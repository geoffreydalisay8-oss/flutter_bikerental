class BicycleModel {
  final String id;
  final String name;
  final String type;
  final double rentalRate;
  final bool available;
  final String description;
  final String imageUrl;

  BicycleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rentalRate,
    required this.available,
    required this.description,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'rentalRate': rentalRate,
      'available': available,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory BicycleModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return BicycleModel(
      id: id,
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      rentalRate:
          (map['rentalRate'] ?? 0).toDouble(),
      available:
          map['available'] ?? true,
      description:
          map['description'] ?? '',
      imageUrl:
          map['imageUrl'] ?? '',
    );
  }
}