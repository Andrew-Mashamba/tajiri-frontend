"""
Zima Looper - Main Orchestrator
Coordinates workers, manages project execution
"""

import argparse
import sys
import os
import signal
import time
from typing import List
from multiprocessing import Process

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.database import get_db
from core.config import get_config
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn, BarColumn, TaskProgressColumn
from rich.live import Live
from rich.table import Table
from rich.layout import Layout
from rich import box

console = Console()


class ZimaOrchestrator:
    """Main orchestrator for Zima Looper"""

    def __init__(self, project_name: str, num_workers: int = 4):
        """
        Initialize orchestrator

        Args:
            project_name: Name of the project to execute
            num_workers: Number of parallel workers
        """
        self.project_name = project_name
        self.num_workers = num_workers
        self.db = get_db()
        self.config = get_config()
        self.workers: List[Process] = []
        self.running = False

        # Get or create project
        self.project = self.db.get_project_by_name(project_name)
        if not self.project:
            # Try to load from prd.json if it exists
            prd_path = os.path.join(project_name, "prd.json")
            if os.path.exists(prd_path):
                console.print(f"[yellow]⚠️  Project not in database, loading from {prd_path}...[/yellow]")
                loaded_name = self._load_prd_from_file(project_name, prd_path)
                self.project = self.db.get_project_by_name(loaded_name)
                if self.project:
                    console.print(f"[green]✓[/green] Loaded project from PRD file")
                else:
                    console.print(f"[red]Error: Failed to load project from PRD[/red]")
                    sys.exit(1)
            else:
                console.print(f"[red]Error: Project '{project_name}' not found in database[/red]")
                console.print(f"[red]Error: PRD file not found at {prd_path}[/red]")
                console.print("\nAvailable projects:")
                projects = self.db.list_projects()
                if projects:
                    for p in projects:
                        console.print(f"  - {p['name']}")
                else:
                    console.print("  (none - use 'zima generate-prd' to create one)")
                sys.exit(1)

        console.print(f"[green]✓[/green] Loaded project: {self.db.get_project_display_name(self.project)}")
        console.print(f"[green]✓[/green] Total stories: {self.project['total_stories']}")

    def _load_prd_from_file(self, project_path: str, prd_path: str) -> str:
        """Load PRD from JSON file into database

        Returns:
            The project name that was created
        """
        import json

        try:
            with open(prd_path, 'r') as f:
                prd = json.load(f)

            # Use directory basename as project name for consistency
            project_name = os.path.basename(os.path.normpath(project_path))
            readme_path = prd.get('readme_path', os.path.join(project_path, 'README.md'))

            # Check if project already exists
            existing_project = self.db.get_project_by_name(project_name)
            if existing_project:
                console.print(f"[yellow]⚠️  Project already exists in database, skipping load[/yellow]")
                return project_name  # Return the project name so it can be found

            # Create project
            project_id = self.db.create_project(
                name=project_name,
                directory=os.path.abspath(project_path),
                readme_path=readme_path,
                prd_path=prd_path
            )

            # Create stories
            for story in prd.get('stories', []):
                self.db.create_story(
                    project_id=project_id,
                    story_data=story
                )

            # Update project stats
            self.db.update_project_stats(project_id)

            console.print(f"[green]✓[/green] Loaded {len(prd.get('stories', []))} stories into database")
            return project_name

        except Exception as e:
            console.print(f"[red]Error loading PRD: {e}[/red]")
            import traceback
            traceback.print_exc()
            raise

    def start(self):
        """Start the orchestrator and spawn workers"""
        console.print(f"\n[cyan]Starting Zima Looper with {self.num_workers} worker(s)...[/cyan]\n")

        # Update project status
        self.db.update_project_status(self.project['id'], 'executing')

        # Show project summary
        self._show_project_summary()

        # Start workers
        self.running = True

        try:
            if self.num_workers == 1:
                console.print("\n[cyan]⚡ Single worker execution[/cyan]")
                self._run_single_worker()
            else:
                console.print(f"\n[cyan]⚡ Parallel execution ({self.num_workers} workers)[/cyan]")
                self._run_parallel_workers()

            # Execution complete
            self._show_final_summary()

        except KeyboardInterrupt:
            console.print("\n[yellow]⚠️  Interrupted by user[/yellow]")
            self.stop()

    def _run_single_worker(self):
        """Run single worker (Phase 3 implementation)"""
        from execution.worker import Worker

        # Create worker
        worker = Worker(
            worker_id=1,
            project_id=self.project['id'],
            project_dir=self.project['directory']
        )

        # Run worker (blocks until complete)
        worker.run()

    def _run_parallel_workers(self):
        """Run multiple workers in parallel (Phase 5 implementation)"""
        from core.worker_pool import WorkerPool

        # Create worker pool
        pool = WorkerPool(
            project_id=self.project['id'],
            project_dir=self.project['directory'],
            num_workers=self.num_workers
        )

        # Start pool (blocks until complete or interrupted)
        pool.start()

    def _show_final_summary(self):
        """Show final execution summary"""
        from core.state_machine import StoryStateMachine

        state_machine = StoryStateMachine(self.db)
        progress = state_machine.get_project_progress(self.project['id'])

        console.print("\n" + "="*60)
        console.print("📊 FINAL SUMMARY")
        console.print("="*60)

        table = Table(box=box.ROUNDED)
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="green")

        table.add_row("Total Stories", str(progress['total_stories']))
        table.add_row("✅ Completed", str(progress['completed_stories']))
        table.add_row("❌ Failed", str(progress['failed_stories']))
        table.add_row("⏭️  Skipped", str(progress['skipped_stories']))
        table.add_row("Completion", f"{progress['completion_percentage']:.1f}%")
        table.add_row("Success Rate", f"{progress['success_rate']:.1f}%")

        console.print(table)

        # Update project status
        if progress['pending_stories'] == 0 and progress['in_progress_stories'] == 0:
            self.db.update_project_status(self.project['id'], 'completed')
            console.print("\n[green]✅ Project execution complete![/green]\n")
        else:
            self.db.update_project_status(self.project['id'], 'paused')
            console.print("\n[yellow]⚠️  Project execution paused[/yellow]\n")

    def stop(self):
        """Stop all workers and cleanup"""
        self.running = False

        for worker in self.workers:
            if worker.is_alive():
                worker.terminate()
                worker.join(timeout=5)

        self.db.update_project_status(self.project['id'], 'paused')
        console.print("[green]✓[/green] Stopped successfully")

    def _show_project_summary(self):
        """Display project summary table"""
        summary = self.db.get_project_summary(self.project['id'])

        table = Table(title="Project Summary", box=box.ROUNDED)
        table.add_column("Metric", style="cyan")
        table.add_column("Value", style="green")

        table.add_row("Project", self.db.get_project_display_name(self.project))
        table.add_row("Status", self.project['status'])
        table.add_row("Total Stories", str(self.project['total_stories']))
        table.add_row("Completed", str(self.project['completed_stories']))
        table.add_row("Failed", str(self.project['failed_stories']))
        table.add_row("Remaining", str(self.project['total_stories'] - self.project['completed_stories']))

        if summary['active_workers']:
            table.add_row("Active Workers", ", ".join(map(str, summary['active_workers'])))

        console.print(table)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="Zima Looper - Autonomous Project Builder")
    parser.add_argument("--project", required=True, help="Project name or path (must contain prd.json)")
    parser.add_argument("--workers", type=int, default=4, help="Number of parallel workers (default: 4)")
    parser.add_argument("--story", help="Run only this story, e.g. STORY-001 or 1")
    parser.add_argument("--config", help="Path to config.yaml")

    args = parser.parse_args()

    # Load config if provided
    if args.config:
        get_config(args.config)

    if args.story:
        os.environ['ZIMA_STORY_FILTER'] = args.story.strip()
    elif os.environ.get('ZIMA_STORY_FILTER'):
        del os.environ['ZIMA_STORY_FILTER']

    # Create and start orchestrator
    orchestrator = ZimaOrchestrator(args.project, args.workers)
    orchestrator.start()


if __name__ == "__main__":
    main()
