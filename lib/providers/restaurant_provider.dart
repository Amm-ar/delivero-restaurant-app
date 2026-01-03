import 'package:flutter/material.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider with ChangeNotifier {
  final RestaurantService _restaurantService = RestaurantService();

  Map<String, dynamic>? _restaurant;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get restaurant => _restaurant;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMyRestaurant() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _restaurantService.getMyRestaurant();
    if (result['success']) {
      _restaurant = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    if (_restaurant == null) return false;
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _restaurantService.updateProfile(_restaurant!['_id'], data);
    
    if (result['success']) {
      _restaurant = result['data'];
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
  
  // Menu Item Actions can be added here as well, 
  // but let's keep it simple for onboarding first.
}
