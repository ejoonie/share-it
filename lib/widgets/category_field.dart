import 'package:flutter/material.dart';

const _kDefaultCategories = [
  'Food', 'Transport', 'Shopping', 'Medical',
  'Entertainment', 'Utilities', 'Housing', 'Other',
];

class CategoryField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final VoidCallback? onEditingComplete;

  const CategoryField({
    super.key,
    required this.controller,
    this.textInputAction = TextInputAction.next,
    this.onEditingComplete,
  });

  @override
  State<CategoryField> createState() => _CategoryFieldState();
}

class _CategoryFieldState extends State<CategoryField> {
  Future<void> _openPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CategoryPickerSheet(initial: widget.controller.text),
    );
    if (result != null) {
      widget.controller.text = result;
      widget.onEditingComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openPicker,
      child: AbsorbPointer(
        child: TextFormField(
          controller: widget.controller,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category_outlined),
            hintText: 'Optional',
            suffixIcon: Icon(Icons.expand_more),
          ),
          textInputAction: widget.textInputAction,
        ),
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final String initial;
  const _CategoryPickerSheet({required this.initial});

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  late TextEditingController _searchController;
  List<String> _filtered = _kDefaultCategories;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initial);
    _filter(widget.initial);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _kDefaultCategories
          : _kDefaultCategories
              .where((c) => c.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  void _select(String value) => Navigator.pop(context, value);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final showCustom = _searchController.text.trim().isNotEmpty &&
        !_kDefaultCategories.any(
          (c) => c.toLowerCase() == _searchController.text.trim().toLowerCase(),
        );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search or type a category',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filter('');
                        },
                      )
                    : null,
              ),
              onChanged: _filter,
              onSubmitted: (v) {
                if (v.trim().isNotEmpty) _select(v.trim());
              },
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView(
              shrinkWrap: true,
              children: [
                if (showCustom)
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: Text('Use "${_searchController.text.trim()}"'),
                    onTap: () => _select(_searchController.text.trim()),
                  ),
                ..._filtered.map(
                  (c) => ListTile(
                    title: Text(c),
                    trailing: _searchController.text.trim().toLowerCase() == c.toLowerCase()
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () => _select(c),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
