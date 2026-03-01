"""
Zima Looper - Worker Process
Continuously polls for and executes pending stories
"""

import os
import sys
import time
import signal
from typing import Optional
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.database import get_db
from core.config import get_config
from execution.executor import StoryExecutor
from execution.checkpoint import CheckpointManager
from core.state_machine import StoryStateMachine
from recovery.retry import RetryManager, RetryStrategy
from recovery.error_analyzer import ErrorAnalyzer
from recovery.claude_fixer import ClaudeFixer


class Worker:
    """
    Worker process that executes stories from the queue
    """

    def __init__(self, worker_id: int, project_id: int, project_dir: str):
        """
        Initialize worker

        Args:
            worker_id: Unique worker ID (1-4)
            project_id: Project ID to work on
            project_dir: Project directory path
        """
        self.worker_id = worker_id
        self.project_id = project_id
        self.project_dir = project_dir
        self.running = True
        self.current_story_id = None

        # Initialize components
        self.db = get_db()
        self.config = get_config()
        self.executor = StoryExecutor(
            db=self.db,
            config=self.config,
            project_dir=project_dir,
            worker_id=worker_id
        )
        self.state_machine = StoryStateMachine(self.db)
        self.checkpoint_manager = CheckpointManager(self.db, project_dir)
        self.retry_manager = RetryManager(self.config)
        self.error_analyzer = ErrorAnalyzer()
        self.claude_fixer = ClaudeFixer(self.db, self.config, project_dir)

        # Setup signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def run(self):
        """
        Main worker loop
        Continuously polls for pending stories and executes them
        """
        print(f"\n{'='*60}")
        print(f"⚡ Worker #{self.worker_id} started")
        print(f"{'='*60}\n")

        story_filter = os.environ.get('ZIMA_STORY_FILTER') or None
        if story_filter:
            print(f"Worker #{self.worker_id}: story filter active: {story_filter}")

        while self.running:
            story = self.db.get_next_pending_story(
                self.project_id, self.worker_id, story_filter=story_filter
            )

            if story:
                self.current_story_id = story['id']
                self._execute_story(story)
                self.current_story_id = None
            else:
                # No pending stories, check if project is complete
                if self._is_project_complete():
                    print(f"\n✅ Worker #{self.worker_id}: All stories complete, shutting down")
                    break

                # Wait before polling again
                print(f"Worker #{self.worker_id}: No pending stories, waiting {self.config.poll_interval_seconds}s...")
                time.sleep(self.config.poll_interval_seconds)

        print(f"\n⚡ Worker #{self.worker_id} stopped\n")

    def _execute_story(self, story: dict):
        """
        Execute a single story with intelligent retry logic

        Args:
            story: Story dictionary
        """
        story_id = story['id']
        story_number = story['story_number']

        print(f"\n{'='*60}")
        print(f"Worker #{self.worker_id} executing Story {story_number}")
        print(f"{'='*60}")

        # Execute story
        success = self.executor.execute_story(story_id)

        if success:
            # Story completed successfully
            print(f"✅ Worker #{self.worker_id}: Story {story_number} completed")
            return

        # Story failed - analyze error
        story = self.db.get_story(story_id)  # Refresh story data
        error_logs = story.get('error_logs', '')
        error_message = story.get('error_message', '')

        # Analyze error
        error_analysis = self.error_analyzer.analyze(
            error_logs=error_logs,
            execution_type='story_execution',
            exit_code=1
        )

        print(f"\n📊 Error Analysis:")
        print(f"   Category: {error_analysis.category.value}")
        print(f"   Severity: {error_analysis.severity.value}")
        print(f"   Recoverable: {error_analysis.is_recoverable}")
        print(f"   Confidence: {error_analysis.confidence:.0%}")

        # Decide if we should retry
        retry_decision = self.retry_manager.should_retry(
            story=story,
            error_type=error_analysis.category.value,
            error_message=error_message
        )

        if retry_decision.should_retry:
            # Retry with strategy
            retry_count = story['retry_count'] + 1
            message = self.retry_manager.format_retry_message(retry_decision, retry_count)
            print(f"\n{message}")

            # Execute retry with wait
            self.retry_manager.execute_retry(
                decision=retry_decision,
                on_wait_callback=lambda wait_time: print(f"⏳ Waiting {wait_time}s before retry...")
            )

            # Rollback to last checkpoint
            print(f"🔄 Rolling back to last checkpoint...")
            self.checkpoint_manager.rollback_to_last_checkpoint(story_id)

            # Release story back to pending for retry
            self.db.update_story(story_id, {
                'status': 'pending',
                'worker_id': None
            })

        else:
            # Max retries reached or non-retryable error
            print(f"\n❌ Worker #{self.worker_id}: {retry_decision.reason}")

            # Check if Claude-powered fix is enabled and error is recoverable
            if self.config.enable_claude_fix and error_analysis.is_recoverable:
                print(f"\n🔧 Attempting Claude-powered fix...")
                fix_success = self._attempt_claude_fix_enhanced(story_id, error_analysis, error_logs)

                if fix_success:
                    print(f"✅ Claude fix successful!")
                    return
                else:
                    print(f"❌ Claude fix failed")

            # Mark as failed and continue to next story
            self.state_machine.transition(story_id, 'failed', retry_decision.reason)
            print(f"Continuing to next story...")

    def _attempt_claude_fix_enhanced(
        self,
        story_id: int,
        error_analysis,
        error_logs: str
    ) -> bool:
        """
        Attempt to fix failed story using enhanced Claude fixer

        Args:
            story_id: Story ID
            error_analysis: ErrorAnalysis object
            error_logs: Full error logs

        Returns:
            True if fix successful
        """
        # Use the enhanced Claude fixer
        fix_success, fix_message = self.claude_fixer.attempt_fix(
            story_id=story_id,
            error_analysis=error_analysis,
            error_logs=error_logs
        )

        if not fix_success:
            return False

        # Reset story for re-execution
        self.db.update_story(story_id, {
            'status': 'pending',
            'worker_id': None,
            'retry_count': 0,  # Reset retry count for fix attempt
            'error_message': None,
            'error_logs': None
        })

        # Rollback to clean state before fix
        self.checkpoint_manager.rollback_to_last_checkpoint(story_id)

        # Re-execute with executor
        return self.executor.execute_story(story_id)

    def _calculate_backoff(self, retry_count: int) -> int:
        """
        Calculate exponential backoff time (DEPRECATED - use RetryManager)

        Args:
            retry_count: Current retry count

        Returns:
            Wait time in seconds
        """
        # This method is deprecated in favor of RetryManager
        # Kept for backward compatibility
        base_delay = self.config.base_delay_seconds
        multiplier = self.config.backoff_multiplier

        return int(base_delay * (multiplier ** (retry_count - 1)))

    def _is_project_complete(self) -> bool:
        """
        Check if all stories in project are complete

        Returns:
            True if project is complete
        """
        stories = self.db.get_project_stories(self.project_id)

        pending_count = sum(1 for s in stories if s['status'] == 'pending')
        in_progress_count = sum(1 for s in stories if s['status'] in ['in_progress', 'planning', 'implementing', 'testing'])

        return pending_count == 0 and in_progress_count == 0

    def _signal_handler(self, signum, frame):
        """
        Handle shutdown signals gracefully

        Args:
            signum: Signal number
            frame: Current stack frame
        """
        print(f"\n⚠️  Worker #{self.worker_id}: Received shutdown signal")

        if self.current_story_id:
            print(f"Finishing current story {self.current_story_id}...")
            # Note: Story execution will complete naturally
            # We just set running=False to prevent picking up new stories

        self.running = False

    def get_status(self) -> dict:
        """
        Get current worker status

        Returns:
            Status dictionary
        """
        return {
            'worker_id': self.worker_id,
            'running': self.running,
            'current_story_id': self.current_story_id,
            'project_id': self.project_id
        }


