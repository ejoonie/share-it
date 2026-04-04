import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../bloc/shopping_bloc.dart';
import '../bloc/shopping_event.dart';
import '../bloc/shopping_state.dart';
import '../../data/models/shopping_item_model.dart';
import '../widgets/shopping_item_tile.dart';
import '../widgets/shopping_form.dart';

class ShoppingScreen extends StatelessWidget {
  const ShoppingScreen({super.key});

  void _showAddForm(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<ShoppingBloc>(),
        child: const ShoppingForm(),
      ),
    );
  }

  void _confirmDeleteChecked(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('완료 항목 삭제'),
        content: const Text('체크된 항목을 모두 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              context.read<ShoppingBloc>().add(const DeleteCheckedItems());
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장볼 목록'),
        actions: [
          BlocBuilder<ShoppingBloc, ShoppingState>(
            builder: (context, state) {
              final hasChecked = state is ShoppingLoaded &&
                  state.checkedItems.isNotEmpty;
              if (!hasChecked) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: '완료 항목 삭제',
                onPressed: () => _confirmDeleteChecked(context),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ShoppingBloc, ShoppingState>(
        builder: (context, state) {
          if (state is ShoppingLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShoppingError) {
            return Center(child: Text('오류: ${state.message}'));
          }
          if (state is ShoppingLoaded) {
            return _ShoppingBody(state: state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ShoppingBody extends StatelessWidget {
  final ShoppingLoaded state;

  const _ShoppingBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final unchecked = state.uncheckedItems;
    final checked = state.checkedItems;
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    if (state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              '장볼 목록이 비어있습니다\n+ 버튼으로 추가하세요',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary bar
        if (state.totalEstimated > 0)
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    color: Colors.grey, size: 18),
                const SizedBox(width: 8),
                Text(
                  '총 ${state.items.length}개',
                  style: const TextStyle(color: Colors.grey),
                ),
                const Spacer(),
                Text(
                  '예상: ${formatter.format(state.totalEstimated / 100.0)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            children: [
              if (unchecked.isNotEmpty) ...[
                ...unchecked.map(
                  (item) => ShoppingItemTile(item: item),
                ),
              ],
              if (checked.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Text(
                    '완료 (${checked.length})',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13),
                  ),
                ),
                ...checked.map(
                  (item) => ShoppingItemTile(item: item),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
