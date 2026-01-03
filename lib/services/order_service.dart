import '../models/order_model.dart';
import 'api_service.dart';
import '../config/constants.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  // Get restaurant orders
  Future<Map<String, dynamic>> getOrders({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (status != null) queryParams['status'] = status;

      final response = await _apiService.get(
        ApiConstants.orders,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success']) {
        final orders = (response.data['data'] as List)
            .map((o) => OrderModel.fromJson(o))
            .toList();

        return {
          'success': true,
          'orders': orders,
          'total': response.data['total'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to load orders'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Update order status
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final response = await _apiService.put(
        '${ApiConstants.orders}/$orderId/status',
        data: {'status': status},
      );

      if (response.statusCode == 200 && response.data['success']) {
        return {
          'success': true,
          'order': OrderModel.fromJson(response.data['data']),
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update status'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
