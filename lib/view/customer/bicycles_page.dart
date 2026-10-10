import 'package:flutter/material.dart';

import 'package:bikerental/service/bicycle_service.dart';
import 'bicycle_details_page.dart';

class BicyclesPage extends StatefulWidget {
  const BicyclesPage({super.key});

  @override
  State<BicyclesPage> createState() => _BicyclesPageState();
}

class _BicyclesPageState extends State<BicyclesPage> {
  final BicycleService service = BicycleService();

  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Mountain',
    'Road',
    'City',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FB),
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xFF1B4D3E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_bike,
                color: Colors.white,
                size: 20,
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              'Bicycles',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),

      body: StreamBuilder(
        stream: service.getBicycles(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load bicycles.',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No bicycles available.',
              ),
            );
          }

          final allBicycles = snapshot.data!;

          // ==================================================
          // FILTER BICYCLES BY TYPE
          // ==================================================

          final bicycles = _selectedCategory == 'All'
              ? allBicycles
              : allBicycles.where((bicycle) {
                  final type = bicycle.type
                      .toString()
                      .trim()
                      .toLowerCase();

                  return type ==
                      _selectedCategory
                          .trim()
                          .toLowerCase();
                }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ==================================================
                // SEARCH BAR
                // ==================================================

                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search bicycles by name or model...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(
                      vertical: 0,
                    ),
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide:
                          BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // CATEGORY FILTER
                // ==================================================

                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection:
                        Axis.horizontal,
                    itemCount:
                        _categories.length,
                    separatorBuilder:
                        (_, _) =>
                            const SizedBox(
                      width: 8,
                    ),

                    itemBuilder:
                        (context, index) {
                      final category =
                          _categories[index];

                      final isSelected =
                          _selectedCategory ==
                              category;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory =
                                category;
                          });
                        },

                        child:
                            AnimatedContainer(
                          duration:
                              const Duration(
                            milliseconds: 200,
                          ),

                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),

                          decoration:
                              BoxDecoration(
                            color: isSelected
                                ? const Color(
                                    0xFF1B4D3E,
                                  )
                                : Colors.white,

                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),

                            border: Border.all(
                              color: isSelected
                                  ? Colors
                                      .transparent
                                  : Colors
                                      .grey
                                      .shade300,
                            ),
                          ),

                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,

                              fontWeight:
                                  isSelected
                                      ? FontWeight
                                          .bold
                                      : FontWeight
                                          .normal,

                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ==================================================
                // AVAILABLE COUNT
                // ==================================================

                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(
                        color: Colors.green,
                        shape:
                            BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 6),

                    Text(
                      '${bicycles.length} Bicycles available',
                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ==================================================
                // NO RESULT
                // ==================================================

                if (bicycles.isEmpty)
                  Container(
                    width:
                        double.infinity,
                    padding:
                        const EdgeInsets.all(
                      30,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons
                              .directions_bike_outlined,
                          size: 50,
                          color:
                              Colors.grey[400],
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          'No $_selectedCategory bicycles found.',
                          textAlign:
                              TextAlign.center,
                          style:
                              TextStyle(
                            color:
                                Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )

                // ==================================================
                // BICYCLE CARDS
                // ==================================================

                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        bicycles.length,
                    itemBuilder:
                        (context, index) {
                      final bicycle =
                          bicycles[index];

                      return _buildBicycleCard(
                        context,
                        bicycle,
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================================================
  // BICYCLE CARD
  // ==================================================

  Widget _buildBicycleCard(
    BuildContext context,
    dynamic bicycle,
  ) {
    final bool isAvailable =
        bicycle.available ?? true;

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 16,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ==================================================
          // IMAGE
          // ==================================================

          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius
                        .vertical(
                  top:
                      Radius.circular(16),
                ),

                child: Image.network(
                  bicycle.imageUrl ??
                      'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=800',

                  height: 180,
                  width:
                      double.infinity,
                  fit: BoxFit.cover,

                  errorBuilder:
                      (
                    context,
                    error,
                    stackTrace,
                  ) {
                    return Container(
                      height: 180,
                      color:
                          Colors.grey[200],
                      child:
                          const Icon(
                        Icons
                            .directions_bike,
                        size: 60,
                        color:
                            Colors.grey,
                      ),
                    );
                  },
                ),
              ),

              // ==================================================
              // AVAILABILITY
              // ==================================================

              Positioned(
                top: 12,
                right: 12,

                child: Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),

                  decoration:
                      BoxDecoration(
                    color: isAvailable
                        ? const Color(
                            0xFFE8F5E9,
                          )
                        : const Color(
                            0xFFFFEBEE,
                          ),

                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                  ),

                  child: Text(
                    isAvailable
                        ? 'AVAILABLE'
                        : 'UNAVAILABLE',

                    style:
                        TextStyle(
                      color: isAvailable
                          ? const Color(
                              0xFF2E7D32,
                            )
                          : const Color(
                              0xFFC62828,
                            ),

                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ==================================================
          // DETAILS
          // ==================================================

          Padding(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Expanded(
                      child: Text(
                        bicycle.name,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ),

                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text:
                                '₱${bicycle.rentalRate} ',

                            style:
                                const TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight
                                      .bold,
                              color:
                                  Colors.black,
                            ),
                          ),

                          TextSpan(
                            text: '/ Day',

                            style:
                                TextStyle(
                              fontSize: 12,
                              color: Colors
                                  .grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  '${bicycle.type} • High Performance',

                  style:
                      TextStyle(
                    fontSize: 13,
                    color:
                        Colors.grey[600],
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons
                              .settings_outlined,
                          size: 16,
                          color:
                              Colors.grey[700],
                        ),

                        const SizedBox(
                          width: 4,
                        ),

                        Text(
                          'Suspension Fork',
                          style:
                              TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey[700],
                          ),
                        ),
                      ],
                    ),

                    ElevatedButton(
                      onPressed:
                          isAvailable
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              BicycleDetailsPage(
                                        bicycle:
                                            bicycle,
                                      ),
                                    ),
                                  );
                                }
                              : null,

                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(
                          0xFFEFEFEF,
                        ),

                        foregroundColor:
                            Colors.black,

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            8,
                          ),
                        ),

                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),

                      child:
                          const Text(
                        'View Details',
                        style:
                            TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}