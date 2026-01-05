import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../providers/order_provider.dart';
import '../../models/order_model.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../restaurant/create_restaurant_screen.dart';
import '../restaurant/manage_menu_screen.dart';
import '../restaurant/analytics_screen.dart';
import 'dart:async';
import '../../providers/restaurant_provider.dart';
import '../../services/socket_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const NewOrdersTab(),
    const PreparingTab(),
    const HistoryTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).fetchOrders();
      Provider.of<RestaurantProvider>(context, listen: false).fetchMyRestaurant();
      _setupSocket();
    });
  }

  Future<void> _setupSocket() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.user != null) {
      final token = await const FlutterSecureStorage().read(key: StorageKeys.accessToken);
      final socketService = SocketService();
      socketService.connect(token ?? '', auth.user!.id);
      
      socketService.on('newOrder', (data) {
        if (mounted) {
          _showNewOrderAlert(data);
          Provider.of<OrderProvider>(context, listen: false).fetchOrders();
        }
      });
    }
  }

  void _showNewOrderAlert(dynamic data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
             Icon(Icons.notifications_active, color: AppColors.sunsetAmber),
             SizedBox(width: 8),
             Text('New Order!'),
          ],
        ),
        content: Text('You have a new order #${data['orderNumber']}.\nAmount: ${AppConstants.currencySymbol} ${data['total']}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedIndex = 0);
            },
            child: const Text('View Orders'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    SocketService().disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Dashboard'),
        actions: [
          // Status Toggle
          Consumer<RestaurantProvider>(
            builder: (context, provider, _) {
              if (provider.restaurant == null) return const SizedBox();
              final isOpen = provider.restaurant!['isOpen'] ?? false;
              return Row(
                children: [
                   Text(
                    isOpen ? 'OPEN' : 'CLOSED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOpen ? AppColors.palmGreen : AppColors.error,
                    ),
                  ),
                  Switch(
                    value: isOpen,
                    onChanged: (_) => provider.toggleStatus(),
                    activeColor: AppColors.palmGreen,
                  ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<OrderProvider>(context, listen: false).fetchOrders();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Consumer<AuthProvider>(
          builder: (context, auth, child) => ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.restaurant, size: 30, color: AppColors.nileBlue),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      auth.user?.name ?? 'Restaurant Owner',
                      style: AppTextStyles.h4.copyWith(color: Colors.white),
                    ),
                    Text(
                      auth.user?.email ?? '',
                      style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.store_outlined, color: AppColors.nileBlue),
                title: const Text('Restaurant Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateRestaurantScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined, color: AppColors.nileBlue),
                title: const Text('Manage Menu'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageMenuScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.analytics_outlined, color: AppColors.nileBlue),
                title: const Text('Business Analytics'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AnalyticsScreen()),
                  );
                  },
              ),
              const Divider(),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.darkMode),
                  secondary: const Icon(Icons.dark_mode, color: AppColors.nileBlue),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(val),
                ),
              ),
              Consumer<LocaleProvider>(
                builder: (context, localeProvider, _) => ListTile(
                  leading: const Icon(Icons.language, color: AppColors.nileBlue),
                  title: Text(AppLocalizations.of(context)!.language),
                  trailing: Text(localeProvider.locale.languageCode == 'ar' ? 'العربية' : 'English'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(AppLocalizations.of(context)!.language),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('English'),
                              onTap: () {
                                localeProvider.setLocale(const Locale('en'));
                                Navigator.pop(context);
                              },
                              trailing: localeProvider.locale.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.nileBlue) : null,
                            ),
                            ListTile(
                              title: const Text('العربية'),
                              onTap: () {
                                localeProvider.setLocale(const Locale('ar'));
                                Navigator.pop(context);
                              },
                              trailing: localeProvider.locale.languageCode == 'ar' ? const Icon(Icons.check, color: AppColors.nileBlue) : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Logout'),
                onTap: () {
                  auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: 'New Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Preparing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}

// New Orders Tab
class NewOrdersTab extends StatelessWidget {
  const NewOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.nileBlue));
        }

        if (provider.newOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: AppColors.gray),
                const SizedBox(height: 16),
                Text(
                  'No new orders',
                  style: AppTextStyles.h3.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.newOrders.length,
          itemBuilder: (context, index) {
            return OrderCard(
              order: provider.newOrders[index],
              showActions: true,
            );
          },
        );
      },
    );
  }
}

// Preparing Tab
class PreparingTab extends StatelessWidget {
  const PreparingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.nileBlue));
        }

        if (provider.preparingOrders.isEmpty) {
          return Center(
            child: Text(
              'No orders in preparation',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.preparingOrders.length,
          itemBuilder: (context, index) {
            return OrderCard(
              order: provider.preparingOrders[index],
              showActions: true,
            );
          },
        );
      },
    );
  }
}

// History Tab
class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: AppColors.nileBlue));
        }

        if (provider.historyOrders.isEmpty) {
          return Center(
            child: Text(
              'No order history',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.historyOrders.length,
          itemBuilder: (context, index) {
            return OrderCard(
              order: provider.historyOrders[index],
              showActions: false,
            );
          },
        );
      },
    );
  }
}

// Order Card Widget
class OrderCard extends StatelessWidget {
  final OrderModel order;
  final bool showActions;

  const OrderCard({
    super.key,
    required this.order,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: AppTextStyles.h4,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(order.createdAt),
              style: AppTextStyles.caption.copyWith(color: AppColors.gray),
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Order items
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.name}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                  Text(
                    '${AppConstants.currencySymbol} ${item.price.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            const Divider(),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total', style: AppTextStyles.h4),
                Text(
                  '${AppConstants.currencySymbol} ${order.pricing.total.toStringAsFixed(2)}',
                  style: AppTextStyles.h4.copyWith(color: AppColors.nileBlue),
                ),
              ],
            ),
            
            if (showActions) ...[
              const SizedBox(height: 16),
              _buildActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    
    if (order.status == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () async {
                await provider.updateStatus(order.id!, 'cancelled');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
              ),
              child: const Text('Reject'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                await provider.updateStatus(order.id!, 'confirmed');
              },
              child: const Text('Accept'),
            ),
          ),
        ],
      );
    }
    
    if (order.status == 'confirmed') {
      return ElevatedButton(
        onPressed: () async {
          await provider.updateStatus(order.id!, 'preparing');
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 45),
        ),
        child: const Text('Start Preparing'),
      );
    }
    
    if (order.status == 'preparing') {
      return ElevatedButton(
        onPressed: () async {
          await provider.updateStatus(order.id!, 'ready');
        },
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 45),
        ),
        child: const Text('Mark as Ready'),
      );
    }
    
    return const SizedBox();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.sunsetAmber;
      case 'confirmed':
      case 'preparing':
        return AppColors.nileBlue;
      case 'ready':
        return AppColors.palmGreen;
      case 'delivered':
        return AppColors.palmGreen;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.gray;
    }
  }
}
