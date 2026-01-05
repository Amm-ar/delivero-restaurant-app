import 'package:flutter/material.dart';
import 'dart:io';
import '../services/restaurant_service.dart';
import '../models/menu_item_model.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  Map<String, dynamic>? _restaurant;
  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get restaurant => _restaurant;
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyRestaurant() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _restaurantService.getMyRestaurant();
      if (result['success'] == true) {
        _restaurant = result['data'];
        if (_restaurant != null) {
          await fetchMenuItems();
        }
      } else {
        _errorMessage = result['message'];
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    print('Provider: updateProfile called with data: $data');
    print('Provider: current _restaurant: $_restaurant');

    try {
      Map<String, dynamic> result;
      if (_restaurant == null) {
        print('Provider: Calling createProfile');
        result = await _restaurantService.createProfile(data);
      } else {
        print('Provider: Calling updateProfile for id: ${_restaurant!['_id']}');
        result = await _restaurantService.updateProfile(_restaurant!['_id'], data);
      }
      
      print('Provider: Result received: $result');

      if (result['success'] == true) {
        _restaurant = result['data'];
        return true;
      } else {
        _errorMessage = result['message'];
        print('Provider: Error message set: $_errorMessage');
        return false;
      }
    } catch (e, stackTrace) {
      print('Provider: EXCEPTION caught: $e');
      print('Provider: Stack trace: $stackTrace');
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus() async {
    if (_restaurant == null) return;

    final result = await _restaurantService.toggleStatus(_restaurant!['_id']);
    if (result['success']) {
      _restaurant!['isOpen'] = result['data']['isOpen'];
      notifyListeners();
    }
  }

  Future<void> fetchMenuItems() async {
    if (_restaurant == null) return;

    final result = await _restaurantService.getMenuItems(_restaurant!['_id']);
    if (result['success']) {
      _menuItems = (result['data'] as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
      notifyListeners();
    }
  }

  Future<bool> addMenuItem(Map<String, dynamic> data) async {
    if (_restaurant == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _restaurantService.addMenuItem(_restaurant!['_id'], data);
    if (result['success']) {
      _menuItems.add(MenuItem.fromJson(result['data']));
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMenuItem(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    final result = await _restaurantService.updateMenuItem(id, data);
    if (result['success']) {
      final index = _menuItems.indexWhere((element) => element.id == id);
      if (index != -1) {
        _menuItems[index] = MenuItem.fromJson(result['data']);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMenuItem(String id) async {
    final result = await _restaurantService.deleteMenuItem(id);
    if (result['success']) {
      _menuItems.removeWhere((element) => element.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> toggleMenuItemAvailability(String id) async {
    final result = await _restaurantService.toggleMenuItemAvailability(id);
    if (result['success']) {
      final index = _menuItems.indexWhere((element) => element.id == id);
      if (index != -1) {
        // We could just flip it locally if the response data is simple
        final current = _menuItems[index];
        _menuItems[index] = MenuItem(
          id: current.id,
          restaurantId: current.restaurantId,
          name: current.name,
          description: current.description,
          image: current.image,
          price: current.price,
          originalPrice: current.originalPrice,
          category: current.category,
          tags: current.tags,
          customizations: current.customizations,
          isAvailable: result['data']['isAvailable'],
          preparationTime: current.preparationTime,
        );
        notifyListeners();
      }
    }
  }

  Future<String?> uploadImage(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _restaurantService.uploadImage(imageFile);
      
      if (result['success'] == true || result['imageUrl'] != null) {
        return result['imageUrl'];
      } else {
        _errorMessage = result['message'];
        return null;
      }
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

