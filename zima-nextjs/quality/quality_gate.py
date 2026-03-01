"""
Zima Looper - Quality Gate
Enforces quality standards before story completion
"""

import os
import sys
from typing import Dict, Optional, List, Any
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from quality.test_executor import TestExecutor
from core.database import Database


class QualityGatePolicy:
    """Quality gate policy configuration"""

    def __init__(
        self,
        require_tests_pass: bool = True,
        require_syntax_valid: bool = True,
        require_composer_valid: bool = False,
        require_env_valid: bool = True,
        allow_no_tests: bool = True,
        min_test_coverage: Optional[float] = None
    ):
        """
        Initialize policy

        Args:
            require_tests_pass: Tests must pass (if tests exist)
            require_syntax_valid: Syntax must be valid
            require_composer_valid: composer.json must be valid
            require_env_valid: .env must exist and be valid
            allow_no_tests: Allow stories without tests
            min_test_coverage: Minimum test coverage percentage (not implemented yet)
        """
        self.require_tests_pass = require_tests_pass
        self.require_syntax_valid = require_syntax_valid
        self.require_composer_valid = require_composer_valid
        self.require_env_valid = require_env_valid
        self.allow_no_tests = allow_no_tests
        self.min_test_coverage = min_test_coverage


class QualityGate:
    """
    Quality gate that checks if story meets quality standards
    """

    def __init__(
        self,
        db: Database,
        project_dir: str,
        policy: Optional[QualityGatePolicy] = None,
        config: Optional[Any] = None
    ):
        """
        Initialize quality gate

        Args:
            db: Database instance
            project_dir: Project directory
            policy: Quality gate policy
            config: Optional Zima config (for run_linter / run_npm_build to save RAM)
        """
        self.db = db
        self.project_dir = project_dir
        self.policy = policy or QualityGatePolicy()
        self.config = config
        self.executor = TestExecutor(project_dir, config=config)

    def check_story_quality(
        self,
        story_id: int,
        run_tests: bool = True
    ) -> Dict:
        """
        Check if story meets quality standards

        Args:
            story_id: Story ID
            run_tests: Whether to run tests

        Returns:
            Dictionary with check results and gate status
        """
        result = {
            'passed': False,
            'story_id': story_id,
            'timestamp': datetime.now().isoformat(),
            'checks': {},
            'failures': [],
            'warnings': [],
            'can_complete': False,
            'message': ''
        }

        # Determine which checks to run based on policy
        checks_config = {
            'run_tests': run_tests and self.policy.require_tests_pass,
            'run_syntax': self.policy.require_syntax_valid,
            'check_composer': self.policy.require_composer_valid,
            'check_env': self.policy.require_env_valid
        }

        # Run all checks
        check_results = self.executor.run_all_checks(**checks_config)
        if check_results is None:
            check_results = {}
        result['checks'] = check_results

        # Evaluate each check against policy
        gate_passed = True

        # Next.js: lint and build
        if check_results.get('lint'):
            lint = check_results['lint']
            if not lint['success']:
                gate_passed = False
                result['failures'].append(f"Lint failed: {lint.get('error', 'See output')}")

        if check_results.get('build'):
            build = check_results['build']
            if not build['success']:
                gate_passed = False
                result['failures'].append(f"Build failed: {build.get('error', 'See output')}")

        # Laravel: tests, syntax, composer, env
        if checks_config['run_tests'] and check_results.get('tests'):
            tests = check_results['tests']

            if tests['error']:
                if tests['error'] == 'No tests directory found':
                    if not self.policy.allow_no_tests:
                        gate_passed = False
                        result['failures'].append('No tests found (required by policy)')
                    else:
                        result['warnings'].append('No tests found (allowed by policy)')
                else:
                    gate_passed = False
                    result['failures'].append(f'Test execution error: {tests["error"]}')

            elif not tests['success']:
                gate_passed = False
                result['failures'].append(
                    f'Tests failed: {tests["tests_failed"]}/{tests["tests_run"]} failed'
                )

                # Add specific test failures
                for failure in tests.get('failures', []):
                    result['failures'].append(f'  - {failure}')

        # Syntax check
        if checks_config['run_syntax'] and check_results.get('syntax'):
            syntax = check_results['syntax']

            if not syntax['success']:
                gate_passed = False
                result['failures'].append(
                    f'Syntax errors: {len(syntax["errors"])} files with errors'
                )

                # Add specific syntax errors (limit to 5)
                for error in syntax['errors'][:5]:
                    result['failures'].append(
                        f'  - {error["file"]}: {error["error"]}'
                    )

        # Composer validation
        if checks_config['check_composer'] and check_results.get('composer'):
            comp = check_results['composer']

            if not comp['success']:
                gate_passed = False
                result['failures'].append('composer.json validation failed')

        # Environment check
        if checks_config['check_env'] and check_results.get('env'):
            env = check_results['env']

            if not env['success']:
                gate_passed = False
                result['failures'].append(f'Environment check failed: {env.get("error", "Unknown")}')

        # Set final result
        result['passed'] = gate_passed
        result['can_complete'] = gate_passed

        # Generate message
        if gate_passed:
            result['message'] = '✅ Quality gate PASSED - Story can be completed'
        else:
            result['message'] = f'❌ Quality gate FAILED - {len(result["failures"])} issue(s)'

        # Save gate result to database
        self._save_gate_result(story_id, result)

        return result

    def _save_gate_result(self, story_id: int, result: Dict):
        """
        Save quality gate result to database

        Args:
            story_id: Story ID
            result: Gate result
        """
        import json

        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            # Save to executions table as 'quality_gate' execution
            cursor.execute('''
                INSERT INTO executions (
                    story_id,
                    execution_type,
                    command,
                    output,
                    exit_code,
                    duration_seconds,
                    created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                story_id,
                'quality_gate',
                'quality_gate_check',
                json.dumps(result, indent=2),
                0 if result['passed'] else 1,
                ((result.get('checks') or {}).get('tests') or {}).get('duration', 0),
                datetime.now().isoformat()
            ))

    def get_story_quality_history(self, story_id: int) -> List[Dict]:
        """
        Get quality gate history for a story

        Args:
            story_id: Story ID

        Returns:
            List of quality gate results
        """
        import json

        with self.db.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute('''
                SELECT output, created_at, exit_code
                FROM executions
                WHERE story_id = ? AND execution_type = 'quality_gate'
                ORDER BY created_at DESC
            ''', (story_id,))

            results = []
            for row in cursor.fetchall():
                try:
                    result = json.loads(row[0])
                    result['created_at'] = row[1]
                    result['exit_code'] = row[2]
                    results.append(result)
                except:
                    pass

            return results

    def get_project_quality_metrics(self, project_id: int) -> Dict:
        """
        Get quality metrics for entire project

        Args:
            project_id: Project ID

        Returns:
            Dictionary with quality metrics
        """
        stories = self.db.get_project_stories(project_id)

        metrics = {
            'total_stories': len(stories),
            'stories_with_tests': 0,
            'stories_passed_gate': 0,
            'stories_failed_gate': 0,
            'total_tests_run': 0,
            'total_tests_passed': 0,
            'total_tests_failed': 0,
            'gate_pass_rate': 0.0,
            'test_success_rate': 0.0
        }

        for story in stories:
            history = self.get_story_quality_history(story['id'])

            if history:
                # Get most recent gate result
                latest = history[0]

                if latest['passed']:
                    metrics['stories_passed_gate'] += 1
                else:
                    metrics['stories_failed_gate'] += 1

                # Count tests
                if latest.get('checks', {}).get('tests'):
                    tests = latest['checks']['tests']

                    if not tests.get('error'):
                        metrics['stories_with_tests'] += 1
                        metrics['total_tests_run'] += tests.get('tests_run', 0)
                        metrics['total_tests_passed'] += tests.get('tests_passed', 0)
                        metrics['total_tests_failed'] += tests.get('tests_failed', 0)

        # Calculate rates
        if metrics['stories_passed_gate'] + metrics['stories_failed_gate'] > 0:
            metrics['gate_pass_rate'] = (
                metrics['stories_passed_gate'] /
                (metrics['stories_passed_gate'] + metrics['stories_failed_gate'])
            ) * 100

        if metrics['total_tests_run'] > 0:
            metrics['test_success_rate'] = (
                metrics['total_tests_passed'] /
                metrics['total_tests_run']
            ) * 100

        return metrics

    def should_rollback_story(self, story_id: int, gate_result: Dict) -> bool:
        """
        Determine if story should be rolled back due to quality gate failure

        Args:
            story_id: Story ID
            gate_result: Quality gate result

        Returns:
            True if should rollback
        """
        # If gate passed, no rollback
        if gate_result['passed']:
            return False

        # If gate failed and policy is strict, rollback
        if not gate_result['can_complete']:
            return True

        return False

    def generate_quality_report(self, project_id: int) -> str:
        """
        Generate quality report for project

        Args:
            project_id: Project ID

        Returns:
            Formatted report string
        """
        metrics = self.get_project_quality_metrics(project_id)
        project = self.db.get_project(project_id)

        lines = []
        lines.append("=" * 60)
        lines.append("QUALITY REPORT")
        lines.append("=" * 60)
        lines.append(f"\nProject: {project['name']}")
        lines.append(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")

        lines.append("Quality Gate Metrics:")
        lines.append("-" * 60)
        lines.append(f"  Total Stories:        {metrics['total_stories']}")
        lines.append(f"  Passed Gate:          {metrics['stories_passed_gate']}")
        lines.append(f"  Failed Gate:          {metrics['stories_failed_gate']}")
        lines.append(f"  Gate Pass Rate:       {metrics['gate_pass_rate']:.1f}%")

        lines.append("\nTest Metrics:")
        lines.append("-" * 60)
        lines.append(f"  Stories with Tests:   {metrics['stories_with_tests']}")
        lines.append(f"  Total Tests Run:      {metrics['total_tests_run']}")
        lines.append(f"  Tests Passed:         {metrics['total_tests_passed']}")
        lines.append(f"  Tests Failed:         {metrics['total_tests_failed']}")
        lines.append(f"  Test Success Rate:    {metrics['test_success_rate']:.1f}%")

        lines.append("\n" + "=" * 60 + "\n")

        return "\n".join(lines)


def main():
    """Test quality gate"""
    from core.database import get_db

    db = get_db()

    # Get first project
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM projects LIMIT 1')
        row = cursor.fetchone()

        if not row:
            print("No projects found")
            return

        columns = [desc[0] for desc in cursor.description]
        project = dict(zip(columns, row))

    print(f"\nTesting Quality Gate for: {project['name']}\n")

    gate = QualityGate(db, project['directory'])

    # Generate quality report
    report = gate.generate_quality_report(project['id'])
    print(report)


if __name__ == '__main__':
    main()
