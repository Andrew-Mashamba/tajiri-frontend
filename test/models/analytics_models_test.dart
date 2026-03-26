import 'package:flutter_test/flutter_test.dart';
import 'package:tajiri/models/analytics_models.dart';

void main() {
  group('AnalyticsDashboard', () {
    test('fromJson parses full dashboard', () {
      final d = AnalyticsDashboard.fromJson({
        'total_views': 10000, 'total_likes': 500, 'total_shares': 100,
        'total_comments': 200, 'avg_engagement_rate': 5.5,
        'follower_count': 1000, 'follower_change_30d': 50,
        'threads_triggered_30d': 3, 'posts_count_30d': 15,
        'session_depth_avg': 4.2, 'best_posting_time': '10:00 AM',
        'top_content_format': 'video', 'top_category': 'music',
        'engagement_trend': 'up',
        'daily_metrics': [
          {'date': '2026-03-01', 'views': 100, 'likes': 10, 'followers': 5},
        ],
      });
      expect(d.totalViews, 10000);
      expect(d.avgEngagementRate, 5.5);
      expect(d.dailyMetrics.length, 1);
      expect(d.dailyMetrics[0].date, '2026-03-01');
    });

    test('fromJson handles empty data', () {
      final d = AnalyticsDashboard.fromJson({});
      expect(d.totalViews, 0);
      expect(d.engagementTrend, 'stable');
      expect(d.dailyMetrics, isEmpty);
    });
  });

  group('PostPerformance', () {
    test('fromJson parses post metrics', () {
      final p = PostPerformance.fromJson({
        'post_id': 42, 'views': 500, 'likes': 50, 'comments': 20,
        'shares': 10, 'saves': 5, 'engagement_rate': 8.0, 'avg_dwell_ms': 15000,
      });
      expect(p.postId, 42);
      expect(p.engagementRate, 8.0);
    });
  });

  group('AudienceInsight', () {
    test('fromJson parses audience data', () {
      final a = AudienceInsight.fromJson({
        'top_city': 'Dar es Salaam', 'top_age_range': '18-24',
        'male_percent': 55.0, 'female_percent': 45.0,
        'active_followers_count': 800, 'peak_activity_time': '8:00 PM',
      });
      expect(a.topCity, 'Dar es Salaam');
      expect(a.malePercent, 55.0);
    });
  });
}
