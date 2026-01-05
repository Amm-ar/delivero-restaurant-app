import '../services/api_service.dart';
import '../config/constants.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class RestaurantService {
  final ApiService _apiService = ApiService();

  // Get current user's restaurant
  Future<Map<String, dynamic>> getMyRestaurant() async {
    try {
      final response = await _apiService.get('/api/auth/me');
      final responseData = response.data as Map<String, dynamic>;
      
      if (responseData['success'] && responseData['data']['restaurantProfile'] != null) {
        final profile = responseData['data']['restaurantProfile'];
        
        // If profile is already populated (Map), return it directly
        if (profile is Map<String, dynamic>) {
          return {'success': true, 'data': profile};
        } else if (profile is String) {
          // If it's an ID (String), fetch it
          final restaurantRes = await _apiService.get('/api/restaurants/$profile');
          return restaurantRes.data as Map<String, dynamic>;
        }
      }
      return {'success': false, 'message': 'Restaurant profile not found'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Create restaurant profile
  Future<Map<String, dynamic>> createProfile(Map<String, dynamic> data) async {
    print('Service: createProfile called');
    try {
      final response = await _apiService.post('/api/restaurants', data: data);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Update restaurant profile
  Future<Map<String, dynamic>> updateProfile(String id, Map<String, dynamic> data) async {
    print('Service: updateProfile called for id: $id');
    print('Service: updateProfile data: $data');
    try {
      final response = await _apiService.put('/api/restaurants/$id', data: data);
      print('Service: updateProfile response: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('Service: updateProfile error: $e');
      // Handle DioException to extract error message from response
      if (e is DioException) {
        final errorMessage = e.response?.data?['message'] ?? 
                           e.message ?? 
                           'Failed to update profile';
        print('Service: updateProfile error message: $errorMessage');
        return {'success': false, 'message': errorMessage};
      }
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

  // Upload image
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      String fileName = imageFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(imageFile.path, filename: fileName),
      });

      final response = await _apiService.post('/api/upload/image', data: formData);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

