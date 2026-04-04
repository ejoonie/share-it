import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/expense_bloc.dart';
import '../bloc/expense_event.dart';
import '../../data/models/expense_model.dart';

class ExpenseForm extends StatefulWidget {
  final ExpenseModel? expense;
  final DateTime initialDate;

  const ExpenseForm({super.key, this.expense, required this.initialDate});

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late TextEditingController _categoryController;
  late ExpenseType _type;
  late DateTime _selectedDate;

  final List<String> _categories = [
    '식비',
    '교통',
    '쇼핑',
    '의료',
    '문화',
    '통신',
    '주거',
    '기타',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? (e.amount / 100.0).toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: e?.note ?? '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _type = e?.type ?? ExpenseType.expense;
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountText = _amountController.text.replaceAll(',', '');
    final amountDouble = double.tryParse(amountText) ?? 0.0;
    final amountCents = (amountDouble * 100).round();

    if (widget.expense == null) {
      // Create new
      final now = DateTime.now();
      final createdAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        now.hour,
        now.minute,
        now.second,
      );
      context.read<ExpenseBloc>().add(
            AddExpense(
              ExpenseModel(
                title: _titleController.text.trim(),
                amount: amountCents,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                category: _categoryController.text.trim().isEmpty
                    ? null
                    : _categoryController.text.trim(),
                type: _type,
                createdAt: createdAt,
                updatedAt: createdAt,
              ),
            ),
          );
    } else {
      // Update existing
      context.read<ExpenseBloc>().add(
            UpdateExpense(
              widget.expense!.copyWith(
                title: _titleController.text.trim(),
                amount: amountCents,
                note: _noteController.text.trim().isEmpty
                    ? null
                    : _noteController.text.trim(),
                category: _categoryController.text.trim().isEmpty
                    ? null
                    : _categoryController.text.trim(),
                type: _type,
                updatedAt: DateTime.now(),
              ),
            ),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final dateFormatter = DateFormat('yyyy년 MM월 dd일');
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Text(
                  isEditing ? '내역 수정' : '내역 추가',
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

            // Type toggle
            SegmentedButton<ExpenseType>(
              segments: const [
                ButtonSegment(
                  value: ExpenseType.expense,
                  label: Text('지출'),
                  icon: Icon(Icons.remove_circle_outline),
                ),
                ButtonSegment(
                  value: ExpenseType.income,
                  label: Text('수입'),
                  icon: Icon(Icons.add_circle_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const SizedBox(height: 12),

            // Date
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: '날짜',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(dateFormatter.format(_selectedDate)),
              ),
            ),
            const SizedBox(height: 12),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목 *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '제목을 입력해주세요' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: '금액 (USD) *',
                prefixIcon: Icon(Icons.attach_money),
                hintText: '0.00',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return '금액을 입력해주세요';
                final amount = double.tryParse(v);
                if (amount == null || amount <= 0) return '올바른 금액을 입력해주세요';
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            // Category
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _categoryController.text),
              optionsBuilder: (value) {
                if (value.text.isEmpty) return _categories;
                return _categories.where(
                  (c) => c.contains(value.text),
                );
              },
              onSelected: (option) => _categoryController.text = option,
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return _CategoryField(
                  autocompleteController: controller,
                  categoryController: _categoryController,
                  focusNode: focusNode,
                  onEditingComplete: onEditingComplete,
                );
              },
            ),
            const SizedBox(height: 12),

            // Note
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '메모',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // Submit
            ElevatedButton(
              onPressed: _submit,
              child: Text(isEditing ? '수정 완료' : '추가'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful widget that syncs the autocomplete controller with the external
/// category controller, properly managing the listener lifecycle.
class _CategoryField extends StatefulWidget {
  final TextEditingController autocompleteController;
  final TextEditingController categoryController;
  final FocusNode focusNode;
  final VoidCallback onEditingComplete;

  const _CategoryField({
    required this.autocompleteController,
    required this.categoryController,
    required this.focusNode,
    required this.onEditingComplete,
  });

  @override
  State<_CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<_CategoryField> {
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    widget.autocompleteController.text = widget.categoryController.text;
    _listener = () {
      widget.categoryController.text = widget.autocompleteController.text;
    };
    widget.autocompleteController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.autocompleteController.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.autocompleteController,
      focusNode: widget.focusNode,
      onEditingComplete: widget.onEditingComplete,
      decoration: const InputDecoration(
        labelText: '카테고리',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      textInputAction: TextInputAction.next,
    );
  }
}
