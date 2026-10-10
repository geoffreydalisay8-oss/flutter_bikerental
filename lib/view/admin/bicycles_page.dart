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

  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F9FC),
        elevation: 0,
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
                  _showBicycleDialog(
                    context,
                    service,
                  );
                },
                icon: const Icon(
                  Icons.add,
                  size: 18,
                ),
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
          // ==============================
          // SEARCH BAR
          // ==============================

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
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(12),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xFF008955),
                  ),
                ),
              ),
            ),
          ),

          // ==============================
          // BICYCLE LIST
          // ==============================

          Expanded(
            child: StreamBuilder<List<BicycleModel>>(
              stream: service.getBicycles(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF008955),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading bicycles:\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No bicycles found.',
                    ),
                  );
                }

                final filteredBicycles =
                    snapshot.data!.where(
                  (bicycle) {
                    final nameMatches = bicycle.name
                        .toLowerCase()
                        .contains(_searchQuery);

                    final typeMatches = bicycle.type
                        .toLowerCase()
                        .contains(_searchQuery);

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

                    return nameMatches ||
                        typeMatches ||
                        specMatches;
                  },
                ).toList();

                if (filteredBicycles.isEmpty) {
                  return const Center(
                    child: Text(
                      'No matching bicycles found.',
                    ),
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

                    return _buildBicycleCard(
                      context,
                      bicycle,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BICYCLE CARD
  // ============================================================

  Widget _buildBicycleCard(
    BuildContext context,
    BicycleModel bicycle,
  ) {
    final specSummary = [
      if (bicycle.specs.gearing.isNotEmpty)
        bicycle.specs.gearing,
      if (bicycle.specs.brakes.isNotEmpty)
        bicycle.specs.brakes,
      if (bicycle.specs.wheelSize.isNotEmpty)
        bicycle.specs.wheelSize,
    ].join(' • ');

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ==============================
          // BICYCLE IMAGE
          // ==============================

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
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
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

          const SizedBox(width: 8),

          // ==============================
          // BICYCLE DETAILS
          // ==============================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bicycle.id.isNotEmpty)
                  Text(
                    bicycle.id,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: 2),

                Text(
                  bicycle.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        bicycle.type,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      ' • ',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '₱${bicycle.rentalRate}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF008955),
                      ),
                    ),
                    Text(
                      '/day',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                if (specSummary.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Specs: $specSummary',
                    style: TextStyle(
                      fontSize: 10,
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

          const SizedBox(width: 4),

          // ==============================
          // STATUS + MENU
          // ==============================

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatusBadge(
                bicycle.available,
              ),
              SizedBox(
                width: 32,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  iconSize: 20,
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
                      await service.deleteBicycle(
                        bicycle.id,
                      );
                    }
                  },
                  itemBuilder:
                      (BuildContext context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit,
                            size: 18,
                          ),
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
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge(
    bool isAvailable,
  ) {
    final Color backgroundColor = isAvailable
        ? const Color(0xFFE8F8F0)
        : const Color(0xFFFFEFE6);

    final Color textColor = isAvailable
        ? const Color(0xFF008955)
        : const Color(0xFFE56A24);

    final String label = isAvailable
        ? 'Available'
        : 'Rented';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ============================================================
  // ADD / EDIT BICYCLE
  // ============================================================

  void _showBicycleDialog(
    BuildContext context,
    BicycleService service, {
    BicycleModel? bicycle,
  }) {
    final nameController = TextEditingController(
      text: bicycle?.name ?? '',
    );

    final typeController = TextEditingController(
      text: bicycle?.type ?? '',
    );

    final rateController = TextEditingController(
      text: bicycle?.rentalRate.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: bicycle?.description ?? '',
    );

    final frameController = TextEditingController(
      text: bicycle?.specs.frame ?? '',
    );

    final gearingController = TextEditingController(
      text: bicycle?.specs.gearing ?? '',
    );

    final brakesController = TextEditingController(
      text: bicycle?.specs.brakes ?? '',
    );

    final wheelSizeController = TextEditingController(
      text: bicycle?.specs.wheelSize ?? '',
    );

    final suitableForController = TextEditingController(
      text: bicycle?.specs.suitableFor ?? '',
    );

    bool available = bicycle?.available ?? true;

    // Selected image
    Uint8List? selectedImageBytes;
    String? selectedImageName;

    // Existing image when editing
    String existingImageUrl = bicycle?.imageUrl ?? '';

    bool isUploading = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setState,
          ) {
            // ==================================================
            // PICK IMAGE
            // ==================================================

            Future<void> pickImage() async {
              try {
                final XFile? pickedFile =
                    await imagePicker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );

                if (pickedFile == null) {
                  return;
                }

                final Uint8List bytes =
                    await pickedFile.readAsBytes();

                // 5 MB maximum
                if (bytes.length > 5 * 1024 * 1024) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(
                      dialogContext,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Image is too large. Please select an image below 5MB.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  return;
                }

                setState(() {
                  selectedImageBytes = bytes;
                  selectedImageName = pickedFile.name;
                });
              } catch (e) {
                debugPrint(
                  'Image picker error: $e',
                );

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(
                    dialogContext,
                  ).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to select image: $e',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            // ==================================================
            // SAVE BICYCLE
            // ==================================================

            Future<void> saveBicycle() async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter the bicycle name.',
                    ),
                  ),
                );
                return;
              }

              if (typeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please select the bicycle type.',
                    ),
                  ),
                );
                return;
              }

              final double? rentalRate =
                  double.tryParse(
                rateController.text.trim(),
              );

              if (rentalRate == null) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid rental rate.',
                    ),
                  ),
                );
                return;
              }

              setState(() {
                isUploading = true;
              });

              try {
                // Keep old image if editing
                // and no new image is selected.
                String imageUrl = existingImageUrl;

                // ==================================================
                // CLOUDINARY IMAGE UPLOAD
                // ==================================================

                if (selectedImageBytes != null) {
                  final String fileName =
                      selectedImageName ??
                          'bicycle_${DateTime.now().millisecondsSinceEpoch}.jpg';

                  debugPrint(
                    'Uploading bicycle image...',
                  );

                  debugPrint(
                    'File name: $fileName',
                  );

                  debugPrint(
                    'File size: ${selectedImageBytes!.length} bytes',
                  );

                  final String? uploadedUrl =
                      await cloudinaryService.uploadImage(
                    imageBytes: selectedImageBytes!,
                    fileName: fileName,
                    folder: 'bikepic/bicycles',
                  );

                  debugPrint(
                    'Cloudinary URL: $uploadedUrl',
                  );

                  // Do not save the bicycle
                  // if image upload failed.
                  if (uploadedUrl == null ||
                      uploadedUrl.trim().isEmpty) {
                    throw Exception(
                      'Image upload failed. Please check your Cloudinary configuration.',
                    );
                  }

                  imageUrl = uploadedUrl;
                }

                // ==================================================
                // CREATE BICYCLE MODEL
                // ==================================================

                final BicycleModel newBicycle =
                    BicycleModel(
                  id: bicycle?.id ?? '',
                  name: nameController.text.trim(),
                  type: typeController.text.trim(),
                  rentalRate: rentalRate,
                  available: available,
                  description:
                      descriptionController.text.trim(),
                  imageUrl: imageUrl,
                  specs: BicycleSpecs(
                    frame: frameController.text.trim(),
                    gearing:
                        gearingController.text.trim(),
                    brakes:
                        brakesController.text.trim(),
                    wheelSize:
                        wheelSizeController.text.trim(),
                    suitableFor:
                        suitableForController.text.trim(),
                  ),
                );

                // ==================================================
                // FIRESTORE
                // ==================================================

                if (bicycle == null) {
                  await service.addBicycle(
                    newBicycle,
                  );
                } else {
                  await service.updateBicycle(
                    newBicycle,
                  );
                }

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                );

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      bicycle == null
                          ? 'Bicycle added successfully.'
                          : 'Bicycle updated successfully.',
                    ),
                    backgroundColor:
                        const Color(0xFF008955),
                  ),
                );
              } catch (e) {
                debugPrint(
                  'SAVE BICYCLE ERROR: $e',
                );

                if (!dialogContext.mounted) {
                  return;
                }

                setState(() {
                  isUploading = false;
                });

                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Failed to save bicycle: $e',
                    ),
                    backgroundColor: Colors.red,
                    duration:
                        const Duration(seconds: 5),
                  ),
                );
              }
            }

            // ==================================================
            // ADD / EDIT DIALOG
            // ==================================================

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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // IMAGE
                    // ==================================================

                    GestureDetector(
                      onTap: isUploading
                          ? null
                          : pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F6F8),
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.memory(
                                      selectedImageBytes!,
                                      fit: BoxFit.cover,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        color: Colors.black54,
                                        child: const Text(
                                          'Tap to change photo',
                                          textAlign:
                                              TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : existingImageUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.network(
                                          existingImageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Center(
                                              child: Icon(
                                                Icons.pedal_bike,
                                                size: 45,
                                                color: Color(
                                                  0xFF8C9BA5,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding:
                                                const EdgeInsets
                                                    .symmetric(
                                              vertical: 8,
                                            ),
                                            color: Colors.black54,
                                            child: const Text(
                                              'Tap to change photo',
                                              textAlign:
                                                  TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
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
                                          color: Color(
                                            0xFF8C9BA5,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          'Select Bicycle Image',
                                          style: TextStyle(
                                            color: Color(
                                              0xFF8C9BA5,
                                            ),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ==================================================
                    // NAME
                    // ==================================================

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Bicycle Name',
                      ),
                    ),

                    // ==================================================
                    // TYPE - DROPDOWN
                    // ==================================================

                    DropdownButtonFormField<String>(
                      value: typeController.text.isNotEmpty &&
                              [
                                'Mountain',
                                'Road',
                                'City',
                              ].contains(typeController.text)
                          ? typeController.text
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Mountain',
                          child: Text('Mountain'),
                        ),
                        DropdownMenuItem(
                          value: 'Road',
                          child: Text('Road'),
                        ),
                        DropdownMenuItem(
                          value: 'City',
                          child: Text('City'),
                        ),
                      ],
                      onChanged: isUploading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  typeController.text = value;
                                });
                              }
                            },
                    ),

                    // ==================================================
                    // RENTAL RATE
                    // ==================================================

                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rental Rate',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ==================================================
                    // TECHNICAL SPECS
                    // ==================================================

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
                        labelText:
                            'Frame (e.g., Alloy 6061)',
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

                    // ==================================================
                    // DESCRIPTION
                    // ==================================================

                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                      ),
                    ),

                    // ==================================================
                    // AVAILABLE
                    // ==================================================

                    SwitchListTile(
                      title: const Text(
                        'Available',
                      ),
                      activeThumbColor:
                          const Color(0xFF008955),
                      value: available,
                      onChanged: isUploading
                          ? null
                          : (value) {
                              setState(() {
                                available = value;
                              });
                            },
                    ),
                  ],
                ),
              ),

              // ==================================================
              // ACTION BUTTONS
              // ==================================================

              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF008955),
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      isUploading ? null : saveBicycle,
                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          bicycle == null
                              ? 'Add'
                              : 'Update',
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