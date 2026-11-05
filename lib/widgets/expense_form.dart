import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../design_system/design_system.dart';
import '../models/expense_model.dart';
import '../models/topic_model.dart';
import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import 'category_field.dart';
import 'topic_picker.dart';

class ExpenseForm extends ConsumerStatefulWidget {
  final ExpenseModel? expense;
  final int initYear;
  final int initMonth;
  final int initDay;
  final String timezone;
  final String? initialAmount;
  final ExpenseType? initialType;
  final bool fullScreen;
  final VoidCallback? onSaved;

  const ExpenseForm({
    super.key,
    this.expense,
    required this.initYear,
    required this.initMonth,
    required this.initDay,
    this.timezone = 'America/New_York',
    this.initialAmount,
    this.initialType,
    this.fullScreen = false,
    this.onSaved,
  });

  @override
  ConsumerState<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends ConsumerState<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _contentController;
  late final TextEditingController _categoryController;
  final _noteFocusNode = FocusNode();

  late ExpenseType _type;
  late DateTime _selectedDate;
  int? _selectedTopicId;

  @override
  void initState() {
    super.initState();
    final expense = widget.expense;
    _titleController = TextEditingController(text: expense?.title ?? '');
    _amountController = TextEditingController(
      text: expense != null
          ? (expense.amount / 100).toStringAsFixed(2)
          : widget.initialAmount ?? '',
    );
    _contentController = TextEditingController(text: expense?.content ?? '');
    _categoryController = TextEditingController(text: expense?.category ?? '');
    _type = expense?.type ?? widget.initialType ?? ExpenseType.expense;
    _selectedDate = DateTime(
      widget.initYear,
      widget.initMonth,
      widget.initDay,
    );
    _selectedTopicId = expense?.topicId;
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
    final picked = await showPiggyDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  int? _effectiveTopicId(List<TopicModel> topics) {
    if (_selectedTopicId != null) return _selectedTopicId;
    if (widget.expense?.topicId != null) return widget.expense!.topicId;
    final lastUsed =
        ref.read(lastUsedTopicStorageProvider).getLastUsedTopicId();
    return resolveDefaultTopicId(topics, lastUsedTopicId: lastUsed);
  }

  Future<void> _pickTopic(List<TopicModel> topics) async {
    final picked = await showTopicPickerSheet(
      context,
      topics: topics,
      selectedTopicId: _effectiveTopicId(topics),
    );
    if (picked != null && mounted) {
      setState(() => _selectedTopicId = picked.id);
    }
  }

  void _submit(List<TopicModel> topics) {
    if (!_formKey.currentState!.validate()) return;
    final topicId = _effectiveTopicId(topics);
    if (topicId == null) return;

    final amount = double.tryParse(
          _amountController.text.replaceAll(',', ''),
        ) ??
        0;
    final now = DateTime.now();
    final occurredAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
      now.second,
    );
    final content = _contentController.text.trim();
    final category = _categoryController.text.trim();
    final expense = ExpenseModel(
      id: widget.expense?.id,
      topicId: topicId,
      title: _titleController.text.trim(),
      amount: (amount * 100).round(),
      content: content.isEmpty ? null : content,
      category: category.isEmpty ? null : category,
      type: _type,
      occurredAt: occurredAt,
      createdAt: widget.expense?.createdAt,
      updatedAt: widget.expense?.updatedAt,
    );

    ref.read(lastUsedTopicStorageProvider).saveLastUsedTopicId(topicId);
    final notifier = ref.read(expenseNotifierProvider.notifier);
    widget.expense == null
        ? notifier.addExpense(expense)
        : notifier.updateExpense(expense);
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expense != null;
    final bottomInset =
        widget.fullScreen ? 0.0 : MediaQuery.viewInsetsOf(context).bottom;
    final topicsAsync = ref.watch(myViewableTopicsProvider);
    final topics = topicsAsync.valueOrNull ?? const <TopicModel>[];
    final selectedTopicId = _effectiveTopicId(topics);
    final selectedTopic = findTopicById(topics, selectedTopicId);
    final tone =
        _type == ExpenseType.income ? PiggyTone.income : PiggyTone.expense;

    final content = Column(
      mainAxisSize: widget.fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (!widget.fullScreen)
          _SheetHeader(
            title: isEditing ? 'Edit transaction' : 'New transaction',
            onClose: () => Navigator.pop(context),
          ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              PiggySpace.page,
              PiggySpace.sm,
              PiggySpace.page,
              PiggySpace.lg,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TransactionTypeSelector(
                    value: _type,
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: PiggySpace.md),
                  _AmountPanel(
                    controller: _amountController,
                    tone: tone,
                  ),
                  const SizedBox(height: PiggySpace.xl),
                  const _SectionLabel('DETAILS'),
                  const SizedBox(height: PiggySpace.sm),
                  PiggySurface(
                    color: PiggyColors.card,
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        topicsAsync.when(
                          data: (availableTopics) => _SelectionRow(
                            icon: Icons.savings_outlined,
                            label: 'Topic',
                            value: selectedTopic?.title ?? 'Choose a topic',
                            valueColor: selectedTopic == null
                                ? PiggyColors.expense
                                : PiggyColors.ink,
                            onTap: () => _pickTopic(availableTopics),
                          ),
                          loading: () => const _SelectionRow(
                            icon: Icons.savings_outlined,
                            label: 'Topic',
                            value: 'Loading topics…',
                            trailing: SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          error: (_, __) => _SelectionRow(
                            icon: Icons.savings_outlined,
                            label: 'Topic',
                            value: 'Couldn’t load topics · Retry',
                            valueColor: PiggyColors.error,
                            onTap: () => ref.refresh(myViewableTopicsProvider),
                          ),
                        ),
                        const _InsetDivider(),
                        _SelectionRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: DateFormat(
                            'EEE, MMM d, yyyy',
                          ).format(_selectedDate),
                          onTap: _pickDate,
                        ),
                        const _InsetDivider(),
                        _TextEntryRow(
                          icon: Icons.edit_outlined,
                          label: 'Title',
                          hintText: 'What was this for?',
                          controller: _titleController,
                        ),
                        const _InsetDivider(),
                        _CategoryEntryRow(
                          controller: _categoryController,
                          onEditingComplete: () =>
                              _noteFocusNode.requestFocus(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: PiggySpace.xl),
                  const _SectionLabel('NOTE'),
                  const SizedBox(height: PiggySpace.sm),
                  PiggySurface(
                    color: PiggyColors.card,
                    padding: EdgeInsets.zero,
                    child: _TextEntryRow(
                      icon: Icons.notes_rounded,
                      label: 'Note',
                      hintText: 'Add a short note',
                      controller: _contentController,
                      focusNode: _noteFocusNode,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            PiggySpace.page,
            PiggySpace.sm,
            PiggySpace.page,
            bottomInset > 0 ? bottomInset + PiggySpace.sm : PiggySpace.lg,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: topicsAsync.hasValue && selectedTopicId != null
                  ? () => _submit(topics)
                  : null,
              child: Text(
                isEditing
                    ? 'Save changes'
                    : widget.fullScreen
                        ? (_type == ExpenseType.income
                            ? 'Add income'
                            : 'Add expense')
                        : 'Add transaction',
              ),
            ),
          ),
        ),
      ],
    );
    if (widget.fullScreen) {
      return Scaffold(
        appBar: AppBar(
          title:
              Text(_type == ExpenseType.income ? 'Add Income' : 'Add Expense'),
        ),
        body: SafeArea(top: false, child: content),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      child: content,
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _SheetHeader({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PiggySpace.page,
          0,
          PiggySpace.sm,
          PiggySpace.sm,
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: PiggyType.pageTitle)),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      );
}

class _TransactionTypeSelector extends StatelessWidget {
  final ExpenseType value;
  final ValueChanged<ExpenseType> onChanged;

  const _TransactionTypeSelector({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(PiggySpace.xs),
        decoration: BoxDecoration(
          color: PiggyColors.card,
          borderRadius: BorderRadius.circular(PiggyRadius.card),
        ),
        child: Row(
          children: [
            Expanded(
              child: _TypeOption(
                label: 'Expense',
                icon: Icons.north_east_rounded,
                tone: PiggyTone.expense,
                selected: value == ExpenseType.expense,
                onTap: () => onChanged(ExpenseType.expense),
              ),
            ),
            const SizedBox(width: PiggySpace.xs),
            Expanded(
              child: _TypeOption(
                label: 'Income',
                icon: Icons.south_west_rounded,
                tone: PiggyTone.income,
                selected: value == ExpenseType.income,
                onTap: () => onChanged(ExpenseType.income),
              ),
            ),
          ],
        ),
      );
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final PiggyTone tone;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.tone,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? tone.background : Colors.transparent,
        borderRadius: BorderRadius.circular(PiggyRadius.small),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(PiggyRadius.small),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PiggySpace.md,
              vertical: PiggySpace.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? Icons.check_rounded : icon,
                  size: 18,
                  color: selected ? tone.foreground : PiggyColors.secondary,
                ),
                const SizedBox(width: PiggySpace.sm),
                Text(
                  label,
                  style: PiggyType.itemTitle.copyWith(
                    color: selected ? tone.foreground : PiggyColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _AmountPanel extends StatelessWidget {
  final TextEditingController controller;
  final PiggyTone tone;

  const _AmountPanel({required this.controller, required this.tone});

  @override
  Widget build(BuildContext context) => PiggySurface(
        color: tone.background,
        padding: const EdgeInsets.fromLTRB(
          PiggySpace.lg,
          PiggySpace.md,
          PiggySpace.lg,
          PiggySpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AMOUNT (USD)',
              style: PiggyType.metadata.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d*\.?\d{0,2}'),
                ),
              ],
              style: PiggyType.summaryAmount.copyWith(
                color: tone.foreground,
                fontSize: 36,
                height: 1.2,
              ),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: PiggyType.summaryAmount.copyWith(
                  color: tone.foreground,
                  fontSize: 30,
                ),
                hintText: '0.00',
                hintStyle: PiggyType.summaryAmount.copyWith(
                  color: tone.foreground.withValues(alpha: 0.45),
                  fontSize: 36,
                ),
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(top: PiggySpace.xs),
              ),
              validator: (value) {
                final amount =
                    double.tryParse(value?.replaceAll(',', '') ?? '');
                if (amount == null || amount <= 0) {
                  return 'Enter an amount greater than zero';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),
          ],
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: PiggySpace.xs),
        child: Text(
          text,
          style: PiggyType.metadata.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      );
}

class _SelectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SelectionRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = PiggyColors.ink,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(PiggySpace.lg),
          child: Row(
            children: [
              _FieldIcon(icon),
              const SizedBox(width: PiggySpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PiggyType.metadata),
                    const SizedBox(height: PiggySpace.sm),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PiggyType.body.copyWith(
                        color: valueColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PiggySpace.sm),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: PiggyColors.muted,
                  ),
            ],
          ),
        ),
      );
}

