import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/tokens.dart';

/// One native input preserves paste, autofill and backspace behavior while
/// presenting the same six digit boxes across authentication flows.
class VerificationCodeField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const VerificationCodeField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.autofocus = true,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<VerificationCodeField> {
  final _focus = FocusNode();
  String? _lastAutoSubmittedCode;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _handleChanged(String value) {
    widget.onChanged?.call(value);

    if (value.length < 6) {
      _lastAutoSubmittedCode = null;
      return;
    }
    if (value.length == 6 && value != _lastAutoSubmittedCode) {
      _lastAutoSubmittedCode = value;
      widget.onSubmitted?.call(value);
    }
  }

  void _handleSubmitted(String value) {
    if (value.length == 6) {
      if (value == _lastAutoSubmittedCode) return;
      _lastAutoSubmittedCode = value;
    }
    widget.onSubmitted?.call(value);
  }

  @override
  void dispose() {
    _focus.removeListener(_refresh);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) => LayoutBuilder(
          builder: (context, constraints) {
            final gap = constraints.maxWidth < 280 ? 6.0 : 8.0;
            final height =
                ((constraints.maxWidth - gap * 5) / 6).clamp(40.0, 56.0);
            final active = value.text.length.clamp(0, 5);
            return SizedBox(
              height: height,
              child: Stack(
                children: [
                  ExcludeSemantics(
                    child: Row(
                      children: List.generate(
                        6,
                        (index) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: gap / 2),
                            child: Container(
                              height: height,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: widget.enabled
                                    ? PiggyColors.surface
                                    : PiggyColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _focus.hasFocus &&
                                          widget.enabled &&
                                          index == active
                                      ? PiggyColors.accent
                                      : PiggyColors.line,
                                  width: _focus.hasFocus &&
                                          widget.enabled &&
                                          index == active
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: FittedBox(
                                child: Text(
                                  index < value.text.length
                                      ? value.text[index]
                                      : '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: PiggyColors.ink,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focus,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      autocorrect: false,
                      enableSuggestions: false,
                      showCursor: false,
                      style: const TextStyle(color: Colors.transparent),
                      decoration: const InputDecoration(
                        labelText: '6-digit code',
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelStyle: TextStyle(color: Colors.transparent),
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      onTap: () =>
                          widget.controller.selection = TextSelection.collapsed(
                        offset: widget.controller.text.length,
                      ),
                      onChanged: _handleChanged,
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
