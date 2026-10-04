import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/service/cloudinary_service.dart';
import 'package:bikerental/view/admin/staff/customer/booking_confirmation_page.dart';

class IDVerificationPage extends StatefulWidget {
  final BicycleModel bicycle;
  final DateTime pickupDate;
  final TimeOfDay pickupTime;
  final DateTime returnDate;
  final TimeOfDay returnTime;

  const IDVerificationPage({
    super.key,
    required this.bicycle,
    required this.pickupDate,
    required this.pickupTime,
    required this.returnDate,
    required this.returnTime,
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

  final List<String> idTypes = [
    'Student ID',
    'Driver\'s License',
    'Passport',
    'National ID',
  ];

  Future<void> pickIdImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    final Uint8List imageBytes =
        await image.readAsBytes();

    // Maximum 5 MB
    if (imageBytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image is too large. Maximum size is 5MB.',
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

    final String? url =
        await cloudinaryService.uploadImage(
      imageBytes: imageBytes,
      fileName: image.name,
      folder: 'bikepic/id_verification',
    );

    if (!mounted) {
      return;
    }

    setState(() {
      uploadedImageUrl = url;
      isUploading = false;
    });

    if (url != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ID uploaded successfully!',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to upload ID.',
          ),
        ),
      );
    }
  }

  Future<void> submitIdVerification() async {
    if (uploadedImageUrl == null) {
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
            'You must be logged in.',
          ),
        ),
      );

      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('id_verifications')
          .add({
        'customerId': currentUser.uid,
        'customerEmail': currentUser.email ?? '',
        'idType': selectedIdType,
        'idImageUrl': uploadedImageUrl,
        'status': 'Pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewedBy': null,
      });

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BookingConfirmationPage(
            bicycle: widget.bicycle,
            pickupDate: widget.pickupDate,
            pickupTime: widget.pickupTime,
            returnDate: widget.returnDate,
            returnTime: widget.returnTime,
            idType: selectedIdType,
            bookingFee: 50.0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to submit ID verification: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'IDENTITY VERIFICATION',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                  letterSpacing: 0.8,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Upload a valid ID for verification',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT ID TYPE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: selectedIdType,
                      decoration: InputDecoration(
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor:
                            const Color(0xFFF7F9FB),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: idTypes
                          .map(
                            (type) =>
                                DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedIdType = value;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              GestureDetector(
                onTap: isUploading
                    ? null
                    : pickIdImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(16),
                    border: Border.all(
                      color: uploadedImageUrl != null
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: isUploading
                      ? const Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Color(0xFF1B4D3E),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Uploading ID...',
                              style: TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : selectedIdImage != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(
                                16,
                              ),
                              child: Image.memory(
                                selectedIdImage!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration:
                                      const BoxDecoration(
                                    color:
                                        Color(0xFFF7F9FB),
                                    shape:
                                        BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons
                                        .cloud_upload_outlined,
                                    size: 32,
                                    color:
                                        Color(0xFF1B4D3E),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'Tap to upload front side of $selectedIdType',
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.black87,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  'Supports PNG, JPG (Max 5MB)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              if (uploadedImageUrl != null) ...[
                const SizedBox(height: 10),

                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'ID uploaded successfully',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      uploadedImageUrl != null &&
                              !isUploading
                          ? submitIdVerification
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1B4D3E),
                    disabledBackgroundColor:
                        Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}