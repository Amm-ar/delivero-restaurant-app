import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/restaurant_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:geolocator/geolocator.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';

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
  final _nameController = TextEditingController(); // Added name controller
  String? _selectedCuisine;
  bool _isSaving = false;
  
  File? _logoFile;
  File? _coverFile;
  String? _logoUrl;
  String? _coverUrl;
  double? _latitude;
  double? _longitude;
  bool _gettingLocation = false;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RestaurantProvider>(context, listen: false).fetchMyRestaurant().then((_) {
        final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
        if (restaurant != null) {
          _nameController.text = restaurant['name'] ?? '';
          _addressController.text = restaurant['address'] ?? '';
          _phoneController.text = restaurant['phone'] ?? '';
          _descriptionController.text = restaurant['description'] ?? '';
          _logoUrl = restaurant['logo'];
          _coverUrl = restaurant['coverImage'];
          if (restaurant['cuisine'] != null && restaurant['cuisine'].isNotEmpty) {
            _selectedCuisine = restaurant['cuisine'][0];
          }
          if (restaurant['location'] != null && restaurant['location']['coordinates'] != null) {
            final coords = restaurant['location']['coordinates'];
            if (coords is List && coords.length == 2) {
              _longitude = coords[0]; // GeoJSON is [lng, lat]
              _latitude = coords[1];
            }
          }
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<File?> _compressImage(File file) async {
    final tempDir = await getTemporaryDirectory();
    final path = p.join(tempDir.path, "temp_${DateTime.now().millisecondsSinceEpoch}.jpg");
    
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      path,
      quality: 70,
      minWidth: 1024,
      minHeight: 1024,
    );

    return result != null ? File(result.path) : null;
  }

  Future<void> _pickImage(bool isLogo) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      File? compressed = await _compressImage(file);
      
      if (compressed != null) {
        setState(() {
          if (isLogo) {
            _logoFile = compressed;
          } else {
            _coverFile = compressed;
          }
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    String? uploadedLogo = _logoUrl;
    String? uploadedCover = _coverUrl;

    try {
      if (_logoFile != null) {
        final logoUrl = await provider.uploadImage(_logoFile!);
        if (logoUrl != null) {
          uploadedLogo = logoUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage ?? 'Logo upload failed'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }
      
      if (_coverFile != null) {
        final coverUrl = await provider.uploadImage(_coverFile!);
        if (coverUrl != null) {
          uploadedCover = coverUrl;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(provider.errorMessage ?? 'Cover image upload failed'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isSaving = false);
          return;
        }
      }
      
      print('Proceeding to update profile with data...');
      print('Profile data: name=${_nameController.text.trim()}, address=${_addressController.text.trim()}, phone=${_phoneController.text.trim()}');
      print('Logo URL: $uploadedLogo, Cover URL: $uploadedCover');

      final success = await provider.updateProfile({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'description': _descriptionController.text.trim(),
        'cuisine': [_selectedCuisine ?? 'Other'],
        'logo': uploadedLogo,
        'coverImage': uploadedCover,
        if (_latitude != null && _longitude != null) ...{
          'latitude': _latitude,
          'longitude': _longitude,
        },
      });

      print('Update profile result: success=$success, error=${provider.errorMessage}');

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        final errorMsg = provider.errorMessage ?? 'Failed to save profile';
        print('Showing error: $errorMsg');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isSaving = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Profile'),
        actions: [
          Consumer<LocaleProvider>(
            builder: (context, provider, _) => DropdownButton<Locale>(
              value: provider.locale,
              icon: const Icon(Icons.language, color: Colors.white),
              dropdownColor: AppColors.nileBlue,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: Locale('en'), child: Text('English', style: TextStyle(color: Colors.black))),
                DropdownMenuItem(value: Locale('ar'), child: Text('العربية', style: TextStyle(color: Colors.black))),
              ],
              onChanged: (val) {
                if (val != null) provider.setLocale(val);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<RestaurantProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.restaurant == null && !_isSaving) {
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

                  // Cover Image
                  GestureDetector(
                    onTap: () => _pickImage(false),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: (_coverFile != null)
                          ? DecorationImage(image: FileImage(_coverFile!), fit: BoxFit.cover)
                          : (_coverUrl != null)
                            ? DecorationImage(image: NetworkImage("${ApiConstants.baseUrl}$_coverUrl"), fit: BoxFit.cover)
                            : null,
                      ),
                      child: (_coverFile == null && _coverUrl == null)
                        ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: Colors.grey))
                        : Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.edit, size: 20),
                            ),
                          ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Logo Image
                  Center(
                    child: GestureDetector(
                      onTap: () => _pickImage(true),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: (_logoFile != null)
                              ? FileImage(_logoFile!)
                              : (_logoUrl != null)
                                ? NetworkImage("${ApiConstants.baseUrl}$_logoUrl") as ImageProvider
                                : null,
                            child: (_logoFile == null && _logoUrl == null)
                              ? const Icon(Icons.restaurant, size: 40, color: Colors.grey)
                              : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: AppColors.palmGreen, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Restaurant Name',
                      prefixIcon: Icon(Icons.store_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter restaurant name' : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  // Location Button
                  OutlinedButton.icon(
                    onPressed: _gettingLocation ? null : _getCurrentLocation,
                    icon: _gettingLocation 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(Icons.my_location, color: _latitude != null ? Colors.green : null),
                    label: Text(_latitude != null 
                      ? 'Location Set (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})' 
                      : 'Get Current Location'),
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
                    onPressed: (provider.isLoading || _isSaving) ? null : _handleSave,
                    child: (provider.isLoading || _isSaving) 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.save),
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