def _apply_memory_limit():
    """Cap this process (and child agent) to a share of system RAM. Disabled by default - can cause workers to get stuck if limit is too low."""
    try:
        import resource
        config = get_config()
        if not getattr(config, "memory_limit_enabled", False):
            return
        percent = getattr(config, "memory_limit_percent", 70.0) / 100.0
        num_workers = int(os.environ.get("ZIMA_NUM_WORKERS", "4"))
        try:
            import psutil
        except ImportError:
            return
        total = psutil.virtual_memory().total
        # Per-slot limit so total usage across workers stays under percent of system RAM
        limit_per_slot = int(total * percent / num_workers)
        try:
            resource.setrlimit(resource.RLIMIT_AS, (limit_per_slot, limit_per_slot))
        except (ValueError, OSError):
            pass  # e.g. macOS may enforce different limits
    except Exception:
        pass


def run_worker(worker_id: int, project_id: int, project_dir: str):
    """
    Entry point for running a worker

    Args:
        worker_id: Worker ID
        project_id: Project ID
        project_dir: Project directory path
    """
    _apply_memory_limit()
    print(f"[Worker-{worker_id}] process started (PID: {os.getpid()})", flush=True)
    try:
        worker = Worker(worker_id, project_id, project_dir)
        worker.run()
    except Exception as e:
        print(f"[Worker-{worker_id}] fatal: {e}", flush=True)
        import traceback
        traceback.print_exc()
        raise


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Zima Looper Worker")
    parser.add_argument('--worker-id', type=int, required=True, help="Worker ID (1-4)")
    parser.add_argument('--project-id', type=int, required=True, help="Project ID")
    parser.add_argument('--project-dir', required=True, help="Project directory path")

    args = parser.parse_args()

    run_worker(args.worker_id, args.project_id, args.project_dir)
