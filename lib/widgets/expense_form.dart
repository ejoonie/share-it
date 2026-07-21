import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import 'category_field.dart';

class ExpenseForm extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  final int initYear;
  final int initMonth;
  final int initDay;
  final String timezone;
  final String? initialAmount;
  final ExpenseType? initialType;

  const ExpenseForm({
    super.key,
    this.expense,
    required this.initYear,
    required this.initMonth,
    required this.initDay,
    this.timezone = 'America/New_York',
    this.initialAmount,
    this.initialType,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _contentController;
  late TextEditingController _categoryController;
  final _noteFocusNode = FocusNode();
  late ExpenseType _type;
  late DateTime _selectedDateUtc;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? (e.amount / 100.0).toStringAsFixed(2) : (widget.initialAmount ?? ''),
    );
    _contentController = TextEditingController(text: e?.content ?? '');
    _categoryController = TextEditingController(text: e?.category ?? '');
    _type = e?.type ?? widget.initialType ?? ExpenseType.expense;
    _selectedDateUtc = DateTime.utc(widget.initYear, widget.initMonth, widget.initDay);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _contentController.dispose();
    _categoryController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateUtc,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ); // local로 리턴함
    if (picked != null) setState(() => _selectedDateUtc = picked.toUtc());
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = ((double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0) * 100).round();
    final now = DateTime.now();
    final occurredAt = DateTime(
      _selectedDateUtc.year, _selectedDateUtc.month, _selectedDateUtc.day,
      now.hour, now.minute, now.second,
    ); // local

    if (widget.expense == null) {
      ref.read(expenseNotifierProvider.notifier).addExpense(ExpenseModel(
        title: _titleController.text.trim(),
        amount: amountCents,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        type: _type,
        occurredAt: occurredAt,
      ));
    } else {
      ref.read(expenseNotifierProvider.notifier).updateExpense(widget.expense!.copyWith(
        title: _titleController.text.trim(),
        amount: amountCents,
        content: () => _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        category: () => _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        type: _type,
        occurredAt: occurredAt,
      ));
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.92;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더 - 항상 고정
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 8, 0),
            child: Row(
              children: [
                Text(
                  isEditing ? 'Edit Transaction' : 'Add Transaction',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 폼 필드 - 스크롤 가능
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<ExpenseType>(
                      segments: const [
                        ButtonSegment(
                          value: ExpenseType.expense,
                          label: Text('Expense'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment(
                          value: ExpenseType.income,
                          label: Text('Income'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: (s) => setState(() => _type = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount (USD) *',
                        prefixIcon: Icon(Icons.attach_money),
                        hintText: '0.00',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Please enter an amount';
                        final amount = double.tryParse(v);
                        if (amount == null || amount <= 0) return 'Please enter a valid amount';
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(dateFormatter.format(_selectedDateUtc)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (_) => null,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    CategoryField(
                      controller: _categoryController,
                      onEditingComplete: () => _noteFocusNode.requestFocus(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contentController,
                      focusNode: _noteFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Note',
                        prefixIcon: Icon(Icons.notes),
                      ),
                      maxLines: 2,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          // Save 버튼 - 키보드 위에 고정
          Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(isEditing ? 'Save Changes' : 'Add'),
            ),
          ),
        ],
      ),
    );
  }
}

