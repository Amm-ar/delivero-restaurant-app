import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/restaurant_provider.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final List<String> _categories = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
    if (restaurant != null && restaurant['menuCategories'] != null) {
      _categories.addAll(List<String>.from(restaurant['menuCategories']));
    }
  }

  Future<void> _saveCategories() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    final success = await provider.updateProfile({
      'menuCategories': _categories,
    });

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categories updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'Failed to update'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addCategory(String name) {
    if (name.isNotEmpty && !_categories.contains(name)) {
      setState(() {
        _categories.add(name);
      });
      _saveCategories();
    }
  }

  void _removeCategory(String name) {
    setState(() {
      _categories.remove(name);
    });
    _saveCategories();
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Category Name (e.g., Starters)'),
          textCapitalization: TextCapitalization.sentences,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addCategory(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _categories.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.category_outlined, size: 60, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text(
                    'No categories defined',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: _showAddDialog,
                     icon: const Icon(Icons.add),
                     label: const Text('Add First Category'),
                   ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _categories.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final category = _categories[i];
                return ListTile(
                  title: Text(category, style: AppTextStyles.bodyLarge),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.palmGreen.withOpacity(0.1),
                    child: Text(category[0].toUpperCase(), style: const TextStyle(color: AppColors.palmGreen)),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _removeCategory(category),
                  ),
                );
              },
            ),
      floatingActionButton: _categories.isNotEmpty 
        ? FloatingActionButton(
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          )
        : null,
    );
  }
}
