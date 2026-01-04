import '../services/api_service.dart';
import '../config/constants.dart';

class RestaurantService {
  final ApiService _apiService = ApiService();

  // Get current user's restaurant
  Future<Map<String, dynamic>> getMyRestaurant() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] && responseData['data']['restaurantProfile'] != null) {
        final restaurantId = responseData['data']['restaurantProfile'];
        final restaurantRes = await _apiService.get('/api/restaurants/$restaurantId');
        return restaurantRes.data as Map<String, dynamic>;
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
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Toggle restaurant open/close status
  Future<Map<String, dynamic>> toggleStatus(String id) async {
    try {
      final response = await _apiService.put('/api/restaurants/$id/toggle-status');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get restaurant menu items
  Future<Map<String, dynamic>> getMenuItems(String restaurantId) async {
    try {
      final response = await _apiService.get('/api/restaurants/$restaurantId/menu');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Add menu item
  Future<Map<String, dynamic>> addMenuItem(String restaurantId, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/api/restaurants/$restaurantId/menu', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update menu item
  Future<Map<String, dynamic>> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.put('/api/menu/$id', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Delete menu item
  Future<Map<String, dynamic>> deleteMenuItem(String id) async {
    try {
      final response = await _apiService.delete('/api/menu/$id');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Toggle menu item availability
  Future<Map<String, dynamic>> toggleMenuItemAvailability(String id) async {
    try {
      final response = await _apiService.put('/api/menu/$id/toggle');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

