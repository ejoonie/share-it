import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../design_system/components/dialogs.dart';
import '../providers/shopping_provider.dart';
import '../models/shopping_item_model.dart';
import 'shopping_form.dart';

class ShoppingItemTile extends ConsumerWidget {
  final ShoppingItemModel item;

  const ShoppingItemTile({super.key, required this.item});

  void _showEditForm(BuildContext context) {
    showPiggySheet<void>(
      context: context,
      builder: (_) => ShoppingForm(item: item),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showPiggyConfirmation(
      context: context,
      title: 'Delete this item?',
      message: 'This item will be removed from your shopping list.',
      detail: item.title,
      confirmLabel: 'Delete',
      icon: Icons.delete_outline_rounded,
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    ref.read(shoppingNotifierProvider.notifier).deleteItem(item.id!);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: item.isChecked,
          activeColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          onChanged: (_) =>
              ref.read(shoppingNotifierProvider.notifier).toggleItem(item),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isChecked
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.isChecked ? Colors.grey : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: _buildSubtitle(item),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.amount != null)
              Text(
                formatter.format(item.amountInDollars),
                style: TextStyle(
                  color: item.isChecked ? Colors.grey : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showEditForm(context);
                if (value == 'delete') _confirmDelete(context, ref);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        onTap: () =>
            ref.read(shoppingNotifierProvider.notifier).toggleItem(item),
      ),
    );
  }

  Widget? _buildSubtitle(ShoppingItemModel item) {
    if (item.content == null || item.content!.isEmpty) return null;
    return Text(
      item.content!,
      style: const TextStyle(fontSize: 12),
    );
  }
}
