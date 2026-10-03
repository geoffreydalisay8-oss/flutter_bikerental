import 'package:flutter/material.dart';
import 'package:bikerental/model/bicycle_model.dart';
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
  State<IDVerificationPage> createState() => _IDVerificationPageState();
}

class _IDVerificationPageState extends State<IDVerificationPage> {
  String selectedIdType = 'Student ID';
  bool isUploaded = false;

  final List<String> idTypes = [
    'Student ID',
    'Driver\'s License',
    'Passport',
    'National ID',
  ];

  void _simulateUpload() {
    setState(() {
      isUploaded = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ID Document attached successfully!')),
    );
  }

  void _submitBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                'Upload a valid ID for campus verification',
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F9FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: idTypes
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            selectedIdType = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _simulateUpload,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isUploaded
                          ? const Color(0xFF1B4D3E)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUploaded
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFF7F9FB),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isUploaded
                              ? Icons.check_circle_outline
                              : Icons.cloud_upload_outlined,
                          size: 32,
                          color: isUploaded
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1B4D3E),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isUploaded
                            ? 'ID Attached Successfully'
                            : 'Tap to upload front side of $selectedIdType',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isUploaded
                              ? const Color(0xFF2E7D32)
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports PNG, JPG (Max 5MB)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isUploaded ? _submitBooking : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4D3E),
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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