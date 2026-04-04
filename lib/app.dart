import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/expenses/data/repositories/expense_repository.dart';
import 'features/expenses/presentation/bloc/expense_bloc.dart';
import 'features/expenses/presentation/bloc/expense_event.dart';
import 'features/shopping/data/repositories/shopping_repository.dart';
import 'features/shopping/presentation/bloc/shopping_bloc.dart';
import 'features/shopping/presentation/bloc/shopping_event.dart';
import 'shared/widgets/bottom_nav_bar.dart';

class ShareItApp extends StatelessWidget {
  const ShareItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ExpenseRepository()),
        RepositoryProvider(create: (_) => ShoppingRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ExpenseBloc(
              repository: context.read<ExpenseRepository>(),
            )..add(LoadExpenses(DateTime.now())),
          ),
          BlocProvider(
            create: (context) => ShoppingBloc(
              repository: context.read<ShoppingRepository>(),
            )..add(const LoadShoppingItems()),
          ),
        ],
        child: MaterialApp(
          title: 'Share It',
          theme: AppTheme.lightTheme,
          home: const MainScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
    );
  }
}
