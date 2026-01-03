import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';

class ManageMenuScreen extends StatelessWidget {
  const ManageMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: AppColors.gray),
            const SizedBox(height: 16),
            const Text(
              'Menu Management',
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            const Text(
              'Coming Soon: Add/Edit your menu items here.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
