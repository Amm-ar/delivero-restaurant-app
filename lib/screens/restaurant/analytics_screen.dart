import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/restaurant_provider.dart';
import '../../config/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final restaurant = Provider.of<RestaurantProvider>(context, listen: false).restaurant;
      if (restaurant != null) {
        Provider.of<AnalyticsProvider>(context, listen: false).fetchAnalytics(restaurant['_id']);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.nileBlue));
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(provider.errorMessage!));
          }

          final data = provider.analyticsData;
          if (data == null) {
            return const Center(child: Text('No data available'));
          }

          final summary = data['summary'];
          final dailyStats = data['dailyStats'] as List;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryGrid(summary),
                const SizedBox(height: 24),

                // Revenue Chart
                const Text('Revenue (Last 7 Days)', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                _buildRevenueChart(dailyStats),
                const SizedBox(height: 24),

                // Top Selling Items
                const Text('Top Selling Items', style: AppTextStyles.h4),
                const SizedBox(height: 16),
                _buildTopItemsList(data['topItems'] as List),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid(Map<String, dynamic> summary) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.5,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Total Revenue', "${AppConstants.currencySymbol} ${(summary['totalRevenue'] as num).toStringAsFixed(2)}", Icons.attach_money, AppColors.palmGreen),
        _buildStatCard('Total Orders', summary['totalOrders'].toString(), Icons.shopping_basket, AppColors.nileBlue),
        _buildStatCard('Avg. Order', "${AppConstants.currencySymbol} ${(summary['averageOrderValue'] as num).toStringAsFixed(2)}", Icons.trending_up, AppColors.sunsetAmber),
        _buildStatCard('Completed', summary['completedOrders'].toString(), Icons.check_circle, Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.gray)),
            ],
          ),
          const Spacer(),
          Text(value, style: AppTextStyles.h3.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(List dailyStats) {
    if (dailyStats.isEmpty) return const Center(child: Text('No historical data'));

    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 24, top: 24, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: dailyStats.asMap().entries.map((e) {
                return FlSpot(e.key.toDouble(), (e.value['revenue'] as num).toDouble());
              }).toList(),
              isCurved: true,
              color: AppColors.palmGreen,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.palmGreen.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemsList(List topItems) {
    if (topItems.isEmpty) return const Center(child: Text('No items data'));

    return Column(
      children: topItems.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item['name'] ?? 'Unknown Item'),
            subtitle: Text("${item['totalQuantity']} units sold"),
            trailing: Text(
              "${AppConstants.currencySymbol} ${(item['totalRevenue'] as num).toStringAsFixed(2)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }
}
