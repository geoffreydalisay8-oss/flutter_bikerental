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

  final List<String> idTypes = [
    'Student ID',
    'Driver\'s License',
    'Passport',
    'National ID',
  ];

  // ============================================================
  // INITIALIZE PAGE
  // ============================================================

  @override
  void initState() {
    super.initState();

    checkExistingVerification();
  }

  // ============================================================
  // CHECK IF CUSTOMER IS ALREADY VERIFIED
  // ============================================================

  Future<void> checkExistingVerification() async {
    try {
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          isCheckingVerification = false;
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

      bool isVerified = false;

      for (final QueryDocumentSnapshot doc
          in snapshot.docs) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>;

        final String status =
            (data['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

        if (status == 'verified') {
          isVerified = true;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        isCheckingVerification = false;
      });

      // --------------------------------------------------------
      // CUSTOMER IS ALREADY VERIFIED
      // --------------------------------------------------------

      if (isVerified) {
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCheckingVerification = false;
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
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) {
        return;
      }

      final Uint8List imageBytes =
          await image.readAsBytes();

      // Maximum file size: 5 MB
      if (imageBytes.length > 5 * 1024 * 1024) {
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
        isUploading = true;
      });

      // ========================================================
      // UPLOAD TO CLOUDINARY
      // ========================================================

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
              'ID uploaded successfully!',
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
          userDoc.data() as Map<String, dynamic>?;

      final String customerName =
          userData?['name'] ??
          userData?['fullName'] ??
          currentUser.displayName ??
          'Unknown User';

      // --------------------------------------------------------
      // CHECK EXISTING ID VERIFICATION
      // --------------------------------------------------------

      final QuerySnapshot existingVerification =
          await FirebaseFirestore.instance
              .collection('id_verifications')
              .where(
                'customerId',
                isEqualTo: currentUser.uid,
              )
              .get();

      String? existingVerificationId;

      for (final QueryDocumentSnapshot doc
          in existingVerification.docs) {
        final Map<String, dynamic> data =
            doc.data() as Map<String, dynamic>;

        final String status =
            (data['status'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

        // Reuse Pending or Verified record
        if (status == 'pending' ||
            status == 'verified') {
          existingVerificationId = doc.id;
          break;
        }
      }

      String verificationId;

      // --------------------------------------------------------
      // UPDATE EXISTING VERIFICATION
      // --------------------------------------------------------

      if (existingVerificationId != null) {
        await FirebaseFirestore.instance
            .collection('id_verifications')
            .doc(existingVerificationId)
            .update({
          'customerId': currentUser.uid,
          'customerName': customerName,
          'customerEmail':
              currentUser.email ?? '',
          'idType': selectedIdType,
          'imageUrl': uploadedImageUrl,
          'idImageUrl': uploadedImageUrl,
          'status': 'Pending',
          'submittedAt':
              FieldValue.serverTimestamp(),
          'uploadedDate':
              FieldValue.serverTimestamp(),
          'reviewedAt': null,
          'reviewedBy': null,
        });

        verificationId =
            existingVerificationId;
      }

      // --------------------------------------------------------
      // CREATE NEW VERIFICATION
      // --------------------------------------------------------

      else {
        final DocumentReference verificationDoc =
            await FirebaseFirestore.instance
                .collection('id_verifications')
                .add({
          'customerId': currentUser.uid,
          'customerName': customerName,
          'customerEmail':
              currentUser.email ?? '',
          'idType': selectedIdType,
          'imageUrl': uploadedImageUrl,
          'idImageUrl': uploadedImageUrl,
          'docNumber': 'N/A',
          'status': 'Pending',
          'submittedAt':
              FieldValue.serverTimestamp(),
          'uploadedDate':
              FieldValue.serverTimestamp(),
          'associatedBooking': 'N/A',
          'bookingId': '',
          'reviewedAt': null,
          'reviewedBy': null,
        });

        verificationId = verificationDoc.id;
      }

      debugPrint(
        'ID Verification ID: $verificationId',
      );

      if (!mounted) return;

      setState(() {
        isUploading = false;
      });

      // --------------------------------------------------------
      // CONTINUE TO BOOKING SUMMARY
      // --------------------------------------------------------

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    // ==========================================================
    // CHECKING VERIFICATION
    // ==========================================================

    if (isCheckingVerification) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'IDENTITY VERIFICATION',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload a valid ID for verification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please upload a valid government or school ID before continuing with your booking.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'ID Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: selectedIdType,
              decoration:
                  const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: idTypes.map(
                (String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                },
              ).toList(),
              onChanged: (String? value) {
                if (value == null) return;

                setState(() {
                  selectedIdType = value;
                });
              },
            ),

            const SizedBox(height: 25),

            const Text(
              'Upload ID',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            GestureDetector(
              onTap: isUploading
                  ? null
                  : pickIdImage,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey,
                  ),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: selectedIdImage != null
                    ? ClipRRect(
                        borderRadius:
                            BorderRadius.circular(12),
                        child: Image.memory(
                          selectedIdImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons
                                .cloud_upload_outlined,
                            size: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Tap to upload your ID',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 10),

            if (selectedIdImageName != null)
              Text(
                selectedIdImageName!,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),

            const SizedBox(height: 15),

            if (isUploading)
              const Center(
                child:
                    CircularProgressIndicator(),
              ),

            if (uploadedImageUrl != null &&
                !isUploading)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      Colors.green.shade50,
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ID uploaded successfully',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isUploading
                        ? null
                        : submitIdVerification,
                child: const Text(
                  'Continue to Booking Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}