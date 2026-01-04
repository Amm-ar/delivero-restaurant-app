import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/order_provider.dart'; // Just in case
import '../../providers/restaurant_provider.dart';
import '../../models/menu_item_model.dart';

class EditMenuItemScreen extends StatefulWidget {
  final MenuItem? item;

  const EditMenuItemScreen({super.key, this.item});

  @override
  State<EditMenuItemScreen> createState() => _EditMenuItemScreenState();
}

class _EditMenuItemScreenState extends State<EditMenuItemScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _categoryController;
  late TextEditingController _imageController;
  
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    _categoryController = TextEditingController(text: widget.item?.category ?? '');
    _imageController = TextEditingController(text: widget.item?.image ?? 'default-food.png');
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'category': _categoryController.text,
      'image': _imageController.text,
      'isAvailable': _isAvailable,
    };

    bool success;
    if (widget.item == null) {
      success = await provider.addMenuItem(data);
    } else {
      success = await provider.updateMenuItem(widget.item!.id, data);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item ${widget.item == null ? 'added' : 'updated'} successfully')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Operation failed'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item == null ? 'Add Menu Item' : 'Edit Menu Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (val) => val == null || val.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: '${AppConstants.currencySymbol} ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _categoryController,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: (val) => val == null || val.isEmpty ? 'Please enter a category' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
               TextFormField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image Filename/URL',
                  hintText: 'e.g. burgers/cheese-burger.jpg',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Is this item currently available to order?'),
                value: _isAvailable,
                activeColor: AppColors.palmGreen,
                onChanged: (val) => setState(() => _isAvailable = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Consumer<RestaurantProvider>(
                  builder: (context, provider, _) {
                    return provider.isLoading 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(widget.item == null ? 'ADD ITEM' : 'SAVE CHANGES');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
