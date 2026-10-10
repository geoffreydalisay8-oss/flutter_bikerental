
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bikerental/login_page.dart';
import 'package:bikerental/model/user_model.dart';
import 'package:bikerental/service/cloudinary_service.dart';
import 'package:bikerental/service/user_service.dart';

class CustomerProfilePage extends StatefulWidget {
  const CustomerProfilePage({super.key});

  @override
  State<CustomerProfilePage> createState() =>
      _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final UserService userService = UserService();
  final CloudinaryService cloudinaryService = CloudinaryService();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  UserModel? user;

  bool isLoading = true;
  bool isEditing = false;
  bool isSaving = false;

  // ============================================================
  // ID VERIFICATION
  // ============================================================

  bool isCheckingVerification = true;
  bool isUploadingId = false;

  String verificationStatus = 'None';
  String rejectionReason = '';

  // This is used when Firestore cannot be read.
  String verificationError = '';

  Uint8List? selectedIdImage;
  String selectedIdImageName = '';

  String uploadedIdImageUrl = '';

  String selectedIdType = 'National ID';

  final List<String> idTypes = [
    'National ID',
    'Driver\'s License',
    'Passport',
    'PhilHealth ID',
    'UMID',
    'Postal ID',
    'Student ID',
    'Other Valid ID',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD USER
  // ============================================================

  Future<void> _loadUser() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // Get user from UserService
      final UserModel? loadedUser =
          await userService.getUser(currentUser.uid);

      // Get complete user document
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic> userData =
          userDoc.data() ?? <String, dynamic>{};

      if (!mounted) return;

      user = loadedUser;

      // NAME
      if (loadedUser != null) {
        nameController.text = loadedUser.name;
      } else {
        nameController.text = (
          userData['name'] ??
          userData['fullName'] ??
          currentUser.displayName ??
          ''
        ).toString();
      }

      // PHONE
      phoneController.text = (
        userData['phone'] ??
        userData['phoneNumber'] ??
        ''
      ).toString();

      // EMAIL
      emailController.text = (
        userData['email'] ??
        currentUser.email ??
        ''
      ).toString();

      setState(() {
        isLoading = false;
      });

      // Check ID verification after profile loads
      await _checkIdVerification();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load profile: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // CHECK ID VERIFICATION
  // ============================================================

  Future<void> _checkIdVerification() async {
    if (!mounted) return;

    setState(() {
      isCheckingVerification = true;
      verificationError = '';
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (!mounted) return;

        setState(() {
          isCheckingVerification = false;
          verificationStatus = 'None';
          rejectionReason = '';
          uploadedIdImageUrl = '';
          verificationError = '';
        });

        return;
      }

      // ========================================================
      // GET ALL VERIFICATION RECORDS OF THIS CUSTOMER
      // ========================================================

      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance
              .collection('id_verifications')
              .where(
                'customerId',
                isEqualTo: currentUser.uid,
              )
              .get();

      if (!mounted) return;

      // ========================================================
      // NO RECORD
      // ========================================================

      if (snapshot.docs.isEmpty) {
        setState(() {
          isCheckingVerification = false;
          verificationStatus = 'None';
          rejectionReason = '';
          uploadedIdImageUrl = '';
          verificationError = '';
        });

        return;
      }

      // ========================================================
      // FIND LATEST VERIFICATION
      // ========================================================

      final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents =
          List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
        snapshot.docs,
      );

      documents.sort(
        (
          QueryDocumentSnapshot<Map<String, dynamic>> a,
          QueryDocumentSnapshot<Map<String, dynamic>> b,
        ) {
          final DateTime aTime = _getVerificationDate(
            a.data(),
          );

          final DateTime bTime = _getVerificationDate(
            b.data(),
          );

          return bTime.compareTo(aTime);
        },
      );

      final Map<String, dynamic> latestData =
          documents.first.data();

      // ========================================================
      // GET STATUS
      // ========================================================

      String status =
          (latestData['status'] ?? 'None')
              .toString()
              .trim();

      // Convert Approved to Verified
      if (status.toLowerCase() == 'approved') {
        status = 'Verified';
      }

      // ========================================================
      // GET REJECTION REASON
      // ========================================================

      final String reason =
          (latestData['rejectionReason'] ?? '')
              .toString()
              .trim();

      // ========================================================
      // GET IMAGE
      // ========================================================

      final String imageUrl = (
        latestData['imageUrl'] ??
        latestData['idImageUrl'] ??
        ''
      ).toString();

      // ========================================================
      // UPDATE UI
      // ========================================================

      setState(() {
        isCheckingVerification = false;
        verificationStatus = status;
        rejectionReason = reason;
        uploadedIdImageUrl = imageUrl;
        verificationError = '';
      });
    } catch (e) {
      debugPrint(
        'Error checking ID verification: $e',
      );

      if (!mounted) return;

      // IMPORTANT:
      // Do NOT change verificationStatus to "None" here.
      //
      // If Firestore rules temporarily reject the query,
      // the old code made the ID look like it disappeared.
      setState(() {
        isCheckingVerification = false;
        verificationError =
            'Unable to load ID verification status.';
      });
    }
  }

