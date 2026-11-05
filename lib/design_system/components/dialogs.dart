import 'package:flutter/material.dart';

import '../tokens.dart';

/// All confirmation routes return true only for an explicit primary action.
Future<bool?> showPiggyConfirmation({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  IconData icon = Icons.info_outline_rounded,
  String cancelLabel = 'Cancel',
  String? detail,
  bool destructive = false,
  bool barrierDismissible = true,
}) =>
    showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: PiggyColors.ink.withValues(alpha: .32),
      builder: (_) => PiggyConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        detail: detail,
        icon: icon,
        destructive: destructive,
      ),
    );

class PiggyConfirmationDialog extends StatelessWidget {
  const PiggyConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.detail,
    this.icon = Icons.info_outline_rounded,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final String? detail;
  final IconData icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final foreground = destructive ? PiggyColors.error : PiggyColors.accent;
    final background =
        destructive ? PiggyColors.errorSoft : PiggyColors.accentSoft;
    return Dialog(
      backgroundColor: PiggyColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PiggyRadius.dialog),
        side: const BorderSide(color: PiggyColors.line),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 26, color: foreground),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                namesRoute: true,
                header: true,
                child: Text(
                  title,
                  style:
                      PiggyType.pageTitle.copyWith(fontSize: 22, height: 1.25),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: PiggyType.body
                    .copyWith(color: PiggyColors.secondary, height: 1.55),
              ),
              if (detail != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: PiggyColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    detail!,
                    style: PiggyType.itemTitle.copyWith(height: 1.4),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cancel = TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: PiggyColors.card,
                      foregroundColor: PiggyColors.ink,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(cancelLabel, textAlign: TextAlign.center),
                  );
                  final confirm = FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: foreground,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(confirmLabel, textAlign: TextAlign.center),
                  );
                  if (constraints.maxWidth < 280 ||
                      MediaQuery.textScalerOf(context).scale(14) > 20) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        confirm,
                        const SizedBox(height: 10),
                        cancel,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: cancel),
                      const SizedBox(width: 12),
                      Expanded(child: confirm),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Forms own keyboard insets; the shared shell owns modal chrome and safe areas.
Future<T?> showPiggySheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: PiggyColors.surface,
      barrierColor: PiggyColors.ink.withValues(alpha: .32),
      constraints: const BoxConstraints(maxWidth: PiggySize.contentMaxWidth),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(PiggyRadius.sheet)),
      ),
      builder: (context) => SafeArea(top: false, child: builder(context)),
    );

Future<DateTime?> showPiggyDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DatePickerMode initialDatePickerMode = DatePickerMode.day,
}) =>
    showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDatePickerMode: initialDatePickerMode,
      barrierColor: PiggyColors.ink.withValues(alpha: .32),
    );
