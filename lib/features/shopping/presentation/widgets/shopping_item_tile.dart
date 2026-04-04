import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/shopping_bloc.dart';
import '../bloc/shopping_event.dart';
import '../../data/models/shopping_item_model.dart';
import '../widgets/shopping_form.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItemModel item;

  const ShoppingItemTile({super.key, required this.item});

  void _showEditForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ShoppingBloc>(),
        child: ShoppingForm(item: item),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${item.title}" 항목을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ShoppingBloc>()
                  .add(DeleteShoppingItem(item.id!));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Checkbox(
          value: item.isChecked,
          activeColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          onChanged: (_) => context
              .read<ShoppingBloc>()
              .add(ToggleShoppingItem(item)),
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
                if (value == 'delete') _confirmDelete(context);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('수정')),
                PopupMenuItem(value: 'delete', child: Text('삭제')),
              ],
            ),
          ],
        ),
        onTap: () => context
            .read<ShoppingBloc>()
            .add(ToggleShoppingItem(item)),
      ),
    );
  }

  Widget? _buildSubtitle(ShoppingItemModel item) {
    final parts = <String>[];
    if (item.quantity != null && item.quantity!.isNotEmpty) {
      parts.add(item.quantity!);
    }
    if (item.note != null && item.note!.isNotEmpty) {
      parts.add(item.note!);
    }
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      style: const TextStyle(fontSize: 12),
    );
  }
}
