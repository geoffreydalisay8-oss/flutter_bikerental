class BicycleModel {
  final String id;
  final String name;
  final String type;
  final double rentalRate;
  final bool available;
  final String description;
  final String imageUrl;
  final BicycleSpecs specs;
  

  BicycleModel({
    required this.id,
    required this.name,
    required this.type,
    required this.rentalRate,
    required this.available,
    required this.description,
    required this.imageUrl,
    required this.specs,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'rentalRate': rentalRate,
      'available': available,
      'description': description,
      'imageUrl': imageUrl,
      'specs': specs.toMap(),
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
      rentalRate: (map['rentalRate'] ?? 0).toDouble(),
      available: map['available'] ?? true,
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      specs: BicycleSpecs.fromMap(
        Map<String, dynamic>.from(map['specs'] ?? {}),
      ),
    );
  }
}

class BicycleSpecs {
  final String frame;
  final String gearing;
  final String brakes;
  final String wheelSize;
  final String suitableFor;

  BicycleSpecs({
    required this.frame,
    required this.gearing,
    required this.brakes,
    required this.wheelSize,
    required this.suitableFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'frame': frame,
      'gearing': gearing,
      'brakes': brakes,
      'wheelSize': wheelSize,
      'suitableFor': suitableFor,
    };
  }

  factory BicycleSpecs.fromMap(
    Map<String, dynamic> map,
  ) {
    return BicycleSpecs(
      frame: map['frame'] ?? '',
      gearing: map['gearing'] ?? '',
      brakes: map['brakes'] ?? '',
      wheelSize: map['wheelSize'] ?? '',
      suitableFor: map['suitableFor'] ?? '',
    );
  }
}