class AppConstants {
  // App Name
  static const String appName = "UrbanLeafs";

  // Firebase Collections
  static const String collectionUsers = "users";
  static const String collectionAttendance = "attendance";
  static const String collectionExpenses = "expenses";
  static const String collectionInventory = "inventory";
  static const String collectionOrders = "orders";
  static const String collectionPayments = "payments";
  static const String collectionWorkers = "workers";

  // Roles
  static const String roleAdmin = "admin";
  static const String roleRegular = "regular";

  // Shifts
  static const String shiftMorning = "Morning";
  static const String shiftAfternoon = "Afternoon";

  // Status
  static const String statusPresent = "present";
  static const String statusAbsent = "absent";
  static const String statusHalfDay = "halfDay";

  // Expense Types
  static const String expenseRawMaterial = "rawMaterial";
  static const String expenseTransportation = "transportation";
  static const String expenseLabor = "labor";
  static const String expenseOther = "other";

  // Payment Types
  static const String paymentCash = "cash";
  static const String paymentOnline = "online";

  // Inventory Units
  static const List<String> inventoryUnits = ["kg", "pcs", "liters", "units"];

  static const List<String> inventoryItemNames = [
    'Wheat',
    'Plates',
    'Oil',
    'Boxes',
    'Paper Rolls',
  ];
}
