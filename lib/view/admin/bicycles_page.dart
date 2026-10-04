import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../model/bicycle_model.dart';
import '../../service/bicycle_service.dart';
import '../../service/cloudinary_service.dart';

class ManageBicycles extends StatefulWidget {
  const ManageBicycles({super.key});

  @override
  State<ManageBicycles> createState() => _ManageBicyclesState();
}

class _ManageBicyclesState extends State<ManageBicycles> {
  final BicycleService service = BicycleService();
  final CloudinaryService cloudinaryService = CloudinaryService();
  final ImagePicker imagePicker = ImagePicker();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Bicycle',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Align(
              alignment: Alignment.center,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showBicycleDialog(context, service);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF008955),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search model type, specs, or tag...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF008955),
                  ),
                ),
              ),
            ),
          ),

          // Bicycle Stream List
          Expanded(
            child: StreamBuilder<List<BicycleModel>>(
              stream: service.getBicycles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008955),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No bicycles found.'),
                  );
                }

                final filteredBicycles = snapshot.data!.where((bicycle) {
                  final nameMatches =
                      bicycle.name.toLowerCase().contains(_searchQuery);

                  final typeMatches =
                      bicycle.type.toLowerCase().contains(_searchQuery);

                  final specMatches =
                      bicycle.specs.frame
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          bicycle.specs.gearing
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          bicycle.specs.brakes
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          bicycle.specs.wheelSize
                              .toLowerCase()
                              .contains(_searchQuery) ||
                          bicycle.specs.suitableFor
                              .toLowerCase()
                              .contains(_searchQuery);

                  return nameMatches || typeMatches || specMatches;
                }).toList();

                if (filteredBicycles.isEmpty) {
                  return const Center(
                    child: Text('No matching bicycles found.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredBicycles.length,
                  itemBuilder: (context, index) {
                    final bicycle = filteredBicycles[index];
                    return _buildBicycleCard(context, bicycle);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBicycleCard(
    BuildContext context,
    BicycleModel bicycle,
  ) {
    // Combine non-empty spec attributes for card summary
    final specSummary = [
      if (bicycle.specs.gearing.isNotEmpty) bicycle.specs.gearing,
      if (bicycle.specs.brakes.isNotEmpty) bicycle.specs.brakes,
      if (bicycle.specs.wheelSize.isNotEmpty) bicycle.specs.wheelSize,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bike Image / Icon Placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: bicycle.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      bicycle.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.pedal_bike,
                          color: Color(0xFF8C9BA5),
                          size: 26,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.pedal_bike,
                    color: Color(0xFF8C9BA5),
                    size: 26,
                  ),
          ),
          const SizedBox(width: 12),

          // Main Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bicycle.id.isNotEmpty)
                  Text(
                    bicycle.id,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  bicycle.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      bicycle.type,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '₱${bicycle.rentalRate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008955),
                      ),
                    ),
                    Text(
                      '/day',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                if (specSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Specs: $specSummary',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Status Badge & Options Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(bicycle.available),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onSelected: (value) async {
                  if (value == 'edit') {
                    _showBicycleDialog(
                      context,
                      service,
                      bicycle: bicycle,
                    );
                  } else if (value == 'delete') {
                    await service.deleteBicycle(bicycle.id);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    final Color backgroundColor = isAvailable
        ? const Color(0xFFE8F8F0)
        : const Color(0xFFFFEFE6);

    final Color textColor = isAvailable
        ? const Color(0xFF008955)
        : const Color(0xFFE56A24);

    final String label = isAvailable ? 'Available' : 'Rented';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showBicycleDialog(
    BuildContext context,
    BicycleService service, {
    BicycleModel? bicycle,
  }) {
    final nameController =
        TextEditingController(text: bicycle?.name ?? '');

    final typeController =
        TextEditingController(text: bicycle?.type ?? '');

    final rateController =
        TextEditingController(
          text: bicycle?.rentalRate.toString() ?? '',
        );

    final descriptionController =
        TextEditingController(
          text: bicycle?.description ?? '',
        );

    // Spec Controllers
    final frameController =
        TextEditingController(text: bicycle?.specs.frame ?? '');

    final gearingController =
        TextEditingController(text: bicycle?.specs.gearing ?? '');

    final brakesController =
        TextEditingController(text: bicycle?.specs.brakes ?? '');

    final wheelSizeController =
        TextEditingController(text: bicycle?.specs.wheelSize ?? '');

    final suitableForController =
        TextEditingController(text: bicycle?.specs.suitableFor ?? '');

    bool available = bicycle?.available ?? true;

    // Cloudinary image variables
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    String existingImageUrl = bicycle?.imageUrl ?? '';

    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                bicycle == null
                    ? 'Add Bicycle'
                    : 'Edit Bicycle',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload
                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : () async {
                              final XFile? pickedFile =
                                  await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 80,
                              );

                              if (pickedFile != null) {
                                final bytes =
                                    await pickedFile.readAsBytes();

                                setState(() {
                                  selectedImageBytes = bytes;
                                  selectedImageName =
                                      pickedFile.name;
                                });
                              }
                            },
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Image.memory(
                                  selectedImageBytes!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : existingImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Image.network(
                                      existingImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return const Center(
                                          child: Icon(
                                            Icons.pedal_bike,
                                            size: 45,
                                            color: Color(0xFF8C9BA5),
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                : const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_a_photo,
                                          size: 35,
                                          color: Color(0xFF8C9BA5),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Select Bicycle Image',
                                          style: TextStyle(
                                            color: Color(0xFF8C9BA5),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bicycle Name',
                      ),
                    ),

                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                      ),
                    ),

                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rental Rate',
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Technical Specs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),

                    TextField(
                      controller: frameController,
                      decoration: const InputDecoration(
                        labelText: 'Frame (e.g., Alloy 6061)',
                      ),
                    ),

                    TextField(
                      controller: gearingController,
                      decoration: const InputDecoration(
                        labelText:
                            'Gearing (e.g., 21-Speed Shimano)',
                      ),
                    ),

                    TextField(
                      controller: brakesController,
                      decoration: const InputDecoration(
                        labelText:
                            'Brakes (e.g., Mech Disc F/R)',
                      ),
                    ),

                    TextField(
                      controller: wheelSizeController,
                      decoration: const InputDecoration(
                        labelText:
                            'Wheel Size (e.g., 27.5 Inches)',
                      ),
                    ),

                    TextField(
                      controller: suitableForController,
                      decoration: const InputDecoration(
                        labelText:
                            'Suitable For (e.g., Campus & Trail)',
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),

                    SwitchListTile(
                      title: const Text('Available'),
                      activeColor: const Color(0xFF008955),
                      value: available,
                      onChanged: (value) =>
                          setState(() => available = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008955),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          setState(() {
                            isUploading = true;
                          });

                          String imageUrl = existingImageUrl;

                          // Upload new image to Cloudinary
                          if (selectedImageBytes != null) {
                            final String? uploadedUrl =
                                await cloudinaryService.uploadImage(
                              imageBytes: selectedImageBytes!,
                              fileName: selectedImageName ??
                                  'bicycle_image',
                              folder: 'bikepic/bicycles',
                            );

                            if (uploadedUrl != null) {
                              imageUrl = uploadedUrl;
                            }
                          }

                          final newBicycle = BicycleModel(
                            id: bicycle?.id ?? '',
                            name: nameController.text,
                            type: typeController.text,
                            rentalRate:
                                double.tryParse(
                                      rateController.text,
                                    ) ??
                                    0,
                            available: available,
                            description:
                                descriptionController.text,
                            imageUrl: imageUrl,
                            specs: BicycleSpecs(
                              frame: frameController.text,
                              gearing: gearingController.text,
                              brakes: brakesController.text,
                              wheelSize: wheelSizeController.text,
                              suitableFor:
                                  suitableForController.text,
                            ),
                          );

                          if (bicycle == null) {
                            await service.addBicycle(
                              newBicycle,
                            );
                          } else {
                            await service.updateBicycle(
                              newBicycle,
                            );
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          bicycle == null ? 'Add' : 'Update',
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}