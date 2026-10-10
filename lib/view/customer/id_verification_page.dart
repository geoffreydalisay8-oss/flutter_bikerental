import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/service/cloudinary_service.dart';
import 'package:bikerental/view/customer/booking_summary_page.dart';

class IDVerificationPage extends StatefulWidget {
  final BicycleModel bicycle;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;
  final double rentalFee;

  const IDVerificationPage({
    super.key,
    required this.bicycle,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
    required this.rentalFee,
  });

  @override
  State<IDVerificationPage> createState() =>
      _IDVerificationPageState();
}

class _IDVerificationPageState
    extends State<IDVerificationPage> {
  final CloudinaryService cloudinaryService =
      CloudinaryService();

  String selectedIdType = 'Student ID';

  Uint8List? selectedIdImage;
  String? selectedIdImageName;
  String? uploadedImageUrl;

  bool isUploading = false;
  bool isCheckingVerification = true;

  String currentVerificationStatus =
      'Not Submitted';

  String rejectionReason = '';

  final List<String> idTypes = [
    'Student ID',
    'Driver\'s License',
    'Passport',
    'National ID',
  ];

  @override
  void initState() {
    super.initState();
    checkExistingVerification();
  }

  // ============================================================
  // CHECK CURRENT VERIFICATION
  // ============================================================

  Future<void> checkExistingVerification() async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          isCheckingVerification = false;
          currentVerificationStatus =
              'Not Submitted';
          rejectionReason = '';
        });

        return;
      }

      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('id_verifications')
              .where(
                'customerId',
                isEqualTo: currentUser.uid,
              )
              .get();

      if (snapshot.docs.isEmpty) {
        if (!mounted) return;

        setState(() {
          isCheckingVerification = false;
          currentVerificationStatus =
              'Not Submitted';
          rejectionReason = '';
        });

        return;
      }

      QueryDocumentSnapshot? latestDoc;
      DateTime? latestDate;

      for (final doc in snapshot.docs) {
        final data =
            doc.data()
                as Map<String, dynamic>;

        final dynamic timestamp =
            data['clientSubmittedAt'] ??
            data['submittedAt'] ??
            data['uploadedDate'];

        DateTime? submittedDate;

        if (timestamp is Timestamp) {
          submittedDate =
              timestamp.toDate();
        } else if (timestamp is DateTime) {
          submittedDate =
              timestamp;
        }

        if (latestDoc == null) {
          latestDoc = doc;
          latestDate = submittedDate;
        } else if (submittedDate != null &&
            latestDate != null &&
            submittedDate.isAfter(
              latestDate,
            )) {
          latestDoc = doc;
          latestDate = submittedDate;
        } else if (latestDate == null &&
            submittedDate != null) {
          latestDoc = doc;
          latestDate = submittedDate;
        }
      }

      latestDoc ??= snapshot.docs.last;

      final latestData =
          latestDoc.data()
              as Map<String, dynamic>;

      final String status =
          (latestData['status'] ?? 'Pending')
              .toString()
              .trim();

      final String reason =
          (latestData['rejectionReason'] ?? '')
              .toString()
              .trim();

      if (!mounted) return;

      setState(() {
        isCheckingVerification = false;

        currentVerificationStatus =
            status.isEmpty
                ? 'Pending'
                : status;

        rejectionReason = reason;
      });

      // ----------------------------------------------------------
      // ALREADY VERIFIED
      // ----------------------------------------------------------

      if (status.toLowerCase() == 'verified' ||
          status.toLowerCase() == 'approved') {
        _goToBookingSummary();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingVerification = false;
        currentVerificationStatus =
            'Not Submitted';
        rejectionReason = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to check ID verification: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // PICK AND UPLOAD ID
  // ============================================================

  Future<void> pickIdImage() async {
    try {
      final ImagePicker picker =
          ImagePicker();

      final XFile? image =
          await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      final Uint8List imageBytes =
          await image.readAsBytes();

      // Maximum file size: 5 MB
      if (imageBytes.length >
          5 * 1024 * 1024) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ID image must be less than 5 MB.',
            ),
          ),
        );

        return;
      }

      setState(() {
        selectedIdImage = imageBytes;
        selectedIdImageName = image.name;
        uploadedImageUrl = null;
        isUploading = true;
      });

      final String fileName =
          selectedIdImageName ??
              'id_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String? imageUrl =
          await cloudinaryService.uploadImage(
        imageBytes: imageBytes,
        fileName: fileName,
        folder: 'bikepic/id_verification',
      );

      if (!mounted) return;

      if (imageUrl != null &&
          imageUrl.isNotEmpty) {
        setState(() {
          uploadedImageUrl = imageUrl;
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'ID uploaded successfully.',
            ),
          ),
        );
      } else {
        setState(() {
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to upload ID image.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT ID VERIFICATION
  // ============================================================

  Future<void> submitIdVerification() async {
    if (uploadedImageUrl == null ||
        uploadedImageUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload your ID first.',
          ),
        ),
      );

      return;
    }

    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in again.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // DO NOT ALLOW RESUBMISSION WHILE PENDING
    // ----------------------------------------------------------

    if (currentVerificationStatus
            .toLowerCase() ==
        'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID is still being reviewed. Please wait for Admin verification.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // VERIFIED USERS DO NOT NEED TO SUBMIT AGAIN
    // ----------------------------------------------------------

    if (currentVerificationStatus
                .toLowerCase() ==
            'verified' ||
        currentVerificationStatus
                .toLowerCase() ==
            'approved') {
      _goToBookingSummary();
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      // --------------------------------------------------------
      // GET CUSTOMER INFORMATION
      // --------------------------------------------------------

      final DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic>? userData =
          userDoc.data()
              as Map<String, dynamic>?;

      final String customerName =
          (userData?['name'] ??
                  userData?['fullName'] ??
                  currentUser.displayName ??
                  'Unknown User')
              .toString();

      // --------------------------------------------------------
      // ALWAYS CREATE A NEW DOCUMENT
      //
      // THIS IS THE IMPORTANT PART FOR RETAKING THE ID.
      //
      // If the previous ID was Rejected:
      //   Old document = stays Rejected
      //   New document = Pending
      //
      // We DO NOT update the old rejected document.
      // --------------------------------------------------------

      final DocumentReference verificationDoc =
          await FirebaseFirestore.instance
              .collection('id_verifications')
              .add({
        'customerId':
            currentUser.uid,

        'customerName':
            customerName,

        'customerEmail':
            currentUser.email ?? '',

        'idType':
            selectedIdType,

        'imageUrl':
            uploadedImageUrl,

        'idImageUrl':
            uploadedImageUrl,

        'docNumber':
            'N/A',

        'status':
            'Pending',

        // This identifies this as the newest
        // customer submission.
        'clientSubmittedAt':
            Timestamp.now(),

        'submittedAt':
            FieldValue.serverTimestamp(),

        'uploadedDate':
            FieldValue.serverTimestamp(),

        'associatedBooking':
            'N/A',

        'bookingId':
            '',

        'reviewedAt':
            null,

        'reviewedBy':
            null,

        // New submission has no rejection reason.
        'rejectionReason':
            '',
      });

      debugPrint(
        'New ID Verification ID: ${verificationDoc.id}',
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
        currentVerificationStatus =
            'Pending';
        rejectionReason = '';

        // Clear the selected image after
        // successful submission.
        selectedIdImage = null;
        selectedIdImageName = null;
        uploadedImageUrl = null;
      });

      // --------------------------------------------------------
      // SHOW PENDING MESSAGE
      // --------------------------------------------------------

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Text('ID Submitted'),
              ],
            ),
            content: const Text(
              'Your new ID has been submitted successfully and is now waiting for Admin verification.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    dialogContext,
                  );
                },
                child: const Text(
                  'Continue',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      // --------------------------------------------------------
      // KEEP CUSTOMER ON VERIFICATION PAGE
      //
      // The new ID is Pending, so customer must wait
      // for Admin verification.
      // --------------------------------------------------------

      setState(() {
        currentVerificationStatus =
            'Pending';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit ID: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // GO TO BOOKING SUMMARY
  // ============================================================

  void _goToBookingSummary() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BookingSummaryPage(
          bicycle: widget.bicycle,
          pickupDate: widget.pickupDate,
          pickupTime: widget.pickupTime,
          returnDate: widget.returnDate,
          returnTime: widget.returnTime,
          rentalFee: widget.rentalFee,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS MESSAGE
  // ============================================================

  Widget _buildStatusMessage() {
    switch (
        currentVerificationStatus
            .toLowerCase()) {
      case 'pending':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                const Color(0xFFFFF8E1),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  Colors.orange.shade200,
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your ID is currently pending review. Admin will manually check your ID before the bicycle can be released.',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );

      case 'rejected':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                const Color(0xFFFFEBEE),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  Colors.red.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your previous ID was rejected. Please upload a valid ID and submit it again.',
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              if (rejectionReason
                  .isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(10),
                  decoration:
                      BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),
                  child: Text(
                    'Reason: $rejectionReason',
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );

      case 'verified':
      case 'approved':
        return Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                const Color(0xFFE8F5E9),
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color:
                  Colors.green.shade200,
            ),
          ),
          child: const Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_rounded,
                color: Colors.green,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your ID has been verified. You may proceed with your booking.',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isCheckingVerification) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    final bool isPending =
        currentVerificationStatus
                .toLowerCase() ==
            'pending';

    final bool isVerified =
        currentVerificationStatus
                    .toLowerCase() ==
                'verified' ||
            currentVerificationStatus
                    .toLowerCase() ==
                'approved';

    final bool isRejected =
        currentVerificationStatus
                .toLowerCase() ==
            'rejected';

    return Scaffold(
      backgroundColor:
          Colors.white,

      appBar: AppBar(
        title: const Text(
          'IDENTITY VERIFICATION',
        ),
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Upload a valid ID for verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Please upload a valid government or school ID before continuing with your booking.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            _buildStatusMessage(),

            if (isPending ||
                isVerified) ...[
              const SizedBox(
                height: 20,
              ),
            ],

            // ----------------------------------------------------
            // UPLOAD FORM
            //
            // SHOW:
            // - Not Submitted
            // - Rejected
            //
            // HIDE:
            // - Pending
            // - Verified
            // ----------------------------------------------------

            if (!isPending &&
                !isVerified) ...[
              if (isRejected) ...[
                const Text(
                  'Resubmit Your ID',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Please upload a new ID that addresses the Admin\'s rejection reason.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),
              ],

              const Text(
                'ID Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 8,
              ),

              DropdownButtonFormField<String>(
                initialValue:
                    selectedIdType,

                decoration:
                    const InputDecoration(
                  border:
                      OutlineInputBorder(),
                ),

                items:
                    idTypes.map(
                  (String type) {
                    return DropdownMenuItem<
                        String>(
                      value: type,
                      child:
                          Text(type),
                    );
                  },
                ).toList(),

                onChanged:
                    (String? value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    selectedIdType =
                        value;
                  });
                },
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                'Upload ID',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              GestureDetector(
                onTap:
                    isUploading
                        ? null
                        : pickIdImage,

                child: Container(
                  width:
                      double.infinity,
                  height: 220,

                  decoration:
                      BoxDecoration(
                    border:
                        Border.all(
                      color:
                          Colors.grey,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),

                  child:
                      selectedIdImage !=
                              null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                              child:
                                  Image.memory(
                                selectedIdImage!,
                                fit:
                                    BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,
                              children: [
                                Icon(
                                  Icons
                                      .cloud_upload_outlined,
                                  size: 50,
                                  color:
                                      Colors.grey,
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Tap to upload your ID',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (selectedIdImageName !=
                  null)
                Text(
                  selectedIdImageName!,
                  style:
                      const TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey,
                  ),
                ),

              const SizedBox(
                height: 15,
              ),

              if (isUploading)
                const Center(
                  child:
                      CircularProgressIndicator(),
                ),

              if (uploadedImageUrl !=
                      null &&
                  !isUploading)
                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration:
                      BoxDecoration(
                    color: Colors
                        .green
                        .shade50,
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child: const Row(
                    children: [
                      Icon(
                        Icons
                            .check_circle,
                        color:
                            Colors.green,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          'ID uploaded successfully',
                          style:
                              TextStyle(
                            color:
                                Colors.green,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 52,

                child:
                    ElevatedButton(
                  onPressed:
                      isUploading
                          ? null
                          : submitIdVerification,

                  child:
                      Text(
                    isRejected
                        ? 'Resubmit ID for Verification'
                        : 'Submit ID for Verification',
                    style:
                        const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],

            // ----------------------------------------------------
            // PENDING MESSAGE
            // ----------------------------------------------------

            if (isPending)
              Container(
                width:
                    double.infinity,
                margin:
                    const EdgeInsets.only(
                  top: 10,
                ),
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Text(
                  'Please wait for Admin to review your submitted ID. You do not need to upload another ID while this submission is pending.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey,
                  ),
                ),
              ),

            // ----------------------------------------------------
            // VERIFIED MESSAGE
            // ----------------------------------------------------

            if (isVerified)
              Container(
                width:
                    double.infinity,
                margin:
                    const EdgeInsets.only(
                  top: 10,
                ),
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
                child:
                    const Text(
                  'Your ID has been verified. You may continue with your booking.',
                  textAlign:
                      TextAlign.center,
                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        Colors.green,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}