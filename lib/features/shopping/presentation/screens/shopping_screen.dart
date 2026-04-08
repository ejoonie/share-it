import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/shopping_provider.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/shopping_form.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  void _showAddForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ShoppingForm(),
    );
  }

  void _confirmDeleteChecked(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Checked Items'),
        content: const Text('Remove all checked items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(shoppingNotifierProvider.notifier).deleteCheckedItems();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(shoppingNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (state.checkedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Delete checked items',
              onPressed: () => _confirmDeleteChecked(context, ref),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return _ShoppingBody(state: state);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShoppingBody extends StatelessWidget {
  final ShoppingState state;

  const _ShoppingBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final unchecked = state.uncheckedItems;
    final checked = state.checkedItems;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Shopping list is empty\nTap + to add items',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (state.totalEstimated > 0)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${state.items.length} items',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  'Est: ${formatter.format(state.totalEstimated / 100.0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 12),
            children: [
              if (unchecked.isNotEmpty) ...[
                ...unchecked.map((item) => ShoppingItemTile(item: item)),
              ],
              if (checked.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Text(
                    'Done (${checked.length})',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                ...checked.map((item) => ShoppingItemTile(item: item)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
