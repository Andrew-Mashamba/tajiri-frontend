"""
Zima Looper - Metrics Collection
Tracks and records performance metrics
"""

import os
import sys
from datetime import datetime
from typing import Dict, List, Optional

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.database import Database


class MetricsCollector:
    """
    Collects and stores performance metrics
    """

    def __init__(self, db: Database):
        """
        Initialize metrics collector

        Args:
            db: Database instance
        """
        self.db = db

    def record_metric(
        self,
        project_id: int,
        metric_name: str,
        metric_value: float,
        timestamp: Optional[datetime] = None
    ):
        """
        Record a metric value

        Args:
            project_id: Project ID
            metric_name: Name of metric
            metric_value: Value to record
            timestamp: Optional timestamp (defaults to now)
        """
        if timestamp is None:
            timestamp = datetime.now()

        with self.db.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO metrics (project_id, metric_name, metric_value, timestamp)
                VALUES (?, ?, ?, ?)
            ''', (project_id, metric_name, metric_value, timestamp.isoformat()))

    def calculate_stories_per_hour(self, project_id: int) -> Optional[float]:
        """
        Calculate stories completed per hour

        Args:
            project_id: Project ID

        Returns:
            Stories per hour or None
        """
        project = self.db.get_project(project_id)

        if not project or not project.get('started_at'):
            return None

        started_at = datetime.fromisoformat(project['started_at'])
        elapsed_hours = (datetime.now() - started_at).total_seconds() / 3600

        if elapsed_hours < 0.1:  # Less than 6 minutes
            return None

        completed = project.get('completed_stories', 0)
        rate = completed / elapsed_hours

        # Record metric
        self.record_metric(project_id, 'stories_per_hour', rate)

        return rate

    def calculate_avg_retry_count(self, project_id: int) -> Optional[float]:
        """
        Calculate average retry count for completed stories

        Args:
            project_id: Project ID

        Returns:
            Average retry count or None
        """
        stories = self.db.get_project_stories(project_id)
        completed_stories = [s for s in stories if s['status'] == 'completed']

        if not completed_stories:
            return None

        total_retries = sum(s.get('retry_count', 0) for s in completed_stories)
        avg_retries = total_retries / len(completed_stories)

        # Record metric
        self.record_metric(project_id, 'avg_retry_count', avg_retries)

        return avg_retries

    def calculate_success_rate(self, project_id: int) -> Optional[float]:
        """
        Calculate success rate (completed / total attempted)

        Args:
            project_id: Project ID

        Returns:
            Success rate percentage or None
        """
        stories = self.db.get_project_stories(project_id)

        if not stories:
            return None

        # Count stories that have been attempted
        attempted_stories = [
            s for s in stories
            if s['status'] in ['completed', 'failed']
        ]

        if not attempted_stories:
            return None

        completed_count = sum(1 for s in attempted_stories if s['status'] == 'completed')
        success_rate = (completed_count / len(attempted_stories)) * 100

        # Record metric
        self.record_metric(project_id, 'success_rate', success_rate)

        return success_rate

    def calculate_api_cost_estimate(self, project_id: int) -> Optional[float]:
        """
        Estimate API cost based on execution count

        Args:
            project_id: Project ID

        Returns:
            Estimated cost in USD or None
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            # Count Claude CLI calls
            cursor.execute('''
                SELECT COUNT(*) as call_count
                FROM executions
                WHERE story_id IN (
                    SELECT id FROM stories WHERE project_id = ?
                )
                AND execution_type = 'claude_call'
            ''', (project_id,))

            result = cursor.fetchone()
            call_count = result[0] if result else 0

        if call_count == 0:
            return None

        # Rough estimate: $0.50 per call (assuming Sonnet model)
        # This is a very rough estimate and should be calibrated
        cost_per_call = 0.50
        estimated_cost = call_count * cost_per_call

        # Record metric
        self.record_metric(project_id, 'api_cost_estimate', estimated_cost)

        return estimated_cost

    def calculate_time_per_story(self, project_id: int) -> Optional[float]:
        """
        Calculate average time per story in minutes

        Args:
            project_id: Project ID

        Returns:
            Average minutes per story or None
        """
        project = self.db.get_project(project_id)

        if not project or not project.get('started_at'):
            return None

        started_at = datetime.fromisoformat(project['started_at'])
        elapsed_minutes = (datetime.now() - started_at).total_seconds() / 60

        completed = project.get('completed_stories', 0)

        if completed == 0:
            return None

        time_per_story = elapsed_minutes / completed

        # Record metric
        self.record_metric(project_id, 'time_per_story_minutes', time_per_story)

        return time_per_story

    def calculate_worker_efficiency(self, project_id: int) -> Dict[int, float]:
        """
        Calculate efficiency per worker (stories/hour)

        Args:
            project_id: Project ID

        Returns:
            Dictionary mapping worker_id to stories/hour
        """
        stories = self.db.get_project_stories(project_id)
        completed_stories = [s for s in stories if s['status'] == 'completed']

        worker_stats = {}

        for story in completed_stories:
            worker_id = story.get('worker_id')

            if not worker_id or not story.get('started_at') or not story.get('completed_at'):
                continue

            if worker_id not in worker_stats:
                worker_stats[worker_id] = {
                    'count': 0,
                    'total_hours': 0
                }

            started = datetime.fromisoformat(story['started_at'])
            completed = datetime.fromisoformat(story['completed_at'])
            hours = (completed - started).total_seconds() / 3600

            worker_stats[worker_id]['count'] += 1
            worker_stats[worker_id]['total_hours'] += hours

        # Calculate efficiency
        efficiency = {}
        for worker_id, stats in worker_stats.items():
            if stats['total_hours'] > 0:
                efficiency[worker_id] = stats['count'] / stats['total_hours']

                # Record metric
                self.record_metric(
                    project_id,
                    f'worker_{worker_id}_efficiency',
                    efficiency[worker_id]
                )

        return efficiency

    def calculate_quality_metrics(self, project_id: int) -> Optional[Dict]:
        """
        Calculate quality gate metrics

        Args:
            project_id: Project ID

        Returns:
            Dictionary with quality metrics or None
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            # Get all quality gate executions
            cursor.execute('''
                SELECT output, exit_code
                FROM executions
                WHERE story_id IN (SELECT id FROM stories WHERE project_id = ?)
                AND execution_type = 'quality_gate'
            ''', (project_id,))

            results = cursor.fetchall()

        if not results:
            return None

        import json

        gate_passed = 0
        gate_failed = 0
        total_tests = 0
        tests_passed = 0
        tests_failed = 0

        for row in results:
            try:
                data = json.loads(row[0])
                exit_code = row[1]

                if exit_code == 0 or data.get('passed'):
                    gate_passed += 1
                else:
                    gate_failed += 1

                # Count tests
                if data.get('checks', {}).get('tests'):
                    tests = data['checks']['tests']
                    if not tests.get('error'):
                        total_tests += tests.get('tests_run', 0)
                        tests_passed += tests.get('tests_passed', 0)
                        tests_failed += tests.get('tests_failed', 0)

            except:
                pass

        gate_pass_rate = (gate_passed / (gate_passed + gate_failed) * 100) if (gate_passed + gate_failed) > 0 else 0
        test_pass_rate = (tests_passed / total_tests * 100) if total_tests > 0 else 0

        quality_metrics = {
            'gate_passed': gate_passed,
            'gate_failed': gate_failed,
            'gate_pass_rate': gate_pass_rate,
            'total_tests': total_tests,
            'tests_passed': tests_passed,
            'tests_failed': tests_failed,
            'test_pass_rate': test_pass_rate
        }

        # Record metrics
        self.record_metric(project_id, 'gate_pass_rate', gate_pass_rate)
        self.record_metric(project_id, 'test_pass_rate', test_pass_rate)

        return quality_metrics

    def collect_all_metrics(self, project_id: int) -> Dict:
        """
        Collect all metrics for a project

        Args:
            project_id: Project ID

        Returns:
            Dictionary of all metrics
        """
        return {
            'stories_per_hour': self.calculate_stories_per_hour(project_id),
            'avg_retry_count': self.calculate_avg_retry_count(project_id),
            'success_rate': self.calculate_success_rate(project_id),
            'api_cost_estimate': self.calculate_api_cost_estimate(project_id),
            'time_per_story': self.calculate_time_per_story(project_id),
            'worker_efficiency': self.calculate_worker_efficiency(project_id),
            'quality_metrics': self.calculate_quality_metrics(project_id),
            'timestamp': datetime.now().isoformat()
        }

    def get_metric_history(
        self,
        project_id: int,
        metric_name: str,
        limit: int = 100
    ) -> List[Dict]:
        """
        Get historical values for a metric

        Args:
            project_id: Project ID
            metric_name: Metric name
            limit: Max number of records

        Returns:
            List of metric records
        """
        with self.db.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT metric_value, timestamp
                FROM metrics
                WHERE project_id = ? AND metric_name = ?
                ORDER BY timestamp DESC
                LIMIT ?
            ''', (project_id, metric_name, limit))

            results = []
            for row in cursor.fetchall():
                results.append({
                    'value': row[0],
                    'timestamp': row[1]
                })

            return results

    def generate_report(self, project_id: int) -> str:
        """
        Generate text report of all metrics

        Args:
            project_id: Project ID

        Returns:
            Formatted report string
        """
        metrics = self.collect_all_metrics(project_id)
        project = self.db.get_project(project_id)

        report = []
        report.append("=" * 60)
        report.append("METRICS REPORT")
        report.append("=" * 60)
        report.append(f"\nProject: {project['name']}")
        report.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

        report.append("Performance Metrics:")
        report.append("-" * 60)

        if metrics['stories_per_hour']:
            report.append(f"  Stories/Hour:     {metrics['stories_per_hour']:.2f}")

        if metrics['time_per_story']:
            report.append(f"  Time/Story:       {metrics['time_per_story']:.1f} minutes")

        if metrics['success_rate']:
            report.append(f"  Success Rate:     {metrics['success_rate']:.1f}%")

        if metrics['avg_retry_count'] is not None:
            report.append(f"  Avg Retry Count:  {metrics['avg_retry_count']:.2f}")

        if metrics['api_cost_estimate']:
            report.append(f"  Est. API Cost:    ${metrics['api_cost_estimate']:.2f}")

        if metrics['worker_efficiency']:
            report.append("\nWorker Efficiency (stories/hour):")
            for worker_id, efficiency in metrics['worker_efficiency'].items():
                report.append(f"  Worker #{worker_id}:      {efficiency:.2f}")

        if metrics['quality_metrics']:
            quality = metrics['quality_metrics']
            report.append("\nQuality Metrics:")
            report.append("-" * 60)
            report.append(f"  Gate Pass Rate:   {quality['gate_pass_rate']:.1f}%")
            report.append(f"  Tests Passed:     {quality['tests_passed']}/{quality['total_tests']}")
            report.append(f"  Test Pass Rate:   {quality['test_pass_rate']:.1f}%")

        report.append("\n" + "=" * 60 + "\n")

        return "\n".join(report)


def main():
    """Test metrics collector"""
    from core.database import get_db

    db = get_db()
    collector = MetricsCollector(db)

    # Get all projects
    projects = []
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM projects')
        columns = [desc[0] for desc in cursor.description]
        for row in cursor.fetchall():
            projects.append(dict(zip(columns, row)))

    if not projects:
        print("No projects found")
        return

    # Generate report for first project
    project = projects[0]
    print(f"\nGenerating metrics report for: {project['name']}\n")

    report = collector.generate_report(project['id'])
    print(report)


if __name__ == '__main__':
    main()
