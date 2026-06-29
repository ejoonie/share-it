import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/shopping_provider.dart';
import '../models/shopping_item_model.dart';

class ShoppingForm extends ConsumerStatefulWidget {
  final ShoppingItemModel? item;

  const ShoppingForm({super.key, this.item});

  @override
  ConsumerState<ShoppingForm> createState() => _ShoppingFormState();
}

class _ShoppingFormState extends ConsumerState<ShoppingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _titleController = TextEditingController(text: i?.title ?? '');
    _amountController = TextEditingController(
      text: i?.amount != null
          ? (i!.amount! / 100.0).toStringAsFixed(2)
          : '',
    );
    _contentController = TextEditingController(text: i?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    int? amountCents;
    final amountText = _amountController.text.trim();
    if (amountText.isNotEmpty) {
      final amountDouble = double.tryParse(amountText);
      if (amountDouble != null) {
        amountCents = (amountDouble * 100).round();
      }
    }

    if (widget.item == null) {
      ref.read(shoppingNotifierProvider.notifier).addItem(
            ShoppingItemModel(
              title: _titleController.text.trim(),
              amount: amountCents,
              content: _contentController.text.trim().isEmpty
                  ? null
                  : _contentController.text.trim(),
            ),
          );
    } else {
      ref.read(shoppingNotifierProvider.notifier).updateItem(
            widget.item!.copyWith(
              title: _titleController.text.trim(),
              amount: () => amountCents,
              content: () => _contentController.text.trim().isEmpty
                  ? null
                  : _contentController.text.trim(),
            ),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  isEditing ? 'Edit Item' : 'Add Item',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Item name *',
                prefixIcon: Icon(Icons.shopping_cart_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter an item name'
                  : null,
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Est. price',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Note',
                prefixIcon: Icon(Icons.notes),
              ),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Save Changes' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
