import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/topic_model.dart';
import '../../core/providers/core_providers.dart';
import '../../core/repositories/topic_repository.dart';

class TopicEditScreen extends ConsumerStatefulWidget {
  final TopicModel topic;

  const TopicEditScreen({super.key, required this.topic});

  @override
  ConsumerState<TopicEditScreen> createState() => _TopicEditScreenState();
}

class _TopicEditScreenState extends ConsumerState<TopicEditScreen> {
  late TextEditingController _titleController;
  late bool _isDefault;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.topic.title);
    _isDefault = widget.topic.isDefault;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newTitle = _titleController.text.trim();
    if (newTitle.isEmpty) return;

    final titleChanged = newTitle != widget.topic.title;
    final defaultChanged = _isDefault != widget.topic.isDefault;

    if (!titleChanged && !defaultChanged) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final authToken = ref.read(tokenStorageProvider).getAuthToken();
      final updated = await TopicRepository(
        apiClient: ref.read(apiClientProvider),
        authToken: authToken ?? '',
      ).update(
        widget.topic.id,
        title: titleChanged ? newTitle : null,
        isDefault: defaultChanged && _isDefault ? true : null,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Piggy'),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Enter piggy name',
            ),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Set as Default'),
            subtitle: _isDefault
                ? const Text('This piggy is currently set as default.')
                : const Text('This piggy will be used by default'),
            value: _isDefault,
            onChanged: widget.topic.isDefault
                ? null // 이미 default면 끄지 못하게
                : (v) => setState(() => _isDefault = v),
          ),
        ],
      ),
    );
  }
}
