import '../services/api_service.dart';
import '../config/constants.dart';

class RestaurantService {
  final ApiService _apiService = ApiService();

  // Get current user's restaurant
  Future<Map<String, dynamic>> getMyRestaurant() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      if (response['success'] && response['data']['restaurantProfile'] != null) {
        final restaurantId = response['data']['restaurantProfile'];
        final restaurantRes = await _apiService.get('/api/restaurants/$restaurantId');
        return restaurantRes;
      }
      return {'success': false, 'message': 'Restaurant profile not found'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update restaurant profile
  Future<Map<String, dynamic>> updateProfile(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/restaurants/$id', data: data);
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add menu item
  Future<Map<String, dynamic>> addMenuItem(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/menu-items', data: data);
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update menu item
  Future<Map<String, dynamic>> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/menu-items/$id', data: data);
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete menu item
  Future<Map<String, dynamic>> deleteMenuItem(String id) async {
    try {
      final response = await _apiService.delete('/api/menu-items/$id');
      return response;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
