import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/stats_data.dart';
import '../services/api_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late Future<StatsData> _statsData;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _statsData = _apiService.getStatsData(); // ✅ Stats load safely
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: FutureBuilder<StatsData>(
        future: _statsData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final stats = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatCards(context, stats),
                const SizedBox(height: 24),
                _buildChart(context, stats.monthlyEarnings),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------ STAT CARDS ------------------
  Widget _buildStatCards(BuildContext context, StatsData stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          "Jobs Completed",
          "${stats.jobsCompleted}",
          FontAwesomeIcons.briefcase,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          "Total Earnings",
          "₹${stats.totalEarnings.toStringAsFixed(2)}", // ✅ replaced $
          FontAwesomeIcons.indianRupeeSign,
          Colors.green,
        ),
        _buildStatCard(
          context,
          "Total Expenses",
          "₹${stats.totalExpenses.toStringAsFixed(2)}",
          FontAwesomeIcons.receipt,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          "Active Jobs",
          "${stats.activeJobs}",
          FontAwesomeIcons.clock,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ------------------ CHART ------------------
  Widget _buildChart(BuildContext context, List<MonthlyEarning> monthlyEarnings) {
    return SizedBox(
      height: 300,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Monthly Earnings",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: monthlyEarnings
                            .map((e) =>
                            FlSpot(e.month.toDouble(), e.earning.toDouble()))
                            .toList(),
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        color: Theme.of(context).colorScheme.primary,
                        belowBarData: BarAreaData(
                          show: true,
                          color:
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
