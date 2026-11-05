import 'package:flutter/material.dart';

import 'design_system/design_system.dart';
import 'screens/design_system_screen.dart';

/// Standalone catalog: no Firebase, sign-in, network or saved user data.
void main() => runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PiggyTheme.light,
        home: const DesignSystemScreen(),
      ),
    );
