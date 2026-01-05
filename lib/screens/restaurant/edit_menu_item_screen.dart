import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/order_provider.dart'; // Just in case
import '../../providers/restaurant_provider.dart';
import '../../models/menu_item_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'manage_categories_screen.dart';
import '../../services/api_service.dart';

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
  // late TextEditingController _categoryController; // Removed
  // late TextEditingController _imageController; // Removed
  
  String? _selectedCategory;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  List<String> _categories = [];
  
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item?.price.toString() ?? '');
    // _categoryController = TextEditingController(text: widget.item?.category ?? '');
    // _imageController = TextEditingController(text: widget.item?.image ?? 'default-food.png');
    
    _selectedCategory = widget.item?.category;
    
    final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
    if (restaurant != null && restaurant['menuCategories'] != null) {
      _categories = List<String>.from(restaurant['menuCategories']);
    }
    
    // Ensure selected category is in the list
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty && !_categories.contains(_selectedCategory)) {
      _categories.add(_selectedCategory!);
    }
    _isAvailable = widget.item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    // _categoryController.dispose();
    // _imageController.dispose();
    super.dispose();
  }

  Future<void> _refreshCategories() async {
    final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
    if (restaurant != null && restaurant['menuCategories'] != null) {
      setState(() {
        _categories = List<String>.from(restaurant['menuCategories']);
        if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
          _selectedCategory = null; 
        }
      });
    }
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, "temp_item_${DateTime.now().millisecondsSinceEpoch}.jpg");
    
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: 70,
      minWidth: 800,
      minHeight: 800,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      File? compressed = await _compressImage(file);
      setState(() {
        _imageFile = compressed ?? file;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    String imageUrl = widget.item?.image ?? 'default-food.png';
    if (_imageFile != null) {
      final uploaded = await provider.uploadImage(_imageFile!);
      if (uploaded != null) {
        imageUrl = uploaded;
      } else {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(provider.errorMessage ?? 'Image upload failed'), backgroundColor: AppColors.error),
           );
         }
         return;
      }
    }

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'category': _selectedCategory,
      'image': imageUrl,
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
                // Image Picker
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: (_imageFile != null)
                        ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                        : (widget.item?.image != null && widget.item!.image != 'default-food.png')
                          ? DecorationImage(image: NetworkImage(ApiConstants.getImageUrl(widget.item!.image)), fit: BoxFit.cover)
                          : null,
                    ),
                    child: (_imageFile == null && (widget.item?.image == null || widget.item!.image == 'default-food.png'))
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Add Item Image', style: TextStyle(color: Colors.grey)),
                          ],
                        )
                      : null,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      flex: 1,
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
                      flex: 2,
                      child: _categories.isEmpty
                        ? OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
                              _refreshCategories();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Add Categories First'),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(labelText: 'Category'),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val),
                            validator: (val) => val == null ? 'Please select category' : null,
                          ),
                    ),
                  ],
                ),
                if (_categories.isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()));
                        _refreshCategories();
                      },
                      child: const Text('Manage Categories'),
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
