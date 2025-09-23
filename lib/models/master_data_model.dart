class InventoryMeta {
  final String name;
  final String unit;
  final String type;
  final String size; // now required
  final List<RecipeStep> recipe;

  InventoryMeta({
    required this.name,
    required this.unit,
    required this.type,
    required this.size,
    this.recipe = const [],
  });

  factory InventoryMeta.fromMap(Map<String, dynamic> map) {
    // Parse recipe safely
    final recipeList = (map['recipe'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map((e) => RecipeStep.fromMap(e))
        .toList();

    return InventoryMeta(
      name: (map['name'] ?? '').toString(),
      unit: (map['unit'] ?? '').toString(),
      type: (map['type'] ?? '').toString(),
      size: (map['size'] ?? 'N/A').toString(), // default to 'N/A' if not provided
      recipe: recipeList,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'unit': unit,
        'type': type,
        'size': size,
        if (recipe.isNotEmpty) 'recipe': recipe.map((e) => e.toMap()).toList(),
      };
}

class MasterDataModel {
  final List<String> expenseTypes;
  final List<InventoryMeta> inventoryTypes;

  MasterDataModel({
    required this.expenseTypes,
    required this.inventoryTypes,
  });

  List<String> get itemTypes =>
      inventoryTypes.map((e) => e.type).toSet().toList();

  List<String> get units =>
      inventoryTypes.map((e) => e.unit).toSet().toList();

  factory MasterDataModel.fromJson(Map<String, dynamic> map) {
    final invRaw = (map['inventoryTypes'] as List<dynamic>? ?? []);

    final invList = invRaw.map((e) {
      if (e is Map) {
        return InventoryMeta.fromMap(Map<String, dynamic>.from(e));
      } else if (e is Map<String, dynamic>) {
        return InventoryMeta.fromMap(e);
      } else {
        // fallback empty item if structure is unexpected
        return InventoryMeta(name: '', unit: '', type: '', size: 'N/A');
      }
    }).toList();

    return MasterDataModel(
      expenseTypes: (map['expenseTypes'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      inventoryTypes: invList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseTypes': expenseTypes,
      'inventoryTypes': inventoryTypes.map((e) => e.toMap()).toList(),
    };
  }
}

class RecipeStep {
  final String rawName;
  final double ratio;

  RecipeStep({required this.rawName, required this.ratio});

  factory RecipeStep.fromMap(Map<String, dynamic> map) => RecipeStep(
        rawName: (map['rawName'] ?? '').toString(),
        ratio: (map['ratio'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'rawName': rawName,
        'ratio': ratio,
      };
}
