"""
Zima Looper - Project Analyzer
Analyzes existing codebase to determine what's already implemented
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict


@dataclass
class ProjectInventory:
    """
    Inventory of existing project implementation
    """
    has_existing_code: bool
    project_path: str

    # Laravel structure
    routes: List[str]  # Route files found
    controllers: List[str]  # Controller files
    models: List[str]  # Model files
    migrations: List[str]  # Migration files
    views: List[str]  # View files
    tests: List[str]  # Test files

    # Configuration
    composer_dependencies: List[str]  # Installed packages
    env_configured: bool  # .env file exists

    # Database
    database_exists: bool  # SQLite/MySQL database file exists

    # Summary
    total_files: int
    estimated_completion: int  # Rough percentage (0-100)

    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return asdict(self)

    def to_json(self) -> str:
        """Convert to JSON string"""
        return json.dumps(self.to_dict(), indent=2)


class ProjectAnalyzer:
    """
    Analyzes existing project to determine what's implemented
    """

    def __init__(self, project_dir: str):
        """
        Initialize project analyzer

        Args:
            project_dir: Path to project directory
        """
        self.project_dir = Path(project_dir)

        if not self.project_dir.exists():
            raise ValueError(f"Project directory not found: {project_dir}")

    def analyze(self) -> ProjectInventory:
        """
        Analyze project and return inventory

        Returns:
            ProjectInventory with existing implementation details
        """
        # Check if this is a Laravel project with existing code
        has_existing_code = self._has_existing_implementation()

        if not has_existing_code:
            return ProjectInventory(
                has_existing_code=False,
                project_path=str(self.project_dir),
                routes=[],
                controllers=[],
                models=[],
                migrations=[],
                views=[],
                tests=[],
                composer_dependencies=[],
                env_configured=False,
                database_exists=False,
                total_files=0,
                estimated_completion=0
            )

        # Scan existing implementation
        routes = self._find_routes()
        controllers = self._find_controllers()
        models = self._find_models()
        migrations = self._find_migrations()
        views = self._find_views()
        tests = self._find_tests()
        composer_deps = self._get_composer_dependencies()
        env_configured = self._check_env_configured()
        database_exists = self._check_database_exists()

        total_files = (
            len(routes) + len(controllers) + len(models) +
            len(migrations) + len(views) + len(tests)
        )

        # Rough completion estimate
        estimated_completion = self._estimate_completion(
            routes, controllers, models, migrations, views, tests
        )

        return ProjectInventory(
            has_existing_code=True,
            project_path=str(self.project_dir),
            routes=routes,
            controllers=controllers,
            models=models,
            migrations=migrations,
            views=views,
            tests=tests,
            composer_dependencies=composer_deps,
            env_configured=env_configured,
            database_exists=database_exists,
            total_files=total_files,
            estimated_completion=estimated_completion
        )

    def _has_existing_implementation(self) -> bool:
        """
        Check if project has existing Laravel implementation

        Returns:
            True if project has code beyond initial setup
        """
        # Check for Laravel structure
        app_dir = self.project_dir / "app"
        if not app_dir.exists():
            return False

        # Check for custom controllers (beyond default Laravel)
        controllers = list((app_dir / "Http" / "Controllers").glob("*.php")) if (app_dir / "Http" / "Controllers").exists() else []

        # Exclude default Laravel controllers
        default_controllers = {"Controller.php"}
        custom_controllers = [c for c in controllers if c.name not in default_controllers]

        # Check for models (beyond User.php)
        models = list((app_dir / "Models").glob("*.php")) if (app_dir / "Models").exists() else []
        default_models = {"User.php"}
        custom_models = [m for m in models if m.name not in default_models]

        # Check for migrations (beyond default Laravel migrations)
        database_dir = self.project_dir / "database" / "migrations"
        migrations = list(database_dir.glob("*.php")) if database_dir.exists() else []

        # Consider it existing implementation if:
        # - Has custom controllers OR
        # - Has custom models OR
        # - Has 3+ migrations (beyond default user tables)
        return len(custom_controllers) > 0 or len(custom_models) > 0 or len(migrations) >= 3

    def _find_routes(self) -> List[str]:
        """Find route files and extract route definitions"""
        routes_dir = self.project_dir / "routes"
        if not routes_dir.exists():
            return []

        route_files = []
        for route_file in routes_dir.glob("*.php"):
            route_files.append(str(route_file.relative_to(self.project_dir)))

        return route_files

    def _find_controllers(self) -> List[str]:
        """Find controller files"""
        controllers_dir = self.project_dir / "app" / "Http" / "Controllers"
        if not controllers_dir.exists():
            return []

        controllers = []
        for controller_file in controllers_dir.glob("*.php"):
            # Skip base Controller
            if controller_file.name != "Controller.php":
                controllers.append(str(controller_file.relative_to(self.project_dir)))

        return controllers

    def _find_models(self) -> List[str]:
        """Find model files"""
        models_dir = self.project_dir / "app" / "Models"
        if not models_dir.exists():
            return []

        models = []
        for model_file in models_dir.glob("*.php"):
            models.append(str(model_file.relative_to(self.project_dir)))

        return models

    def _find_migrations(self) -> List[str]:
        """Find migration files"""
        migrations_dir = self.project_dir / "database" / "migrations"
        if not migrations_dir.exists():
            return []

        migrations = []
        for migration_file in sorted(migrations_dir.glob("*.php")):
            migrations.append(str(migration_file.relative_to(self.project_dir)))

        return migrations

    def _find_views(self) -> List[str]:
        """Find view files"""
        views_dir = self.project_dir / "resources" / "views"
        if not views_dir.exists():
            return []

        views = []
        for view_file in views_dir.rglob("*.blade.php"):
            views.append(str(view_file.relative_to(self.project_dir)))

        return views

    def _find_tests(self) -> List[str]:
        """Find test files"""
        tests_dir = self.project_dir / "tests"
        if not tests_dir.exists():
            return []

        tests = []
        for test_file in tests_dir.rglob("*Test.php"):
            tests.append(str(test_file.relative_to(self.project_dir)))

        return tests

    def _get_composer_dependencies(self) -> List[str]:
        """Get installed Composer dependencies"""
        composer_file = self.project_dir / "composer.json"
        if not composer_file.exists():
            return []

        try:
            with open(composer_file, 'r') as f:
                composer_data = json.load(f)

            dependencies = []

            # Get require dependencies
            if 'require' in composer_data:
                for package, version in composer_data['require'].items():
                    if package != 'php':  # Skip PHP version
                        dependencies.append(f"{package}:{version}")

            return dependencies

        except Exception as e:
            print(f"Warning: Could not parse composer.json: {e}")
            return []

    def _check_env_configured(self) -> bool:
        """Check if .env file is configured"""
        env_file = self.project_dir / ".env"
        if not env_file.exists():
            return False

        try:
            with open(env_file, 'r') as f:
                env_content = f.read()

            # Check for APP_KEY configuration
            return 'APP_KEY=' in env_content and 'APP_KEY=\n' not in env_content

        except Exception:
            return False

    def _check_database_exists(self) -> bool:
        """Check if database file exists"""
        # Check for SQLite database
        db_file = self.project_dir / "database" / "database.sqlite"
        if db_file.exists():
            return True

        # Check for MySQL configuration in .env
        env_file = self.project_dir / ".env"
        if env_file.exists():
            try:
                with open(env_file, 'r') as f:
                    env_content = f.read()

                # Check if MySQL is configured
                return 'DB_DATABASE=' in env_content and 'DB_DATABASE=\n' not in env_content
            except Exception:
                pass

        return False

    def _estimate_completion(
        self,
        routes: List[str],
        controllers: List[str],
        models: List[str],
        migrations: List[str],
        views: List[str],
        tests: List[str]
    ) -> int:
        """
        Rough estimate of project completion percentage

        Args:
            routes, controllers, models, migrations, views, tests: File lists

        Returns:
            Completion percentage (0-100)
        """
        # Scoring system (rough heuristic)
        score = 0
        max_score = 100

        # Routes (15 points)
        if len(routes) > 0:
            score += min(15, len(routes) * 5)

        # Controllers (20 points)
        if len(controllers) > 0:
            score += min(20, len(controllers) * 4)

        # Models (20 points)
        if len(models) > 0:
            score += min(20, len(models) * 4)

        # Migrations (15 points)
        if len(migrations) >= 3:
            score += min(15, (len(migrations) - 2) * 3)

        # Views (15 points)
        if len(views) > 0:
            score += min(15, len(views) * 2)

        # Tests (15 points)
        if len(tests) > 0:
            score += min(15, len(tests) * 3)

        return min(100, score)

    def generate_summary(self, inventory: ProjectInventory) -> str:
        """
        Generate human-readable summary of project inventory

        Args:
            inventory: ProjectInventory object

        Returns:
            Formatted summary string
        """
        if not inventory.has_existing_code:
            return "No existing implementation found. Starting from scratch."

        summary = []
        summary.append("=" * 60)
        summary.append("EXISTING IMPLEMENTATION ANALYSIS")
        summary.append("=" * 60)
        summary.append(f"\nProject: {inventory.project_path}")
        summary.append(f"Estimated Completion: {inventory.estimated_completion}%\n")

        summary.append("Laravel Structure:")
        summary.append("-" * 60)
        summary.append(f"  Routes:       {len(inventory.routes)} files")
        summary.append(f"  Controllers:  {len(inventory.controllers)} files")
        summary.append(f"  Models:       {len(inventory.models)} files")
        summary.append(f"  Migrations:   {len(inventory.migrations)} files")
        summary.append(f"  Views:        {len(inventory.views)} files")
        summary.append(f"  Tests:        {len(inventory.tests)} files")

        summary.append("\nConfiguration:")
        summary.append("-" * 60)
        summary.append(f"  Environment:  {'✓ Configured' if inventory.env_configured else '✗ Not configured'}")
        summary.append(f"  Database:     {'✓ Exists' if inventory.database_exists else '✗ Not found'}")
        summary.append(f"  Dependencies: {len(inventory.composer_dependencies)} packages")

        if inventory.controllers:
            summary.append("\nControllers:")
            for controller in inventory.controllers[:5]:
                summary.append(f"  - {controller}")
            if len(inventory.controllers) > 5:
                summary.append(f"  ... and {len(inventory.controllers) - 5} more")

        if inventory.models:
            summary.append("\nModels:")
            for model in inventory.models[:5]:
                summary.append(f"  - {model}")
            if len(inventory.models) > 5:
                summary.append(f"  ... and {len(inventory.models) - 5} more")

        summary.append("\n" + "=" * 60 + "\n")

        return "\n".join(summary)


def main():
    """Test project analyzer"""
    import sys

    if len(sys.argv) < 2:
        print("Usage: python3 project_analyzer.py <project_dir>")
        sys.exit(1)

    project_dir = sys.argv[1]

    try:
        analyzer = ProjectAnalyzer(project_dir)
        inventory = analyzer.analyze()

        print(analyzer.generate_summary(inventory))

        # Save inventory as JSON
        output_file = Path(project_dir) / "zima-inventory.json"
        with open(output_file, 'w') as f:
            f.write(inventory.to_json())

        print(f"Inventory saved to: {output_file}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == '__main__':
    main()