// Override every border state: collapsed decorations otherwise inherit the
// app theme's outlines without the padding those outlines need.
InputDecoration _inlineInputDecoration(String hintText) => InputDecoration(
      hintText: hintText,
      hintStyle: PiggyType.body.copyWith(
        color: PiggyColors.secondary,
        height: 1.5,
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: PiggySpace.xs),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

class _TextEntryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hintText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final int maxLines;
  final TextInputAction textInputAction;

  const _TextEntryRow({
    required this.icon,
    required this.label,
    required this.hintText,
    required this.controller,
    this.focusNode,
    this.maxLines = 1,
    this.textInputAction = TextInputAction.next,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(PiggySpace.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FieldIcon(icon),
            const SizedBox(width: PiggySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: PiggyType.metadata),
                  const SizedBox(height: PiggySpace.sm),
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    maxLines: maxLines,
                    textInputAction: textInputAction,
                    cursorColor: PiggyColors.accent,
                    cursorWidth: 2,
                    cursorRadius: const Radius.circular(1),
                    textAlignVertical: TextAlignVertical.top,
                    style: PiggyType.body.copyWith(
                      fontWeight:
                          maxLines > 1 ? FontWeight.w400 : FontWeight.w600,
                      height: 1.5,
                    ),
                    decoration: _inlineInputDecoration(hintText),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _CategoryEntryRow extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onEditingComplete;

  const _CategoryEntryRow({
    required this.controller,
    required this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(PiggySpace.lg),
        child: Row(
          children: [
            const _FieldIcon(Icons.category_outlined),
            const SizedBox(width: PiggySpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Category', style: PiggyType.metadata),
                  const SizedBox(height: PiggySpace.sm),
                  CategoryField(
                    controller: controller,
                    onEditingComplete: onEditingComplete,
                    decoration: _inlineInputDecoration('Choose a category'),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: PiggyColors.muted,
            ),
          ],
        ),
      );
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;
  const _FieldIcon(this.icon);

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: PiggyColors.surface,
          borderRadius: BorderRadius.circular(PiggyRadius.small),
        ),
        child: Icon(icon, size: 18, color: PiggyColors.accent),
      );
}

class _InsetDivider extends StatelessWidget {
  const _InsetDivider();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.only(left: 64),
        child: Divider(height: 1),
      );
}
