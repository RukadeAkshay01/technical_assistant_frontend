class StatsData {
  final int jobsCompleted;
  final double totalEarnings;
  final double totalExpenses;
  final int activeJobs;
  final List<MonthlyEarning> monthlyEarnings;

  StatsData({
    required this.jobsCompleted,
    required this.totalEarnings,
    required this.totalExpenses,
    required this.activeJobs,
    required this.monthlyEarnings,
  });

  factory StatsData.fromJson(Map<String, dynamic> json) {
    return StatsData(
      jobsCompleted: json['jobs_completed'] as int,
      totalEarnings: (json['total_earnings'] as num).toDouble(),
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      activeJobs: json['active_jobs'] as int,
      monthlyEarnings: (json['monthly_earnings'] as List)
          .map((e) => MonthlyEarning.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'jobs_completed': jobsCompleted,
      'total_earnings': totalEarnings,
      'total_expenses': totalExpenses,
      'active_jobs': activeJobs,
      'monthly_earnings': monthlyEarnings.map((e) => e.toJson()).toList(),
    };
  }
}

class MonthlyEarning {
  final int month;
  final double earning;

  MonthlyEarning({
    required this.month,
    required this.earning,
  });

  factory MonthlyEarning.fromJson(Map<String, dynamic> json) {
    return MonthlyEarning(
      month: json['month'] as int,
      earning: (json['earning'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'earning': earning,
    };
  }
}