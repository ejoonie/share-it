import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../widgets/category_field.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final int initYear;
  final int initMonth;
  final int initDay;
  final String initialAmount;
  final ExpenseType initialType;

  const AddExpenseScreen({
    super.key,
    required this.initYear,
    required this.initMonth,
    required this.initDay,
    required this.initialAmount,
    required this.initialType,
  });

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _contentController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteFocusNode = FocusNode();

  late ExpenseType _type;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.initialAmount;
    _type = widget.initialType;
    _selectedDate = DateTime(widget.initYear, widget.initMonth, widget.initDay);
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
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final amountCents = ((double.tryParse(_amountController.text) ?? 0) * 100).round();
    final now = DateTime.now();

    ref.read(expenseNotifierProvider.notifier).addExpense(
      ExpenseModel(
        title: _titleController.text.trim(),
        amount: amountCents,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        type: _type,
        occurredAt: DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          now.hour, now.minute, now.second,
        ),
      ),
    );

    // AmountEntryScreen까지 pop
    Navigator.of(context)
      ..pop()
      ..pop();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(_type == ExpenseType.income ? 'Add Income' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (USD)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final amount = double.tryParse(v ?? '');
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
                      child: Text(dateFormatter.format(_selectedDate)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                      hintText: 'Title',
                    ),
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
                      hintText: 'Optional',
                    ),
                    maxLines: 2,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
