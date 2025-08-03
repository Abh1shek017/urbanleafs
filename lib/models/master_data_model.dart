class InventoryMeta {
final String name;
final String unit;
final String type;
final List<RecipeStep> recipe;

InventoryMeta({
required this.name,
required this.unit,
required this.type,
this.recipe = const [],
});

factory InventoryMeta.fromMap(Map<String, dynamic> map) {
final recipeList = (map['recipe'] as List<dynamic>? ?? [])
.where((e) => e is Map)
.map((e) => RecipeStep.fromMap(Map<String, dynamic>.from(e as Map)))
.toList();


return InventoryMeta(
  name: (map['name'] ?? '').toString(),
  unit: (map['unit'] ?? '').toString(),
  type: (map['type'] ?? '').toString(),
  recipe: recipeList,
);
}

Map<String, dynamic> toMap() => {
'name': name,
'unit': unit,
'type': type,
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
final invList = invRaw
.where((e) => e is Map)
.map((e) => InventoryMeta.fromMap(Map<String, dynamic>.from(e as Map)))
.toList();


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