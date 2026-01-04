import 'api_service.dart';

class AnalyticsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAnalytics(String restaurantId, {String? startDate, String? endDate}) async {
    try {
      String path = '/restaurants/$restaurantId/analytics';
      Map<String, dynamic> queryParams = {};
      
      if (startDate != null && endDate != null) {
        queryParams['startDate'] = startDate;
        queryParams['endDate'] = endDate;
      }

      final response = await _apiService.get(path, queryParameters: queryParams);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.data['data'],
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to fetch analytics',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
