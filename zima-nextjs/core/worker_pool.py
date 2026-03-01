"""
Zima Looper - Worker Pool Manager
Manages multiple concurrent workers with coordination and monitoring
"""

import os
import sys
import time
import signal
from multiprocessing import Process, get_context
from typing import List, Dict, Optional
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from core.database import get_db
from core.config import get_config
from execution.worker import run_worker

# Use 'spawn' so child processes don't inherit problematic state (e.g. on macOS)
_mp_ctx = get_context("spawn")


class WorkerStatus:
    """Worker status tracking"""

    def __init__(self, worker_id: int, process: Process):
        self.worker_id = worker_id
        self.process = process
        self.started_at = datetime.now()
        self.current_story_id = None
        self.stories_completed = 0
        self.stories_failed = 0
        self.is_alive = True
        self.last_heartbeat = datetime.now()


class WorkerPool:
    """
    Manages a pool of worker processes
    """

    def __init__(
        self,
        project_id: int,
        project_dir: str,
        num_workers: int = 4
    ):
        """
        Initialize worker pool

        Args:
            project_id: Project ID to work on
            project_dir: Project directory path
            num_workers: Number of concurrent workers
        """
        self.project_id = project_id
        self.project_dir = project_dir
        self.num_workers = num_workers
        self.workers: List[WorkerStatus] = []
        self.running = False

        self.db = get_db()
        self.config = get_config()

        # Setup signal handlers
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)

    def start(self):
        """Start all workers in the pool"""
        print(f"\n{'='*60}", flush=True)
        print(f"⚡ Starting Worker Pool ({self.num_workers} workers)", flush=True)
        print(f"{'='*60}\n", flush=True)

        self.running = True

        # So workers can apply per-worker memory limit (70% system RAM / num_workers)
        os.environ["ZIMA_NUM_WORKERS"] = str(self.num_workers)

        # Spawn workers
        for i in range(self.num_workers):
            self._spawn_worker(i + 1)

        print(f"✓ All {self.num_workers} workers started\n", flush=True)

        # Monitor workers
        try:
            self._monitor_workers()
        except KeyboardInterrupt:
            print("\n⚠️  Interrupted by user")
            self.stop()

    def add_workers(self, count: int = 1):
        """
        Dynamically add more workers to the pool without disrupting existing workers.

        Args:
            count: Number of workers to add
        """
        current_max_id = max([w.worker_id for w in self.workers]) if self.workers else 0

        print(f"\n⚡ Adding {count} new worker(s) to pool...")

        for i in range(count):
            new_worker_id = current_max_id + i + 1
            self._spawn_worker(new_worker_id)
            self.num_workers += 1

        print(f"✓ Pool now has {self.num_workers} workers\n")

    def _spawn_worker(self, worker_id: int):
        """
        Spawn a single worker process

        Args:
            worker_id: Unique worker ID
        """
        # Create worker process using spawn context (reliable on macOS/Windows)
        process = _mp_ctx.Process(
            target=run_worker,
            args=(worker_id, self.project_id, self.project_dir),
            name=f"Worker-{worker_id}"
        )

        try:
            process.start()
        except Exception as e:
            print(f"✗ Worker #{worker_id} failed to start: {e}", flush=True)
            raise

        # Track worker status
        worker_status = WorkerStatus(worker_id, process)
        self.workers.append(worker_status)

        print(f"✓ Worker #{worker_id} started (PID: {process.pid})", flush=True)

    def _monitor_workers(self):
        """Monitor worker health and restart if needed"""

        print("📊 Monitoring workers (Ctrl+C to stop)\n")

        check_interval = 5  # Check every 5 seconds
        status_interval = 30  # Show status every 30 seconds
        last_status_time = time.time()

        while self.running:
            time.sleep(check_interval)

            # Check if project is complete
            if self._is_project_complete():
                print("\n✅ All stories complete!")
                self.stop()
                break

            # Check worker health
            for worker_status in self.workers:
                # Check if process died
                if not worker_status.process.is_alive():
                    if self.running:  # Only restart if pool is still running
                        print(f"\n⚠️  Worker #{worker_status.worker_id} died! Restarting...")
                        self._restart_worker(worker_status)

            # Show status periodically
            current_time = time.time()
            if current_time - last_status_time >= status_interval:
                self._show_pool_status()
                last_status_time = current_time

            # Check for stuck workers (no activity for 10 minutes)
            self._check_stuck_workers()

    def _restart_worker(self, worker_status: WorkerStatus):
        """
        Restart a dead worker

        Args:
            worker_status: WorkerStatus object
        """
        worker_id = worker_status.worker_id

        # Release any stories claimed by dead worker
        self.db.release_worker_stories(worker_id)

        # Remove old worker
        self.workers.remove(worker_status)

        # Spawn new worker with same ID
        self._spawn_worker(worker_id)

    def _check_stuck_workers(self):
        """Check for workers that may be stuck"""

        timeout_minutes = 15  # Consider stuck after 15 minutes on same story

        for worker_status in self.workers:
            if worker_status.current_story_id:
                # Check how long worker has been on this story
                elapsed = (datetime.now() - worker_status.last_heartbeat).total_seconds()

                if elapsed > timeout_minutes * 60:
                    print(f"\n⚠️  Worker #{worker_status.worker_id} may be stuck (no activity for {elapsed/60:.1f} minutes)")
                    print(f"   Consider manual intervention or restart")

    def _is_project_complete(self) -> bool:
        """Check if all stories in project are complete"""

        stories = self.db.get_project_stories(self.project_id)

        pending_count = sum(1 for s in stories if s['status'] == 'pending')
        in_progress_count = sum(1 for s in stories if s['status'] in ['in_progress', 'planning', 'implementing', 'testing'])

        return pending_count == 0 and in_progress_count == 0

    def _show_pool_status(self):
        """Display worker pool status"""

        print("\n" + "="*60)
        print("📊 WORKER POOL STATUS")
        print("="*60)

        # Get project progress
        project = self.db.get_project(self.project_id)
        stories = self.db.get_project_stories(self.project_id)

        total = len(stories)
        completed = sum(1 for s in stories if s['status'] == 'completed')
        failed = sum(1 for s in stories if s['status'] == 'failed')
        in_progress = sum(1 for s in stories if s['status'] in ['in_progress', 'planning', 'implementing', 'testing'])
        pending = sum(1 for s in stories if s['status'] == 'pending')

        print(f"\nProject: {self.db.get_project_display_name(project)}")
        print(f"Progress: {completed}/{total} completed ({completed/total*100:.1f}%)")
        print(f"  ✅ Completed: {completed}")
        print(f"  🔄 In Progress: {in_progress}")
        print(f"  ⏳ Pending: {pending}")
        print(f"  ❌ Failed: {failed}")

        print(f"\nWorkers:")
        for worker_status in self.workers:
            alive_status = "🟢 Running" if worker_status.process.is_alive() else "🔴 Dead"
            print(f"  Worker #{worker_status.worker_id}: {alive_status} (PID: {worker_status.process.pid})")

        print("="*60 + "\n")

    def stop(self):
        """Stop all workers gracefully"""

        if not self.running:
            return

        print(f"\n{'='*60}")
        print("⚠️  Stopping Worker Pool")
        print(f"{'='*60}\n")

        self.running = False

        # Give workers time to finish current stories
        print("Waiting for workers to finish current stories (max 30s)...")
        timeout = 30
        start_time = time.time()

        while time.time() - start_time < timeout:
            all_stopped = all(not w.process.is_alive() for w in self.workers)
            if all_stopped:
                break
            time.sleep(1)

        # Terminate any remaining workers
        for worker_status in self.workers:
            if worker_status.process.is_alive():
                print(f"Terminating Worker #{worker_status.worker_id}...")
                worker_status.process.terminate()
                worker_status.process.join(timeout=5)

                # Force kill if still alive
                if worker_status.process.is_alive():
                    print(f"Force killing Worker #{worker_status.worker_id}...")
                    worker_status.process.kill()
                    worker_status.process.join()

        # Release any claimed stories
        for worker_status in self.workers:
            self.db.release_worker_stories(worker_status.worker_id)

        print("\n✓ All workers stopped\n")

    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print(f"\n⚠️  Received signal {signum}")
        self.stop()

    def get_pool_stats(self) -> Dict:
        """Get worker pool statistics"""

        stories = self.db.get_project_stories(self.project_id)

        stats = {
            'num_workers': self.num_workers,
            'workers_alive': sum(1 for w in self.workers if w.process.is_alive()),
            'total_stories': len(stories),
            'completed_stories': sum(1 for s in stories if s['status'] == 'completed'),
            'failed_stories': sum(1 for s in stories if s['status'] == 'failed'),
            'in_progress_stories': sum(1 for s in stories if s['status'] in ['in_progress', 'planning', 'implementing', 'testing']),
            'pending_stories': sum(1 for s in stories if s['status'] == 'pending'),
            'worker_details': []
        }

        for worker_status in self.workers:
            stats['worker_details'].append({
                'worker_id': worker_status.worker_id,
                'pid': worker_status.process.pid,
                'is_alive': worker_status.process.is_alive(),
                'started_at': worker_status.started_at.isoformat()
            })

        return stats


def create_worker_pool(project_id: int, project_dir: str, num_workers: int = 4) -> WorkerPool:
    """
    Convenience function to create and start worker pool

    Args:
        project_id: Project ID
        project_dir: Project directory path
        num_workers: Number of workers

    Returns:
        WorkerPool instance
    """
    pool = WorkerPool(project_id, project_dir, num_workers)
    return pool
