import 'package:flutter/material.dart';
import 'package:bikerental/model/bicycle_model.dart';
import 'package:bikerental/view/customer/booking_page.dart';

class BicycleDetailsPage extends StatefulWidget {
  final BicycleModel bicycle;

  const BicycleDetailsPage({
    super.key,
    required this.bicycle,
  });

  @override
  State<BicycleDetailsPage> createState() =>
      _BicycleDetailsPageState();
}

class _BicycleDetailsPageState
    extends State<BicycleDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final bicycle = widget.bicycle;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // TOP BAR
            // =========================
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  _buildCircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),

            // =========================
            // CONTENT
            // =========================
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // =========================
                    // BICYCLE IMAGE
                    // =========================
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(20),
                        child: bicycle.imageUrl.isNotEmpty
                            ? Image.network(
                                bicycle.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                  return const Center(
                                    child: Icon(
                                      Icons
                                          .directions_bike,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(
                                  Icons.directions_bike,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // NAME / TYPE / PRICE
                    // =========================
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                bicycle.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${bicycle.type}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color:
                                      Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${bicycle.rentalRate.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight:
                                    FontWeight.bold,
                                color:
                                    Color(0xFF1B4D3E),
                              ),
                            ),
                            Text(
                              '/ day',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // AVAILABILITY
                    // =========================
                    Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: bicycle.available
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Icon(
                            bicycle.available
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: bicycle.available
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            bicycle.available
                                ? 'Available for Rent'
                                : 'Currently Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.bold,
                              color: bicycle.available
                                  ? const Color(
                                      0xFF2E7D32,
                                    )
                                  : const Color(
                                      0xFFC62828,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // DESCRIPTION
                    // =========================
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                      child: Text(
                        bicycle.description.isNotEmpty
                            ? bicycle.description
                            : 'No description available.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================
                    // SPECIFICATIONS
                    // =========================
                    const Text(
                      'Specifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildSpecCard(
                          Icons.speed,
                          'Gears',
                          bicycle.specs.gearing.isNotEmpty
                              ? bicycle.specs.gearing
                              : 'N/A',
                        ),
                        const SizedBox(width: 10),
                        _buildSpecCard(
                          Icons.fitness_center,
                          'Frame',
                          bicycle.specs.frame.isNotEmpty
                              ? bicycle.specs.frame
                              : 'N/A',
                        ),
                        const SizedBox(width: 10),
                        _buildSpecCard(
                          Icons.tune,
                          'Brakes',
                          bicycle.specs.brakes.isNotEmpty
                              ? bicycle.specs.brakes
                              : 'N/A',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildSpecCard(
                          Icons.circle_outlined,
                          'Wheel Size',
                          bicycle.specs.wheelSize
                                  .isNotEmpty
                              ? bicycle.specs.wheelSize
                              : 'N/A',
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          flex: 2,
                          child: Container(
                            padding:
                                const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons
                                      .person_outline,
                                  size: 20,
                                  color:
                                      Color(0xFF1B4D3E),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Suitable For',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color:
                                        Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bicycle
                                          .specs
                                          .suitableFor
                                          .isNotEmpty
                                      ? bicycle
                                          .specs
                                          .suitableFor
                                      : 'N/A',
                                  textAlign:
                                      TextAlign.center,
                                  style:
                                      const TextStyle(
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // =========================
            // BOOK NOW BUTTON
            // =========================
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: bicycle.available
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  BookingPage(
                                bicycle: bicycle,
                              ),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1B4D3E),
                    disabledBackgroundColor:
                        Colors.grey[300],
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================
  // BACK BUTTON
  // =========================
  Widget _buildCircleIconButton({
    required IconData icon,
    required void Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: Colors.black87,
        ),
      ),
    );
  }

  // =========================
  // SPECIFICATION CARD
  // =========================
  Widget _buildSpecCard(
    IconData icon,
    String label,
    String value,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: const Color(0xFF1B4D3E),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}