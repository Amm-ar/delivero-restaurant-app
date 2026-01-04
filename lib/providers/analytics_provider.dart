import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  Map<String, dynamic>? _analyticsData;
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get analyticsData => _analyticsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchAnalytics(String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _analyticsService.getAnalytics(restaurantId);

    if (result['success']) {
      _analyticsData = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }
}
