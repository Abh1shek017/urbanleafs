class InventoryMeta {
final String name;
final String unit;
final String type;

InventoryMeta({
required this.name,
required this.unit,
required this.type,
});

factory InventoryMeta.fromMap(Map<String, dynamic> map) {
return InventoryMeta(
name: (map['name'] ?? '').toString(),
unit: (map['unit'] ?? '').toString(),
type: (map['type'] ?? '').toString(),
);
}

Map<String, dynamic> toMap() => {
'name': name,
'unit': unit,
'type': type,
};
}

class MasterDataModel {
final List<String> expenseTypes;
final List<InventoryMeta> inventoryTypes;

MasterDataModel({
required this.expenseTypes,
required this.inventoryTypes,
});

// Derived values (no longer stored separately)
List<String> get itemTypes =>
inventoryTypes.map((e) => e.type).toSet().toList();

List<String> get units =>
inventoryTypes.map((e) => e.unit).toSet().toList();

factory MasterDataModel.fromJson(Map<String, dynamic> map) {
final invList = (map['inventoryTypes'] as List<dynamic>? ?? [])
.whereType<Map>()
.map((e) => InventoryMeta.fromMap(Map<String, dynamic>.from(e)))
.toList();


return MasterDataModel(
  expenseTypes:
      (map['expenseTypes'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
  inventoryTypes: invList,
);
}

Map<String, dynamic> toJson() {
return {
'expenseTypes': expenseTypes,
'inventoryTypes': inventoryTypes.map((e) => e.toMap()).toList(),
// No itemTypes/units in persisted JSON anymore
};
}
}