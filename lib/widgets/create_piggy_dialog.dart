import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/core_providers.dart';
import '../providers/expense_provider.dart';
import '../providers/followed_piggies_provider.dart';
import '../providers/session_provider.dart';

Future<void> showCreatePiggyDialog(BuildContext context) => showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreatePiggyDialog(),
    );

class _CreatePiggyDialog extends ConsumerStatefulWidget {
  const _CreatePiggyDialog();

  @override
  ConsumerState<_CreatePiggyDialog> createState() => _CreatePiggyDialogState();
}

class _CreatePiggyDialogState extends ConsumerState<_CreatePiggyDialog> {
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final topic = await ref.read(topicRepositoryProvider).create(_name.text);
      if (!mounted) return;
      ref.read(selectedTopicIdProvider.notifier).state = topic.id;
      ref.read(sessionNotifierProvider.notifier).useTopic(topic);
      ref.invalidate(myViewableTopicsProvider);
      ref.invalidate(followedPiggiesProvider);
      ref.read(settingsRefreshProvider.notifier).update((value) => value + 1);
      await ref
          .read(lastUsedTopicStorageProvider)
          .saveLastUsedTopicId(topic.id);
      if (!mounted) return;
      await ref
          .read(expenseNotifierProvider.notifier)
          .includeTopicInSelection(topic.id);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Couldn’t create your piggy. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_saving,
        child: AlertDialog(
          title: const Text('Create a piggy'),
          content: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Give your new piggy a name.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Piggy name',
                    hintText: 'Everyday spending',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name for your piggy'
                      : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _create(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _saving ? null : _create,
              child: Text(_saving ? 'Creating…' : 'Create piggy'),
            ),
          ],
        ),
      );
}
