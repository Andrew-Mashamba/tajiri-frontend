"""
Zima Looper - Test Executor
Runs tests and validates code quality before story completion
"""

import os
import sys
import subprocess
import re
from typing import Dict, List, Optional, Tuple, Any
from datetime import datetime
from enum import Enum

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


class TestResult(Enum):
    """Test execution results"""
    PASSED = "passed"
    FAILED = "failed"
    ERROR = "error"
    SKIPPED = "skipped"


class TestExecutor:
    """
    Executes tests and quality checks.
    For Next.js: npm run lint, npm run build (Laravel checks disabled).
    Config.run_linter=False and run_npm_build=False skip these to save RAM.
    """

    def __init__(self, project_dir: str, config: Optional[Any] = None):
        """
        Initialize test executor

        Args:
            project_dir: Project directory path
            config: Optional Zima config (run_linter, run_npm_build) to skip lint/build and save RAM
        """
        self.project_dir = project_dir
        self.config = config

    def _is_flutter_project(self) -> bool:
        """Check if project has pubspec.yaml (Flutter)"""
        pubspec = os.path.join(self.project_dir, "pubspec.yaml")
        return os.path.exists(pubspec)

    def _is_nextjs_project(self) -> bool:
        """Check if project has frontend/package.json (Next.js)"""
        pkg = os.path.join(self.project_dir, "frontend", "package.json")
        return os.path.exists(pkg)

    def _get_frontend_dir(self) -> str:
        """Return frontend directory (frontend/ or project_dir for monorepos)"""
        frontend = os.path.join(self.project_dir, "frontend")
        if os.path.exists(frontend):
            return frontend
        return self.project_dir

    def run_npm_lint(self, timeout: int = 120) -> Dict:
        """
        Run npm run lint in frontend/

        Returns:
            Dictionary with lint results
        """
        result = {
            "success": True,
            "output": "",
            "error": None,
            "duration": 0,
        }
        frontend = self._get_frontend_dir()
        pkg = os.path.join(frontend, "package.json")
        if not os.path.exists(pkg):
            result["error"] = "frontend/package.json not found"
            result["success"] = False
            return result

        start = datetime.now()
        try:
            proc = subprocess.run(
                ["npm", "run", "lint"],
                cwd=frontend,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            result["output"] = (proc.stdout or "") + (proc.stderr or "")
            result["duration"] = (datetime.now() - start).total_seconds()
            result["success"] = proc.returncode == 0
            if proc.returncode != 0:
                result["error"] = f"Lint failed (exit {proc.returncode})"
        except subprocess.TimeoutExpired:
            result["error"] = f"Lint timed out after {timeout}s"
            result["success"] = False
        except Exception as e:
            result["error"] = str(e)
            result["success"] = False
        return result

    def run_flutter_analyze(self, timeout: int = 180) -> Dict:
        """
        Run flutter analyze (Dart static analysis).

        Returns:
            Dictionary with analysis results
        """
        result = {
            "success": True,
            "output": "",
            "error": None,
            "duration": 0,
        }
        if not self._is_flutter_project():
            result["error"] = "pubspec.yaml not found (not a Flutter project)"
            result["success"] = False
            return result

        start = datetime.now()
        try:
            proc = subprocess.run(
                ["flutter", "analyze"],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            result["output"] = (proc.stdout or "") + (proc.stderr or "")
            result["duration"] = (datetime.now() - start).total_seconds()
            result["success"] = proc.returncode == 0
            if proc.returncode != 0:
                result["error"] = f"Flutter analyze failed (exit {proc.returncode})"
        except subprocess.TimeoutExpired:
            result["error"] = f"Flutter analyze timed out after {timeout}s"
            result["success"] = False
        except FileNotFoundError:
            result["error"] = "flutter command not found"
            result["success"] = False
        except Exception as e:
            result["error"] = str(e)
            result["success"] = False
        return result

    def run_flutter_build(self, target: str = "apk", timeout: int = 600) -> Dict:
        """
        Run flutter build (apk, ios, web, etc.).

        Args:
            target: apk, ios, web, or macos
            timeout: Timeout in seconds (default 600 for build)

        Returns:
            Dictionary with build results
        """
        result = {
            "success": True,
            "output": "",
            "error": None,
            "duration": 0,
        }
        if not self._is_flutter_project():
            result["error"] = "pubspec.yaml not found (not a Flutter project)"
            result["success"] = False
            return result

        start = datetime.now()
        try:
            proc = subprocess.run(
                ["flutter", "build", target],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            result["output"] = (proc.stdout or "") + (proc.stderr or "")
            result["duration"] = (datetime.now() - start).total_seconds()
            result["success"] = proc.returncode == 0
            if proc.returncode != 0:
                result["error"] = f"Flutter build {target} failed (exit {proc.returncode})"
        except subprocess.TimeoutExpired:
            result["error"] = f"Flutter build timed out after {timeout}s"
            result["success"] = False
        except FileNotFoundError:
            result["error"] = "flutter command not found"
            result["success"] = False
        except Exception as e:
            result["error"] = str(e)
            result["success"] = False
        return result

    def run_npm_build(self, timeout: int = 300) -> Dict:
        """
        Run npm run build in frontend/

        Returns:
            Dictionary with build results
        """
        result = {
            "success": True,
            "output": "",
            "error": None,
            "duration": 0,
        }
        frontend = self._get_frontend_dir()
        pkg = os.path.join(frontend, "package.json")
        if not os.path.exists(pkg):
            result["error"] = "frontend/package.json not found"
            result["success"] = False
            return result

        start = datetime.now()
        try:
            proc = subprocess.run(
                ["npm", "run", "build"],
                cwd=frontend,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            result["output"] = (proc.stdout or "") + (proc.stderr or "")
            result["duration"] = (datetime.now() - start).total_seconds()
            result["success"] = proc.returncode == 0
            if proc.returncode != 0:
                result["error"] = f"Build failed (exit {proc.returncode})"
        except subprocess.TimeoutExpired:
            result["error"] = f"Build timed out after {timeout}s"
            result["success"] = False
        except Exception as e:
            result["error"] = str(e)
            result["success"] = False
        return result

    def run_laravel_tests(
        self,
        timeout: int = 300
    ) -> Dict:
        """
        Run Laravel PHPUnit tests

        Args:
            timeout: Timeout in seconds

        Returns:
            Dictionary with test results
        """
        result = {
            'success': False,
            'tests_run': 0,
            'tests_passed': 0,
            'tests_failed': 0,
            'tests_skipped': 0,
            'failures': [],
            'duration': 0,
            'output': '',
            'error': None
        }

        # Check if project has tests
        artisan_path = os.path.join(self.project_dir, 'artisan')
        if not os.path.exists(artisan_path):
            result['error'] = 'Not a Laravel project (artisan not found)'
            return result

        tests_path = os.path.join(self.project_dir, 'tests')
        if not os.path.exists(tests_path):
            result['error'] = 'No tests directory found'
            result['success'] = True  # No tests = pass
            return result

        # Run PHPUnit tests
        start_time = datetime.now()

        try:
            cmd = ['php', 'artisan', 'test', '--no-interaction']

            process = subprocess.run(
                cmd,
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=timeout
            )

            result['output'] = process.stdout + process.stderr
            result['duration'] = (datetime.now() - start_time).total_seconds()

            # Parse test output
            parsed = self._parse_phpunit_output(result['output'])
            result.update(parsed)

            # Success if exit code 0 or all tests passed
            result['success'] = (process.returncode == 0) or (
                result['tests_run'] > 0 and result['tests_failed'] == 0
            )

        except subprocess.TimeoutExpired:
            result['error'] = f'Tests timed out after {timeout}s'
            result['duration'] = timeout

        except Exception as e:
            result['error'] = f'Test execution failed: {str(e)}'

        return result

    def _parse_phpunit_output(self, output: str) -> Dict:
        """
        Parse PHPUnit test output

        Args:
            output: Test output string

        Returns:
            Parsed test results
        """
        parsed = {
            'tests_run': 0,
            'tests_passed': 0,
            'tests_failed': 0,
            'tests_skipped': 0,
            'failures': []
        }

        # Match: "Tests:  5 passed, 20 assertions"
        # Match: "Tests:  3 failed, 10 passed, 13 total"
        tests_pattern = r'Tests:\s+(?:(\d+)\s+failed[,\s]+)?(?:(\d+)\s+passed)?'
        match = re.search(tests_pattern, output, re.IGNORECASE)

        if match:
            failed = int(match.group(1)) if match.group(1) else 0
            passed = int(match.group(2)) if match.group(2) else 0

            parsed['tests_failed'] = failed
            parsed['tests_passed'] = passed
            parsed['tests_run'] = failed + passed

        # Alternative pattern: "OK (13 tests, 45 assertions)"
        ok_pattern = r'OK\s+\((\d+)\s+tests?,\s+\d+\s+assertions?\)'
        ok_match = re.search(ok_pattern, output)

        if ok_match:
            parsed['tests_run'] = int(ok_match.group(1))
            parsed['tests_passed'] = parsed['tests_run']
            parsed['tests_failed'] = 0

        # Alternative pattern: "FAILURES! Tests: 5, Assertions: 10, Failures: 2"
        failure_pattern = r'FAILURES!\s+Tests:\s+(\d+),.*?Failures:\s+(\d+)'
        failure_match = re.search(failure_pattern, output)

        if failure_match:
            total = int(failure_match.group(1))
            failed = int(failure_match.group(2))

            parsed['tests_run'] = total
            parsed['tests_failed'] = failed
            parsed['tests_passed'] = total - failed

        # Extract failure details
        # Match: "FAILED  Tests\Unit\ExampleTest::test_example"
        failure_lines = re.findall(
            r'(?:FAILED|FAIL)\s+(.+?)(?:\n|$)',
            output,
            re.MULTILINE
        )

        parsed['failures'] = [line.strip() for line in failure_lines]

        return parsed

    def run_syntax_check(self) -> Dict:
        """
        Run PHP syntax check on all PHP files

        Returns:
            Dictionary with syntax check results
        """
        result = {
            'success': True,
            'files_checked': 0,
            'errors': [],
            'output': ''
        }

        # Find all PHP files
        php_files = []
        for root, dirs, files in os.walk(self.project_dir):
            # Skip vendor and node_modules
            if 'vendor' in root or 'node_modules' in root:
                continue

            for file in files:
                if file.endswith('.php'):
                    php_files.append(os.path.join(root, file))

        result['files_checked'] = len(php_files)

        # Check each file
        for php_file in php_files:
            try:
                process = subprocess.run(
                    ['php', '-l', php_file],
                    capture_output=True,
                    text=True,
                    timeout=5
                )

                if process.returncode != 0:
                    result['success'] = False
                    result['errors'].append({
                        'file': php_file,
                        'error': process.stderr.strip()
                    })

            except Exception as e:
                result['success'] = False
                result['errors'].append({
                    'file': php_file,
                    'error': str(e)
                })

        return result

    def check_composer_validate(self) -> Dict:
        """
        Validate composer.json

        Returns:
            Dictionary with validation results
        """
        result = {
            'success': True,
            'output': '',
            'error': None
        }

        composer_path = os.path.join(self.project_dir, 'composer.json')
        if not os.path.exists(composer_path):
            result['error'] = 'composer.json not found'
            return result

        try:
            process = subprocess.run(
                ['composer', 'validate', '--no-check-publish'],
                cwd=self.project_dir,
                capture_output=True,
                text=True,
                timeout=30
            )

            result['output'] = process.stdout + process.stderr
            result['success'] = process.returncode == 0

            if not result['success']:
                result['error'] = 'composer.json validation failed'

        except Exception as e:
            result['error'] = str(e)
            result['success'] = False

        return result

    def check_env_file(self) -> Dict:
        """
        Check if .env file exists and is valid

        Returns:
            Dictionary with check results
        """
        result = {
            'success': True,
            'exists': False,
            'has_app_key': False,
            'has_database': False,
            'error': None
        }

        env_path = os.path.join(self.project_dir, '.env')
        result['exists'] = os.path.exists(env_path)

        if not result['exists']:
            result['error'] = '.env file not found'
            result['success'] = False
            return result

        try:
            with open(env_path, 'r') as f:
                content = f.read()

            # Check for APP_KEY
            result['has_app_key'] = bool(re.search(r'APP_KEY=.+', content))

            # Check for database config
            result['has_database'] = bool(
                re.search(r'DB_CONNECTION=', content) or
                re.search(r'DATABASE_URL=', content)
            )

            if not result['has_app_key']:
                result['error'] = 'APP_KEY not set in .env'
                result['success'] = False

        except Exception as e:
            result['error'] = str(e)
            result['success'] = False

        return result

    def run_all_checks(
        self,
        run_tests: bool = True,
        run_syntax: bool = True,
        check_composer: bool = True,
        check_env: bool = True
    ) -> Dict:
        """
        Run all quality checks.
        For Next.js projects: npm run lint + npm run build (Laravel checks skipped).
        For Laravel: PHPUnit, php -l, composer, .env.
        """
        results = {
            'success': True,
            'checks_run': 0,
            'checks_passed': 0,
            'checks_failed': 0,
            'tests': None,
            'syntax': None,
            'composer': None,
            'env': None,
            'lint': None,
            'build': None,
            'summary': ''
        }

        if self._is_flutter_project():
            # Flutter: analyze + build; config controls run_flutter_analyze / run_flutter_build
            run_analyze = (run_tests or run_syntax) and getattr(self.config, 'run_flutter_analyze', True) if self.config else (run_tests or run_syntax)
            run_build = getattr(self.config, 'run_flutter_build', True) if self.config else True
            flutter_build_target = getattr(self.config, 'flutter_build_target', 'apk') if self.config else 'apk'

            if run_analyze:
                results['checks_run'] += 1
                results['lint'] = self.run_flutter_analyze()
                if results['lint']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False
            else:
                results['lint'] = {'success': True, 'skipped': True, 'reason': 'run_flutter_analyze=false'}

            if run_build:
                results['checks_run'] += 1
                results['build'] = self.run_flutter_build(target=flutter_build_target)
                if results['build']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False
            else:
                results['build'] = {'success': True, 'skipped': True, 'reason': 'run_flutter_build=false'}

            results['composer'] = {'success': True}
            results['env'] = {'success': True}
        elif self._is_nextjs_project():
            # Next.js: lint + build; skip either to save RAM (config.run_linter / run_npm_build)
            run_lint = (run_tests or run_syntax) and getattr(self.config, 'run_linter', True) if self.config else (run_tests or run_syntax)
            run_build = getattr(self.config, 'run_npm_build', True) if self.config else True

            if run_lint:
                results['checks_run'] += 1
                results['lint'] = self.run_npm_lint()
                if results['lint']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False
            else:
                results['lint'] = {'success': True, 'skipped': True, 'reason': 'run_linter=false (save RAM)'}

            if run_build:
                results['checks_run'] += 1
                results['build'] = self.run_npm_build()
                if results['build']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False
            else:
                results['build'] = {'success': True, 'skipped': True, 'reason': 'run_npm_build=false (save RAM)'}

            # Composer/env not used for Next.js
            results['composer'] = {'success': True}
            results['env'] = {'success': True}
        else:
            # Laravel: original checks (kept for compatibility)
            if run_tests:
                results['checks_run'] += 1
                results['tests'] = self.run_laravel_tests()
                if results['tests']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False

            if run_syntax:
                results['checks_run'] += 1
                results['syntax'] = self.run_syntax_check()
                if results['syntax']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False

            if check_composer:
                results['checks_run'] += 1
                results['composer'] = self.check_composer_validate()
                if results['composer']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False

            if check_env:
                results['checks_run'] += 1
                results['env'] = self.check_env_file()
                if results['env']['success']:
                    results['checks_passed'] += 1
                else:
                    results['checks_failed'] += 1
                    results['success'] = False

        # Generate summary
        results['summary'] = self._generate_summary(results)

        return results

    def _generate_summary(self, results: Dict) -> str:
        """
        Generate human-readable summary

        Args:
            results: Check results

        Returns:
            Summary string
        """
        lines = []
        lines.append("Quality Gate Results:")
        lines.append(f"  Checks Run: {results['checks_run']}")
        lines.append(f"  Passed: {results['checks_passed']}")
        lines.append(f"  Failed: {results['checks_failed']}")

        if results.get('lint'):
            lint = results['lint']
            status = "✅" if lint['success'] else "❌"
            lines.append(f"  {status} Lint: {'OK' if lint['success'] else lint.get('error', 'Failed')}")

        if results.get('build'):
            build = results['build']
            status = "✅" if build['success'] else "❌"
            lines.append(f"  {status} Build: {'OK' if build['success'] else build.get('error', 'Failed')}")

        if results.get('tests'):
            tests = results['tests']
            if tests['success']:
                lines.append(f"  ✅ Tests: {tests['tests_passed']}/{tests['tests_run']} passed")
            else:
                lines.append(f"  ❌ Tests: {tests['tests_failed']}/{tests['tests_run']} failed")

        if results.get('syntax'):
            syntax = results['syntax']
            if syntax['success']:
                lines.append(f"  ✅ Syntax: {syntax['files_checked']} files OK")
            else:
                lines.append(f"  ❌ Syntax: {len(syntax['errors'])} errors")

        if results.get('composer'):
            comp = results['composer']
            status = "✅" if comp['success'] else "❌"
            lines.append(f"  {status} Composer: {'Valid' if comp['success'] else 'Invalid'}")

        if results.get('env'):
            env = results['env']
            status = "✅" if env['success'] else "❌"
            lines.append(f"  {status} Environment: {'OK' if env['success'] else env.get('error', 'Failed')}")

        return "\n".join(lines)


def main():
    """Test the test executor"""
    import sys

    if len(sys.argv) < 2:
        print("Usage: python test_executor.py <project_dir>")
        sys.exit(1)

    project_dir = sys.argv[1]

    if not os.path.exists(project_dir):
        print(f"Error: Directory not found: {project_dir}")
        sys.exit(1)

    executor = TestExecutor(project_dir)

    print(f"\n{'='*60}")
    print(f"Running Quality Checks: {project_dir}")
    print(f"{'='*60}\n")

    results = executor.run_all_checks()

    print(results['summary'])
    print(f"\n{'='*60}")
    print(f"Overall: {'✅ PASSED' if results['success'] else '❌ FAILED'}")
    print(f"{'='*60}\n")

    sys.exit(0 if results['success'] else 1)


if __name__ == '__main__':
    main()
