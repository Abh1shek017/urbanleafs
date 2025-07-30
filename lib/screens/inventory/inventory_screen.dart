// lib/screens/inventory_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:urbanleafs/screens/inventory/add_inventory_screen.dart';
import '../../models/inventory_model.dart';
import '../../providers/inventory_provider.dart';
import '../../repositories/inventory_repository.dart';
import '../../services/master_data_service.dart';
import '../../utils/notifications_util.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
// import '../../utils/format_utils.dart';
import 'package:intl/intl.dart';
import '../../providers/stock_history_provider.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with AutomaticKeepAliveClientMixin {
  final MasterDataService masterDataService = MasterDataService();

  // UI state
  bool _loadingMaster = true;
  String? _errorMaster;
  String _searchQuery = '';
  String _filterType = 'all';
  bool _lowStockOnly = false;
  String _sortBy = 'name';

  // Batch selection
  final Set<String> _selectedIds = {};

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  Future<void> _loadMasterData() async {
    try {
      // final data = await masterDataService.loadLocalMasterData();
      // Won’t actually use itemNames/units here; your provider does that
      setState(() => _loadingMaster = false);
    } catch (e) {
      setState(() {
        _loadingMaster = false;
        _errorMaster = e.toString();
      });
    }
  }

  void _applyBatchRestock() {
    for (var id in _selectedIds) {
      // example: set quantity = lowStockThreshold * 2
      final asyncList = ref.read(inventoryStreamProvider);
      final items = asyncList.when(
        data: (list) => list,
        loading: () => [],
        error: (_, __) => [],
      );

      final item = items.firstWhere((i) => i.id == id);

      InventoryRepository().updateInventory(id, {
        'quantity': item.lowStockThreshold * 2,
        'lastUpdated': Timestamp.now(),
        'updatedBy': ref.read(authStateProvider).value!.uid,
      });
    }
    setState(() => _selectedIds.clear());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authUser = ref.watch(authStateProvider).value;
    final inventoryAsync = ref.watch(inventoryStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: _selectedIds.isEmpty
            ? const Text('Inventory Status')
            : Text('${_selectedIds.length} selected'),
        actions: _selectedIds.isEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showSortFilterDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.restore),
                  onPressed: _applyBatchRestock,
                ),
                // IconButton(icon: const Icon(Icons.delete), onPressed: _applyBatchDelete),
              ],
      ),
      body: _loadingMaster
          ? _buildShimmerGrid()
          : _errorMaster != null
          ? _buildErrorState(_errorMaster!, _loadMasterData)
          : inventoryAsync.when(
              loading: _buildShimmerGrid,
              error: (e, _) => _buildErrorState(
                e.toString(),
                () => ref.invalidate(inventoryStreamProvider),
              ),
              data: (items) => _buildContent(context, items, authUser!.uid),
            ),
      floatingActionButton: _selectedIds.isEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showAddInventorySheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Item'),
            )
          : null,
    );
  }

  void _showAddInventorySheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (ctx) => const AddInventoryBottomSheet(),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<InventoryModel> items,
    String userId,
  ) {
    // Apply search/filter/sort
    var filtered = items.where(
      (i) => i.itemName.toLowerCase().contains(_searchQuery.toLowerCase()),
    );
    if (_filterType != 'all')
      filtered = filtered.where((i) => i.type == _filterType);
    if (_lowStockOnly)
      filtered = filtered.where((i) => i.quantity < i.lowStockThreshold);
    final sorted = filtered.toList()
      ..sort((a, b) {
        switch (_sortBy) {
          case 'qty':
            return a.quantity.compareTo(b.quantity);
          case 'date':
            return b.lastUpdated.compareTo(a.lastUpdated);
          default:
            return a.itemName.compareTo(b.itemName);
        }
      });

    if (sorted.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 8),
            Text('No items match your criteria'),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxWidth = constraints.maxWidth;
        final crossAxisCount = (maxWidth / 200).clamp(2, 4).toInt();

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 4 / 3.5,
          ),
          itemCount: sorted.length,
          itemBuilder: (ctx, idx) {
            final item = sorted[idx];
            final isLow = item.quantity < item.lowStockThreshold;
            final isSelected = _selectedIds.contains(item.id);
            final stripeColor = item.quantity == 0
                ? Colors.grey
                : isLow
                ? Colors.red
                : (item.type == 'raw' ? Colors.green : Colors.blue);

            return GestureDetector(
              onLongPress: () => setState(() {
                isSelected
                    ? _selectedIds.remove(item.id)
                    : _selectedIds.add(item.id);
              }),
              onTap: () {
                if (_selectedIds.isNotEmpty) {
                  setState(() {
                    isSelected
                        ? _selectedIds.remove(item.id)
                        : _selectedIds.add(item.id);
                  });
                } else {
                  _showDetailSheet(ctx, item);
                }
              },
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: isSelected ? 0.6 : 1,
                child: Slidable(
                  key: ValueKey(item.id),
                  endActionPane: ActionPane(
                    extentRatio: 0.4,
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _restockItem(item),
                        icon: Icons.restore,
                        label: 'Restock',
                        backgroundColor: Colors.green,
                      ),
                      // SlidableAction(
                      //   onPressed: (_) => InventoryRepository().deleteInventory(item.id),
                      //   icon: Icons.delete,
                      //   label: 'Delete',
                      //   backgroundColor: Colors.red,
                      // ),
                    ],
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        // left stripe
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(width: 4, color: stripeColor),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // header + badge
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  Icon(
                                    isLow
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                    color: isLow ? Colors.red : Colors.green,
                                    size: 18,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 7),
                              Text('Qty: ${item.quantity} ${item.unit}'),
                              Text(
                                'Type: ${item.type.toUpperCase()}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const Spacer(),
                              Text(
                                'Restocked: ${DateFormat.yMMMd().format(item.lastUpdated)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback retry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $message'),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: retry, child: const Text('Retry')),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Search'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Item name…'),
          onChanged: (v) => setState(() => _searchQuery = v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSortFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _filterType,
                decoration: const InputDecoration(labelText: 'Filter by Type'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(
                    value: 'RAW MATERIAL',
                    child: Text('Raw Material'),
                  ),
                  DropdownMenuItem(value: 'Prepared', child: Text('Prepared')),
                ],
                onChanged: (v) {
                  setState(() => _filterType = v!);
                  setModalState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Low-stock only'),
                value: _lowStockOnly,
                onChanged: (v) {
                  setState(() => _lowStockOnly = v);
                  setModalState(() {});
                },
              ),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(labelText: 'Sort by'),
                items: const [
                  DropdownMenuItem(value: 'name', child: Text('Name')),
                  DropdownMenuItem(value: 'qty', child: Text('Quantity')),
                  DropdownMenuItem(
                    value: 'date',
                    child: Text('Last Restocked'),
                  ),
                ],
                onChanged: (v) {
                  setState(() => _sortBy = v!);
                  setModalState(() {});
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _filterType = 'all';
                          _lowStockOnly = false;
                          _sortBy = 'name';
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restockItem(InventoryModel item) {
    final userId = ref.read(authStateProvider).value!.uid;
    InventoryRepository().updateInventory(item.id, {
      'quantity': item.lowStockThreshold * 2,
      'lastUpdated': Timestamp.now(),
      'updatedBy': userId,
    });
    addNotification('inventory', 'Restocked', '${item.itemName} restocked');
  }

  void _showDetailSheet(BuildContext ctx, InventoryModel item) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final userNameAsync = ref.watch(userNameByIdProvider(item.updatedBy));

          return Padding(
            padding: MediaQuery.of(ctx).viewInsets,
            child: DraggableScrollableSheet(
              expand: false,
              builder: (_, ctrl) => ListView(
                controller: ctrl,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                children: [
                  // Header
                  Text(
                    item.itemName,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${item.id}',
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const Divider(height: 32),

                  // Quantity & Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.storage_outlined, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '${item.quantity} ${item.unit}',
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.category_outlined, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            item.type.toUpperCase(),
                            style: Theme.of(ctx).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Low-stock threshold
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_outlined, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Reorder at ≤ ${item.lowStockThreshold}',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Last updated
                  Row(
                    children: [
                      const Icon(Icons.update, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Last restocked: ${DateFormat.yMMMd().format(item.lastUpdated)}',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Updated by
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 20),
                      const SizedBox(width: 6),
                      userNameAsync.when(
                        data: (name) => Text(
                          'Updated by: $name',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        loading: () => Text(
                          'Updated by: …',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                        error: (_, __) => Text(
                          'Updated by: Unknown',
                          style: Theme.of(ctx).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Stock History
                  Consumer(
                    builder: (context, ref, _) {
                      final historyAsync = ref.watch(
                        stockHistoryProvider(item.id),
                      );

                      return historyAsync.when(
                        loading: () => const CircularProgressIndicator(),
                        error: (err, stack) => Text('Error: $err'),
                        data: (historyList) => historyList.isEmpty
                            ? const Text('No history yet.')
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Text(
                                        '— Usage & Restock History —',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...historyList.map((entry) {
                                      final formattedDate = DateFormat(
                                        'dd MMM yyyy',
                                      ).format(entry.date);
                                      final color = entry.type == 'restock'
                                          ? Colors.green
                                          : Colors.red;
                                      final label = entry.type == 'restock'
                                          ? 'Restocked'
                                          : 'Used';

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '$label: ${entry.quantity} pcs',
                                              style: TextStyle(color: color),
                                            ),
                                            Text(formattedDate),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ],
                                ),
                              ),
                      );
                    },
                  ),


                  
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
