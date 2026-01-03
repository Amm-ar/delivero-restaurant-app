import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _newOrders = [];
  List<OrderModel> _preparingOrders = [];
  List<OrderModel> _historyOrders = [];
  
  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get newOrders => _newOrders;
  List<OrderModel> get preparingOrders => _preparingOrders;
  List<OrderModel> get historyOrders => _historyOrders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all orders and categorize
  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _orderService.getOrders();

    if (result['success']) {
      final orders = result['orders'] as List<OrderModel>;
      
      _newOrders = orders.where((o) => 
        o.status == 'pending' || o.status == 'confirmed'
      ).toList();
      
      _preparingOrders = orders.where((o) => 
        o.status == 'preparing' || o.status == 'ready'
      ).toList();
      
      _historyOrders = orders.where((o) => 
        o.status == 'delivered' || o.status == 'cancelled'
      ).toList();
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update order status
  Future<bool> updateStatus(String orderId, String newStatus) async {
    final result = await _orderService.updateOrderStatus(orderId, newStatus);
    
    if (result['success']) {
      await fetchOrders(); // Refresh orders
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }
}