  // ============================================================
  // GET VERIFICATION DATE
  // ============================================================

  DateTime _getVerificationDate(
    Map<String, dynamic> data,
  ) {
    final dynamic clientSubmittedAt =
        data['clientSubmittedAt'];

    if (clientSubmittedAt is Timestamp) {
      return clientSubmittedAt.toDate();
    }

    if (clientSubmittedAt is DateTime) {
      return clientSubmittedAt;
    }

    final dynamic submittedAt =
        data['submittedAt'];

    if (submittedAt is Timestamp) {
      return submittedAt.toDate();
    }

    if (submittedAt is DateTime) {
      return submittedAt;
    }

    final dynamic uploadedDate =
        data['uploadedDate'];

    if (uploadedDate is Timestamp) {
      return uploadedDate.toDate();
    }

    if (uploadedDate is DateTime) {
      return uploadedDate;
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  // ============================================================
  // PICK ID IMAGE
  // ============================================================

  Future<void> _pickIdImage() async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes =
          await image.readAsBytes();

      // Maximum size: 5 MB
      if (bytes.length > 5 * 1024 * 1024) {
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

      if (!mounted) return;

      setState(() {
        selectedIdImage = bytes;
        selectedIdImageName = image.name;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to select image: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT ID VERIFICATION
  // ============================================================

  Future<void> _submitIdVerification() async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please log in again.',
          ),
        ),
      );

      return;
    }

    // Check image
    if (selectedIdImage == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select your valid ID.',
          ),
        ),
      );

      return;
    }

    // Don't allow duplicate submission while pending
    if (verificationStatus.toLowerCase() ==
        'pending') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID is still being reviewed. Please wait for Admin verification.',
          ),
        ),
      );

      return;
    }

    // Don't allow submission if already verified
    if (verificationStatus.toLowerCase() ==
            'verified' ||
        verificationStatus.toLowerCase() ==
            'approved') {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID has already been verified.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isUploadingId = true;
    });

    try {
      // ========================================================
      // UPLOAD IMAGE TO CLOUDINARY
      // ========================================================

      final String fileName =
          selectedIdImageName.isNotEmpty
              ? selectedIdImageName
              : 'id_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final String? uploadedUrl =
          await cloudinaryService.uploadImage(
        imageBytes: selectedIdImage!,
        fileName: fileName,
        folder: 'bikepic/id_verification',
      );

      if (uploadedUrl == null ||
          uploadedUrl.isEmpty) {
        throw Exception(
          'ID image upload failed.',
        );
      }

      // ========================================================
      // GET CUSTOMER INFORMATION
      // ========================================================

      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      final Map<String, dynamic> userData =
          userDoc.data() ?? <String, dynamic>{};

      final String customerName = (
        userData['name'] ??
        userData['fullName'] ??
        currentUser.displayName ??
        'Unknown User'
      ).toString();

      final String customerEmail = (
        userData['email'] ??
        currentUser.email ??
        ''
      ).toString();

      final String customerPhone = (
        userData['phone'] ??
        userData['phoneNumber'] ??
        ''
      ).toString();

      // ========================================================
      // CREATE NEW VERIFICATION
      // ========================================================

      final DocumentReference<Map<String, dynamic>>
          verificationDoc =
          await FirebaseFirestore.instance
              .collection('id_verifications')
              .add({
        'customerId': currentUser.uid,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,

        'idType': selectedIdType,

        'imageUrl': uploadedUrl,
        'idImageUrl': uploadedUrl,

        'docNumber': 'N/A',

        'status': 'Pending',

        'rejectionReason': '',

        'associatedBooking': '',
        'bookingId': '',

        'clientSubmittedAt': Timestamp.now(),

        'submittedAt':
            FieldValue.serverTimestamp(),

        'uploadedDate':
            FieldValue.serverTimestamp(),

        'reviewedAt': null,
        'reviewedBy': null,
      });

      debugPrint(
        'New ID Verification ID: ${verificationDoc.id}',
      );

      if (!mounted) return;

      setState(() {
        verificationStatus = 'Pending';
        rejectionReason = '';
        uploadedIdImageUrl = uploadedUrl;
        selectedIdImage = null;
        selectedIdImageName = '';
        isUploadingId = false;
        verificationError = '';
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID has been submitted for verification.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isUploadingId = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit ID verification: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // OPEN ID VERIFICATION
  // ============================================================

  void _openIdVerification() {
    final String status =
        verificationStatus.toLowerCase();

    if (status == 'pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID is currently being reviewed.',
          ),
        ),
      );

      return;
    }

    if (status == 'verified' ||
        status == 'approved') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your ID has already been verified.',
          ),
        ),
      );

      return;
    }

    setState(() {
      selectedIdImage = null;
      selectedIdImageName = '';
    });

    _showIdVerificationDialog();
  }

  // ============================================================
  // ID VERIFICATION DIALOG
  // ============================================================

  void _showIdVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setDialogState,
          ) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ID Verification',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    if (verificationStatus
                            .toLowerCase() ==
                        'rejected') ...[
                      Container(
                        width: double.infinity,
                        padding:
                            const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              Colors.red.withOpacity(
                            0.08,
                          ),
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          border: Border.all(
                            color:
                                Colors.red.withOpacity(
                              0.3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Previous ID Rejected',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              rejectionReason
                                      .isNotEmpty
                                  ? rejectionReason
                                  : 'Please submit a clearer or valid ID.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'Select ID Type',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      initialValue:
                          selectedIdType,
                      decoration:
                          const InputDecoration(
                        border:
                            OutlineInputBorder(),
                        prefixIcon: Icon(
                          Icons.badge_outlined,
                        ),
                      ),
                      items: idTypes.map(
                        (String type) {
                          return DropdownMenuItem<
                              String>(
                            value: type,
                            child: Text(type),
                          );
                        },
                      ).toList(),
                      onChanged:
                          (String? value) {
                        if (value == null) {
                          return;
                        }

                        setDialogState(() {
                          selectedIdType =
                              value;
                        });

                        setState(() {
                          selectedIdType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Upload a clear photo of your valid ID.',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    GestureDetector(
                      onTap: isUploadingId
                          ? null
                          : () async {
                              await _pickIdImage();

                              if (context.mounted) {
                                setDialogState(
                                  () {},
                                );
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration:
                            BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(
                            12,
                          ),
                          border: Border.all(
                            color: Colors
                                .grey.shade400,
                          ),
                        ),
                        child: selectedIdImage !=
                                null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  12,
                                ),
                                child:
                                    Image.memory(
                                  selectedIdImage!,
                                  fit: BoxFit.cover,
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
                                    size: 45,
                                    color:
                                        Colors.grey,
                                  ),
                                  SizedBox(
                                      height: 8),
                                  Text(
                                    'Tap to select ID image',
                                  ),
                                  SizedBox(
                                      height: 4),
                                  Text(
                                    'Use a clear and readable photo',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (selectedIdImageName
                        .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        selectedIdImageName,
                        style:
                            const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],

                    const SizedBox(height: 15),

                    const Text(
                      'Make sure the following are visible:',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      '• Your complete name\n'
                      '• ID photo\n'
                      '• ID number\n'
                      '• ID type\n'
                      '• The image must be clear and readable',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploadingId
                      ? null
                      : () {
                          Navigator.of(
                            dialogContext,
                          ).pop();
                        },
                  child:
                      const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: isUploadingId
                      ? null
                      : () async {
                          await _submitIdVerification();
                        },
                  icon: isUploadingId
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                        ),
                  label: Text(
                    isUploadingId
                        ? 'Submitting...'
                        : 'Submit ID',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // VERIFICATION STATUS
  // ============================================================

  Widget _buildVerificationStatus() {
    // Checking
    if (isCheckingVerification) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Checking verification status...',
          ),
        ],
      );
    }

    // ==========================================================
    // FIRESTORE ERROR
    // ==========================================================

    if (verificationError.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(
            0.08,
          ),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color: Colors.orange.withOpacity(
              0.3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  color: Colors.orange,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Unable to load verification status',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Please try refreshing your profile.',
              style: TextStyle(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _checkIdVerification,
                icon: const Icon(
                  Icons.refresh,
                ),
                label:
                    const Text('Refresh'),
              ),
            ),
          ],
        ),
      );
    }

    final String status =
        verificationStatus.toLowerCase();

    // ==========================================================
    // VERIFIED
    // ==========================================================

    if (status == 'verified' ||
        status == 'approved') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              Colors.green.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                Colors.green.withOpacity(0.3),
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.verified,
              color: Colors.green,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Verified',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your identity has been verified successfully.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // PENDING
    // ==========================================================

    if (status == 'pending') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              Colors.orange.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                Colors.orange.withOpacity(0.3),
          ),
        ),
        child: const Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.hourglass_top,
              color: Colors.orange,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID Verification Pending',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your ID is currently being reviewed by the admin.',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Please wait for the verification result.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // REJECTED
    // ==========================================================

    if (status == 'rejected') {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              Colors.red.withOpacity(0.08),
          borderRadius:
              BorderRadius.circular(12),
          border: Border.all(
            color:
                Colors.red.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ID Verification Rejected',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rejectionReason.isNotEmpty
                  ? 'Reason: $rejectionReason'
                  : 'Your ID was rejected by the admin.',
              style:
                  const TextStyle(
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child:
                  ElevatedButton.icon(
                onPressed:
                    _openIdVerification,
                icon: const Icon(
                  Icons.camera_alt_outlined,
                ),
                label: const Text(
                  'Retake / Resubmit ID',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ==========================================================
    // NO ID
    // ==========================================================

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            Colors.blue.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              Colors.blue.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.badge_outlined,
                color: Colors.blue,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ID Verification Required',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Please submit a valid ID before making a bicycle reservation.',
            style: TextStyle(
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child:
                ElevatedButton.icon(
              onPressed:
                  _openIdVerification,
              icon: const Icon(
                Icons.upload_file,
              ),
              label:
                  const Text('Submit ID'),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE PROFILE
  // ============================================================

  Future<void> _saveProfile() async {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    if (nameController.text
        .trim()
        .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Name cannot be empty.',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .set(
        {
          'name':
              nameController.text.trim(),
          'fullName':
              nameController.text.trim(),
          'phone':
              phoneController.text.trim(),
          'phoneNumber':
              phoneController.text.trim(),
        },
        SetOptions(
          merge: true,
        ),
      );

      if (!mounted) return;

      setState(() {
        isSaving = false;
        isEditing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully.',
          ),
        ),
      );

      await _loadUser();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to update profile: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context)
        .pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) =>
            const LoginPage(),
      ),
      (route) => false,
    );
  }

  // ============================================================
  // LOGOUT DIALOG
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _logout();
              },
              child:
                  const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // PROFILE HEADER
  // ============================================================

  Widget _buildProfileHeader() {
    final User? currentUser =
        FirebaseAuth.instance.currentUser;

    final String name =
        nameController.text
                .trim()
                .isNotEmpty
            ? nameController.text
                .trim()
            : currentUser?.displayName ??
                'Customer';

    final String firstLetter =
        name.isNotEmpty
            ? name[0].toUpperCase()
            : 'C';

    return Column(
      children: [
        CircleAvatar(
          radius: 45,
          backgroundColor:
              Theme.of(context)
                  .colorScheme
                  .primary,
          child: Text(
            firstLetter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          emailController.text,
          style: TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================

  Widget _buildPersonalInformation() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller:
                  nameController,
              enabled:
                  isEditing && !isSaving,
              decoration:
                  const InputDecoration(
                labelText:
                    'Full Name',
                prefixIcon: Icon(
                  Icons.person_outline,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  emailController,
              enabled: false,
              decoration:
                  const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(
                  Icons.email_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller:
                  phoneController,
              enabled:
                  isEditing && !isSaving,
              keyboardType:
                  TextInputType.phone,
              decoration:
                  const InputDecoration(
                labelText:
                    'Phone Number',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            if (!isEditing)
              SizedBox(
                width:
                    double.infinity,
                child:
                    OutlinedButton
                        .icon(
                  onPressed: () {
                    setState(() {
                      isEditing =
                          true;
                    });
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                  ),
                  label: const Text(
                    'Edit Profile',
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton(
                      onPressed:
                          isSaving
                              ? null
                              : () async {
                                  setState(
                                    () {
                                      isEditing =
                                          false;
                                    },
                                  );

                                  await _loadUser();
                                },
                      child:
                          const Text(
                        'Cancel',
                      ),
                    ),
                  ),
                  const SizedBox(
                      width: 10),
                  Expanded(
                    child:
                        ElevatedButton
                            .icon(
                      onPressed:
                          isSaving
                              ? null
                              : _saveProfile,
                      icon: isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .save_outlined,
                            ),
                      label: Text(
                        isSaving
                            ? 'Saving...'
                            : 'Save',
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ID VERIFICATION CARD
  // ============================================================

  Widget _buildIdVerificationCard() {
    return Card(
      elevation: 0,
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(14),
        side: BorderSide(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons
                      .verified_user_outlined,
                ),
                SizedBox(width: 10),
                Text(
                  'ID Verification',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildVerificationStatus(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh:
            _checkIdVerification,
        child: ListView(
          physics:
              const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.all(16),
          children: [
            _buildProfileHeader(),

            const SizedBox(
                height: 24),

            _buildPersonalInformation(),

            const SizedBox(
                height: 20),

            _buildIdVerificationCard(),

            const SizedBox(
                height: 20),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed:
                    _showLogoutDialog,
                icon: const Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                label: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(
                height: 30),
          ],
        ),
      ),
    );
  }
}
