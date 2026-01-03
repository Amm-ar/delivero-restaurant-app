import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/restaurant_provider.dart';
import '../../providers/auth_provider.dart';

class CreateRestaurantScreen extends StatefulWidget {
  const CreateRestaurantScreen({super.key});

  @override
  State<CreateRestaurantScreen> createState() => _CreateRestaurantScreenState();
}

class _CreateRestaurantScreenState extends State<CreateRestaurantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCuisine;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false).fetchMyRestaurant().then((_) {
        final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
        if (restaurant != null) {
          _addressController.text = restaurant['address'] ?? '';
          _phoneController.text = restaurant['phone'] ?? '';
          _descriptionController.text = restaurant['description'] ?? '';
          if (restaurant['cuisine'] != null && restaurant['cuisine'].isNotEmpty) {
            _selectedCuisine = restaurant['cuisine'][0];
          }
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await Provider.of<RestaurantProvider>(context, listen: false).updateProfile({
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'description': _descriptionController.text.trim(),
      'cuisine': [_selectedCuisine ?? 'Other'],
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.restaurant == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Text(
                    'Complete your profile to start receiving orders.',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter phone' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  DropdownButtonFormField<String>(
                    value: _selectedCuisine,
                    decoration: const InputDecoration(
                      labelText: 'Primary Cuisine',
                      prefixIcon: Icon(Icons.restaurant_outlined),
                    ),
                    items: AppConstants.cuisineTypes.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCuisine = val),
                    validator: (value) => value == null ? 'Please select cuisine' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter description' : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  
                  ElevatedButton(
                    onPressed: provider.isLoading ? null : _handleSave,
                    child: provider.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Profile'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
