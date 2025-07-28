class MasterDataModel {
  final List<String> expenseTypes;
  final List<String> inventoryTypes;
  final List<String> itemTypes;
  final List<String> units;

  MasterDataModel({
    required this.expenseTypes,
    required this.inventoryTypes,
    required this.itemTypes,
    required this.units,
  });

  factory MasterDataModel.fromJson(Map<String, dynamic> map) {
    return MasterDataModel(
      expenseTypes: List<String>.from(map['expenseTypes'] ?? []),
      inventoryTypes: List<String>.from(map['inventoryTypes'] ?? []),
      itemTypes: List<String>.from(map['itemTypes'] ?? []),
      units: List<String>.from(map['units'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expenseTypes': expenseTypes,
      'inventoryTypes': inventoryTypes,
      'itemTypes': itemTypes,
      'units': units,
    };
  }
}
