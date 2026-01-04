import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../models/menu_item_model.dart';
import 'edit_menu_item_screen.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({super.key});

  @override
  State<ManageMenuScreen> createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false).fetchMenuItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditMenuItemScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.menuItems.isEmpty) {
            return Center(child: CircularProgressIndicator(color: AppColors.nileBlue));
          }

          if (provider.menuItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: AppColors.gray),
                  const SizedBox(height: 16),
                  const Text('No menu items yet', style: AppTextStyles.h3),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditMenuItemScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Item'),
                  ),
                ],
              ),
            );
          }

          // Group by category
          final Map<String, List<MenuItem>> groupedItems = {};
          for (var item in provider.menuItems) {
            if (!groupedItems.containsKey(item.category)) {
              groupedItems[item.category] = [];
            }
            groupedItems[item.category]!.add(item);
          }

          final categories = groupedItems.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: categories.length,
            itemBuilder: (context, catIndex) {
              final category = categories[catIndex];
              final items = groupedItems[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      category,
                      style: AppTextStyles.h4.copyWith(color: AppColors.nileBlue),
                    ),
                  ),
                  ...items.map((item) => _buildMenuItemCard(context, provider, item)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(BuildContext context, RestaurantProvider provider, MenuItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            item.image.startsWith('http') ? item.image : '${ApiConstants.baseUrl}/uploads/${item.image}',
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 60,
              height: 60,
              color: AppColors.gray.withOpacity(0.2),
              child: const Icon(Icons.fastfood, color: AppColors.gray),
            ),
          ),
        ),
        title: Text(item.name, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 4),
            Text(
              '${AppConstants.currencySymbol} ${item.price.toStringAsFixed(2)}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.nileBlue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: item.isAvailable,
              activeColor: AppColors.palmGreen,
              onChanged: (_) => provider.toggleMenuItemAvailability(item.id),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditMenuItemScreen(item: item)),
                  );
                } else if (value == 'delete') {
                  _showDeleteConfirm(context, provider, item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, RestaurantProvider provider, MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteMenuItem(item.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
