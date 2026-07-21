import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense_model.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';

class AmountEntryScreen extends StatefulWidget {
  final int initYear;
  final int initMonth;
  final int initDay;

  const AmountEntryScreen({
    super.key,
    required this.initYear,
    required this.initMonth,
    required this.initDay,
  });

  @override
  State<AmountEntryScreen> createState() => _AmountEntryScreenState();
}

class _AmountEntryScreenState extends State<AmountEntryScreen> {
  String _input = '';
  int _cursor = 0;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.initYear, widget.initMonth, widget.initDay);
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

  bool get _hasOperator =>
      RegExp(r'[+\-*/]').hasMatch(_input.replaceFirst(RegExp(r'^-'), ''));

  double? get _evaluated {
    if (!_hasOperator && !_input.contains('(')) return null;
    return _evaluate(_input);
  }

  double get _finalAmount {
    if (_evaluated != null) return _evaluated!.abs();
    return double.tryParse(_input) ?? 0;
  }

  void _insert(String key) {
    _input = _input.substring(0, _cursor) + key + _input.substring(_cursor);
    _cursor += key.length;
  }

  void _onKey(String key) {
    setState(() {
      if (key == '⌫') {
        if (_cursor > 0) {
          _input = _input.substring(0, _cursor - 1) + _input.substring(_cursor);
          _cursor--;
        }
      } else if (key == '.') {
        final before = _input.substring(0, _cursor);
        final lastSegment = before.split(RegExp(r'[+\-*/(]')).last;
        if (!lastSegment.contains('.')) _insert(key);
      } else if (['+', '-', '*', '/'].contains(key)) {
        if (_input.isEmpty && key != '-') return;
        // 바로 앞이 연산자면 교체 (음수 부호 제외)
        if (_cursor > 0 &&
            RegExp(r'[+\-*/]').hasMatch(_input[_cursor - 1]) &&
            key != '-') {
          _input = _input.substring(0, _cursor - 1) + key + _input.substring(_cursor);
        } else {
          _insert(key);
        }
      } else {
        _insert(key);
      }
    });
  }

  void _onPaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final cleaned = (data?.text?.trim() ?? '').replaceAll(RegExp(r'[^\d.+\-*/()]'), '');
    if (cleaned.isNotEmpty) {
      setState(() {
        _input = cleaned;
        _cursor = cleaned.length;
      });
    }
  }

  void _submit(ExpenseType type) {
    if (_finalAmount <= 0) return;
    final amountStr = _finalAmount.toStringAsFixed(2);
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          initYear: _selectedDate.year,
          initMonth: _selectedDate.month,
          initDay: _selectedDate.day,
          initialAmount: amountStr,
          initialType: type,
        ),
      ),
    );
  }

  String _dateLabel() {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final diff = today
        .difference(DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day))
        .inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }

  @override
  Widget build(BuildContext context) {
    final evaluated = _evaluated;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── 헤더 ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_drop_down, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _dateLabel(),
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── 금액 표시 (커서 지원 TextField) ──────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '\$',
                          style: TextStyle(
                            fontSize: 36,
                            color: Colors.grey.shade400,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              _input.isEmpty
                                  ? const TextSpan(
                                      text: '0',
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  : TextSpan(children: [
                                      TextSpan(text: _input.substring(0, _cursor)),
                                      // 커서 표시
                                      const TextSpan(
                                        text: '|',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w100,
                                        ),
                                      ),
                                      TextSpan(text: _input.substring(_cursor)),
                                    ]),
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.w300,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (evaluated != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '= ${evaluated.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Income / Expense 버튼 ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Income',
                      color: AppTheme.primaryColor,
                      onTap: () => _submit(ExpenseType.income),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      label: 'Expense',
                      color: const Color(0xFFEF5FA7),
                      onTap: () => _submit(ExpenseType.expense),
                    ),
                  ),
                ],
              ),
            ),

            // ── 붙여넣기 + 커서 이동 ──────────────────────────────
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
              child: Row(
                children: [
                  _SmallIconButton(
                    icon: Icons.content_paste_rounded,
                    tooltip: 'Paste',
                    onTap: _onPaste,
                  ),
                  const Spacer(),
                  _SmallIconButton(
                    icon: Icons.first_page,
                    tooltip: 'Move to start',
                    onTap: () => setState(() => _cursor = 0),
                  ),
                  _SmallIconButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Move left',
                    onTap: () => setState(() {
                      if (_cursor > 0) _cursor--;
                    }),
                  ),
                  _SmallIconButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Move right',
                    onTap: () => setState(() {
                      if (_cursor < _input.length) _cursor++;
                    }),
                  ),
                  _SmallIconButton(
                    icon: Icons.last_page,
                    tooltip: 'Move to end',
                    onTap: () => setState(() => _cursor = _input.length),
                  ),
                ],
              ),
            ),

            // ── 커스텀 키보드 ─────────────────────────────────────
            _NumPad(onKey: _onKey),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── 서브 위젯 ────────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final void Function(String) onKey;

  const _NumPad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    // 연산자 행: 괄호 포함
    const operatorRow = ['(', ')', '+', '-', '×', '÷'];
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: [
        Row(
          children: operatorRow.map((op) {
            final key = op == '×' ? '*' : op == '÷' ? '/' : op;
            return Expanded(
              child: _NumKey(label: op, onTap: () => onKey(key), isOperator: true),
            );
          }).toList(),
        ),
        ...rows.map(
          (row) => Row(
            children: row
                .map((k) => Expanded(
                      child: _NumKey(label: k, onTap: () => onKey(k)),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _NumKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isOperator;

  const _NumKey({required this.label, required this.onTap, this.isOperator = false});

  @override
  Widget build(BuildContext context) {
    final isBackspace = label == '⌫';

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: isOperator ? 56 : 64,
        width: double.infinity,
        child: Center(
          child: isBackspace
              ? Icon(Icons.backspace_outlined, size: 22, color: Colors.grey.shade600)
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: isOperator ? 22 : 28,
                    fontWeight: FontWeight.w300,
                    color: isOperator
                        ? AppTheme.primaryColor
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── 사칙연산 + 괄호 파서 ──────────────────────────────────────────────────────

double? _evaluate(String expr) {
  try {
    final tokens = _tokenize(expr.trim());
    if (tokens.isEmpty) return null;
    final c = _Cursor();
    final result = _parseExpr(tokens, c);
    if (c.pos != tokens.length) return null; // 파싱 불완전
    return (result * 100).round() / 100;
  } catch (_) {
    return null;
  }
}

List<String> _tokenize(String expr) {
  final tokens = <String>[];
  var i = 0;
  while (i < expr.length) {
    final ch = expr[i];
    if (RegExp(r'[\d.]').hasMatch(ch)) {
      var num = '';
      while (i < expr.length && RegExp(r'[\d.]').hasMatch(expr[i])) {
        num += expr[i++];
      }
      tokens.add(num);
    } else if (ch == '-' &&
        (tokens.isEmpty ||
            ['+', '-', '*', '/', '('].contains(tokens.last))) {
      // 음수 부호
      i++;
      var num = '-';
      while (i < expr.length && RegExp(r'[\d.]').hasMatch(expr[i])) {
        num += expr[i++];
      }
      tokens.add(num);
    } else if (['+', '-', '*', '/', '(', ')'].contains(ch)) {
      tokens.add(ch);
      i++;
    } else {
      i++;
    }
  }
  return tokens;
}

class _Cursor {
  int pos = 0;
}

double _parseExpr(List<String> tokens, _Cursor c) {
  var result = _parseTerm(tokens, c);
  while (c.pos < tokens.length &&
      (tokens[c.pos] == '+' || tokens[c.pos] == '-')) {
    final op = tokens[c.pos++];
    final right = _parseTerm(tokens, c);
    result = op == '+' ? result + right : result - right;
  }
  return result;
}

double _parseTerm(List<String> tokens, _Cursor c) {
  var result = _parseFactor(tokens, c);
  while (c.pos < tokens.length &&
      (tokens[c.pos] == '*' || tokens[c.pos] == '/')) {
    final op = tokens[c.pos++];
    final right = _parseFactor(tokens, c);
    if (op == '/' && right == 0) throw Exception('division by zero');
    result = op == '*' ? result * right : result / right;
  }
  return result;
}

double _parseFactor(List<String> tokens, _Cursor c) {
  if (c.pos < tokens.length && tokens[c.pos] == '(') {
    c.pos++; // '(' 소비
    final result = _parseExpr(tokens, c);
    if (c.pos < tokens.length && tokens[c.pos] == ')') {
      c.pos++; // ')' 소비
    }
    return result;
  }
  if (c.pos >= tokens.length) throw Exception('unexpected end');
  return double.parse(tokens[c.pos++]);
}
