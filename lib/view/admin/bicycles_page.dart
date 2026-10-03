import 'package:flutter/material.dart';

import '../../model/bicycle_model.dart';
import '../../service/bicycle_service.dart';

class ManageBicycles extends StatefulWidget {
  const ManageBicycles({super.key});

  @override
  State<ManageBicycles> createState() => _ManageBicyclesState();
}

class _ManageBicyclesState extends State<ManageBicycles> {
  final BicycleService service = BicycleService();
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
                hintText: 'Search model type or tag...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
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
                  borderSide: const BorderSide(color: Color(0xFF008955)),
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
                  return nameMatches || typeMatches;
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

  Widget _buildBicycleCard(BuildContext context, BicycleModel bicycle) {
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
          // Bike Icon Placeholder
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
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
              ],
            ),
          ),

          // Status Tag & Options Menu
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
                        Icon(Icons.delete, color: Colors.red, size: 18),
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
    final Color backgroundColor =
        isAvailable ? const Color(0xFFE8F8F0) : const Color(0xFFFFEFE6);
    final Color textColor =
        isAvailable ? const Color(0xFF008955) : const Color(0xFFE56A24);
    final String label = isAvailable ? 'Available' : 'Rented';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    final nameController = TextEditingController(text: bicycle?.name ?? '');
    final typeController = TextEditingController(text: bicycle?.type ?? '');
    final rateController =
        TextEditingController(text: bicycle?.rentalRate.toString() ?? '');
    final descriptionController =
        TextEditingController(text: bicycle?.description ?? '');
    bool available = bicycle?.available ?? true;

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
                bicycle == null ? 'Add Bicycle' : 'Edit Bicycle',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      onChanged: (value) {
                        setState(() {
                          available = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF008955),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final newBicycle = BicycleModel(
                      id: bicycle?.id ?? '',
                      name: nameController.text,
                      type: typeController.text,
                      rentalRate:
                          double.tryParse(rateController.text) ?? 0,
                      available: available,
                      description: descriptionController.text,
                      imageUrl: bicycle?.imageUrl ?? '',
                    );

                    if (bicycle == null) {
                      await service.addBicycle(newBicycle);
                    } else {
                      await service.updateBicycle(newBicycle);
                    }

                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Text(bicycle == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}