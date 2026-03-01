"""
Zima Looper - SQLite Database Layer
Handles all database operations for project and story management
"""

import sqlite3
import json
from datetime import datetime
from typing import List, Dict, Optional, Tuple, Any
from contextlib import contextmanager
import os


class Database:
    """SQLite database wrapper for Zima Looper state management"""

    def __init__(self, db_path: str = None):
        """
        Initialize database connection

        Args:
            db_path: Path to SQLite database file
        """
        if db_path is None:
            # Default to zima.db inside the zima/ folder
            script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            db_path = os.path.join(script_dir, "zima.db")
        self.db_path = db_path
        self.init_database()

    @contextmanager
    def get_connection(self):
        """Context manager for database connections"""
        conn = sqlite3.connect(self.db_path, timeout=30.0)
        conn.row_factory = sqlite3.Row  # Return rows as dictionaries
        conn.execute("PRAGMA journal_mode=WAL")  # Enable Write-Ahead Logging for concurrency
        conn.execute("PRAGMA busy_timeout=30000")  # Wait up to 30s if DB locked (multi-worker)
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
        finally:
            conn.close()

    def init_database(self):
        """Create all tables if they don't exist"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Projects table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS projects (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL UNIQUE,
                    directory TEXT NOT NULL,
                    readme_path TEXT NOT NULL,
                    prd_path TEXT,
                    status TEXT NOT NULL DEFAULT 'pending',
                    total_stories INTEGER DEFAULT 0,
                    completed_stories INTEGER DEFAULT 0,
                    failed_stories INTEGER DEFAULT 0,
                    started_at DATETIME,
                    completed_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                )
            ''')

            # Stories table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS stories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    project_id INTEGER NOT NULL,
                    story_number INTEGER NOT NULL,
                    title TEXT NOT NULL,
                    description TEXT,
                    acceptance_criteria TEXT,
                    priority INTEGER,
                    estimate_hours REAL,
                    status TEXT NOT NULL DEFAULT 'pending',
                    worker_id INTEGER,
                    retry_count INTEGER DEFAULT 0,
                    max_retries INTEGER DEFAULT 3,
                    error_message TEXT,
                    error_logs TEXT,
                    started_at DATETIME,
                    completed_at DATETIME,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (project_id) REFERENCES projects(id),
                    UNIQUE(project_id, story_number)
                )
            ''')

            # Checkpoints table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS checkpoints (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    story_id INTEGER NOT NULL,
                    checkpoint_type TEXT NOT NULL,
                    data TEXT,
                    files_modified TEXT,
                    git_sha TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (story_id) REFERENCES stories(id)
                )
            ''')

            # Executions table (activity log)
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS executions (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    story_id INTEGER NOT NULL,
                    execution_type TEXT NOT NULL,
                    command TEXT,
                    output TEXT,
                    exit_code INTEGER,
                    duration_seconds REAL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (story_id) REFERENCES stories(id)
                )
            ''')

            # Metrics table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    project_id INTEGER NOT NULL,
                    metric_name TEXT NOT NULL,
                    metric_value REAL NOT NULL,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (project_id) REFERENCES projects(id)
                )
            ''')

            # Recent changes log (shared across workers for token optimization)
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS recent_changes (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    project_id INTEGER NOT NULL,
                    story_id INTEGER NOT NULL,
                    story_number INTEGER NOT NULL,
                    one_liner TEXT NOT NULL,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (project_id) REFERENCES projects(id),
                    FOREIGN KEY (story_id) REFERENCES stories(id)
                )
            ''')

            conn.commit()

    # ========== PROJECT METHODS ==========

    def create_project(self, name: str, directory: str, readme_path: str, prd_path: str = None) -> int:
        """
        Create a new project

        Returns:
            project_id
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO projects (name, directory, readme_path, prd_path, status)
                VALUES (?, ?, ?, ?, 'pending')
            ''', (name, directory, readme_path, prd_path))
            return cursor.lastrowid

    def get_project(self, project_id: int) -> Optional[Dict]:
        """Get project by ID"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM projects WHERE id = ?', (project_id,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def get_project_display_name(self, project: Dict) -> str:
        """Return a human-friendly project name (e.g. ENTERPRISESACCOS instead of '..')."""
        if not project:
            return ""
        name = project.get("name") or ""
        if name == ".." and project.get("directory"):
            return os.path.basename(os.path.normpath(project["directory"]))
        return name

    def get_project_by_name(self, name: str) -> Optional[Dict]:
        """Get project by name"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM projects WHERE name = ?', (name,))
            row = cursor.fetchone()
            return dict(row) if row else None

    def list_projects(self) -> List[Dict]:
        """List all projects"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM projects ORDER BY created_at DESC')
            return [dict(row) for row in cursor.fetchall()]

    def update_project_status(self, project_id: int, status: str):
        """Update project status"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE projects
                SET status = ?, updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (status, project_id))

    def update_project_stats(self, project_id: int):
        """Recalculate and update project statistics"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Count stories by status
            cursor.execute('''
                SELECT
                    COUNT(*) as total,
                    SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END) as completed,
                    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed
                FROM stories
                WHERE project_id = ?
            ''', (project_id,))

            stats = cursor.fetchone()

            cursor.execute('''
                UPDATE projects
                SET
                    total_stories = ?,
                    completed_stories = ?,
                    failed_stories = ?,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (stats['total'], stats['completed'], stats['failed'], project_id))

    # ========== STORY METHODS ==========

    def create_story(self, project_id: int, story_data: Dict) -> int:
        """
        Create a new story

        Args:
            project_id: ID of the parent project
            story_data: Dictionary with story fields

        Returns:
            story_id
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()

            acceptance_criteria_json = json.dumps(story_data.get('acceptance', []))

            cursor.execute('''
                INSERT INTO stories (
                    project_id, story_number, title, description,
                    acceptance_criteria, priority, estimate_hours
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                project_id,
                story_data.get('id', story_data.get('story_number')),
                story_data.get('title'),
                story_data.get('description'),
                acceptance_criteria_json,
                story_data.get('priority'),
                story_data.get('estimate_hours', story_data.get('estimate', 1.0))
            ))

            return cursor.lastrowid

    def get_story(self, story_id: int) -> Optional[Dict]:
        """Get story by ID"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM stories WHERE id = ?', (story_id,))
            row = cursor.fetchone()

            if row:
                story = dict(row)
                # Parse JSON fields
                story['acceptance_criteria'] = json.loads(story['acceptance_criteria']) if story['acceptance_criteria'] else []
                return story
            return None

    def get_next_pending_story(self, project_id: int, worker_id: int, check_dependencies: bool = True,
                               story_filter: Optional[str] = None) -> Optional[Dict]:
        """
        Get next pending story and atomically assign it to worker.

        Args:
            story_filter: Optional "STORY-001" or "1" to run only that story (by story_number).
        """
        filter_story_number = None
        if story_filter is not None:
            s = str(story_filter).strip().upper()
            if s.isdigit():
                filter_story_number = int(s)
            elif s.startswith("STORY-") and len(s) > 6 and s[6:].isdigit():
                filter_story_number = int(s[6:])

        # If dependency checking is enabled, find a story with met dependencies
        if check_dependencies:
            from core.dependency import DependencyDetector

            all_stories = self.get_project_stories(project_id)
            detector = DependencyDetector()
            ready_stories = detector.get_ready_stories(all_stories)
            if filter_story_number is not None:
                ready_stories = [s for s in ready_stories if s.get('story_number') == filter_story_number]

            if not ready_stories:
                return None

            for story in ready_stories:
                with self.get_connection() as conn:
                    cursor = conn.cursor()

                    # Atomic update: try to claim this specific story
                    cursor.execute('''
                        UPDATE stories
                        SET
                            status = 'in_progress',
                            worker_id = ?,
                            started_at = CURRENT_TIMESTAMP,
                            updated_at = CURRENT_TIMESTAMP
                        WHERE id = ? AND status = 'pending'
                    ''', (worker_id, story['id']))

                    if cursor.rowcount > 0:
                        # Successfully claimed
                        return story

            return None

        # Non-dependency path: claim next pending (optionally filtered by story_number)
        with self.get_connection() as conn:
            cursor = conn.cursor()
            if filter_story_number is not None:
                cursor.execute('''
                    UPDATE stories SET status = 'in_progress', worker_id = ?,
                    started_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
                    WHERE id = (SELECT id FROM stories WHERE project_id = ? AND status = 'pending' AND story_number = ?
                    ORDER BY priority ASC, story_number ASC LIMIT 1)
                ''', (worker_id, project_id, filter_story_number))
            else:
                cursor.execute('''
                    UPDATE stories SET status = 'in_progress', worker_id = ?,
                    started_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
                    WHERE id = (SELECT id FROM stories WHERE project_id = ? AND status = 'pending'
                    ORDER BY priority ASC, story_number ASC LIMIT 1)
                ''', (worker_id, project_id))

            if cursor.rowcount == 0:
                return None  # No pending stories

            # Get the story we just claimed
            cursor.execute('''
                SELECT * FROM stories
                WHERE project_id = ? AND worker_id = ? AND status = 'in_progress'
                ORDER BY updated_at DESC
                LIMIT 1
            ''', (project_id, worker_id))

            row = cursor.fetchone()
            if row:
                story = dict(row)
                story['acceptance_criteria'] = json.loads(story['acceptance_criteria']) if story['acceptance_criteria'] else []
                return story
            return None

    def release_worker_stories(self, worker_id: int):
        """
        Release all stories claimed by a worker (for dead/crashed workers)

        Args:
            worker_id: Worker ID to release stories for
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()

            cursor.execute('''
                UPDATE stories
                SET
                    status = 'pending',
                    worker_id = NULL,
                    updated_at = CURRENT_TIMESTAMP
                WHERE worker_id = ? AND status IN ('in_progress', 'planning', 'implementing', 'testing')
            ''', (worker_id,))

            released_count = cursor.rowcount

            if released_count > 0:
                print(f"Released {released_count} story/stories from Worker #{worker_id}")

    def update_story_status(self, story_id: int, status: str, error_message: str = None, error_logs: str = None):
        """Update story status"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            if status == 'completed':
                cursor.execute('''
                    UPDATE stories
                    SET
                        status = ?,
                        completed_at = CURRENT_TIMESTAMP,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                ''', (status, story_id))
            else:
                cursor.execute('''
                    UPDATE stories
                    SET
                        status = ?,
                        error_message = ?,
                        error_logs = ?,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id = ?
                ''', (status, error_message, error_logs, story_id))


    def update_story(self, story_id: int, updates: dict):
        """Update story with arbitrary fields"""
        if not updates:
            return
        with self.get_connection() as conn:
            cursor = conn.cursor()
            set_clauses = []
            values = []
            for key, value in updates.items():
                set_clauses.append(f"{key} = ?")
                values.append(value)
            set_clauses.append("updated_at = CURRENT_TIMESTAMP")
            sql = f"UPDATE stories SET {', '.join(set_clauses)} WHERE id = ?"
            values.append(story_id)
            cursor.execute(sql, values)

    def increment_retry_count(self, story_id: int) -> int:
        """
        Increment retry count for a story

        Returns:
            New retry count
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE stories
                SET
                    retry_count = retry_count + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = ?
            ''', (story_id,))

            cursor.execute('SELECT retry_count FROM stories WHERE id = ?', (story_id,))
            return cursor.fetchone()['retry_count']

    def get_project_stories(self, project_id: int, status: str = None) -> List[Dict]:
        """
        Get all stories for a project, optionally filtered by status

        Args:
            project_id: Project ID
            status: Optional status filter (pending, in_progress, completed, failed)

        Returns:
            List of story dictionaries
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()

            if status:
                cursor.execute('''
                    SELECT * FROM stories
                    WHERE project_id = ? AND status = ?
                    ORDER BY priority ASC, story_number ASC
                ''', (project_id, status))
            else:
                cursor.execute('''
                    SELECT * FROM stories
                    WHERE project_id = ?
                    ORDER BY priority ASC, story_number ASC
                ''', (project_id,))

            rows = cursor.fetchall()
            stories = []
            for row in rows:
                story = dict(row)
                story['acceptance_criteria'] = json.loads(story['acceptance_criteria']) if story['acceptance_criteria'] else []
                stories.append(story)

            return stories

    # ========== CHECKPOINT METHODS ==========

    def create_checkpoint(self, story_id: int, checkpoint_type: str, data: Dict = None,
                         files_modified: List[str] = None, git_sha: str = None):
        """Create a checkpoint for a story"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            data_json = json.dumps(data) if data else None
            files_json = json.dumps(files_modified) if files_modified else None

            cursor.execute('''
                INSERT INTO checkpoints (story_id, checkpoint_type, data, files_modified, git_sha)
                VALUES (?, ?, ?, ?, ?)
            ''', (story_id, checkpoint_type, data_json, files_json, git_sha))

            return cursor.lastrowid

    def get_latest_checkpoint(self, story_id: int, checkpoint_type: str = None) -> Optional[Dict]:
        """Get latest checkpoint for a story"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            if checkpoint_type:
                cursor.execute('''
                    SELECT * FROM checkpoints
                    WHERE story_id = ? AND checkpoint_type = ?
                    ORDER BY created_at DESC
                    LIMIT 1
                ''', (story_id, checkpoint_type))
            else:
                cursor.execute('''
                    SELECT * FROM checkpoints
                    WHERE story_id = ?
                    ORDER BY created_at DESC
                    LIMIT 1
                ''', (story_id,))

            row = cursor.fetchone()
            if row:
                checkpoint = dict(row)
                checkpoint['data'] = json.loads(checkpoint['data']) if checkpoint['data'] else None
                checkpoint['files_modified'] = json.loads(checkpoint['files_modified']) if checkpoint['files_modified'] else []
                return checkpoint
            return None

    def get_recent_completions_summary(
        self,
        project_id: int,
        limit_stories: int = 15,
        max_chars: int = 1500,
        exclude_story_id: int = None
    ) -> str:
        """
        Build a short summary of recently completed stories and files they modified,
        for injection into other workers' prompts (shared context, avoid duplicate work).

        Returns:
            String like "Already done: Story 1 (Login): app/Http/Controllers/AuthController.php. Story 2 (Dashboard): ..."
        """
        completed = self.get_project_stories(project_id, status='completed')
        if not completed:
            return ""
        # Order by completed_at desc (most recent first); limit
        completed = sorted(
            [s for s in completed if s.get('id') != exclude_story_id],
            key=lambda s: (s.get('completed_at') or ''), reverse=True
        )[:limit_stories]
        parts = []
        total = 0
        for s in completed:
            cps = self.get_story_checkpoints(s['id'])
            files = []
            if cps and cps[0].get('files_modified'):
                files = cps[0]['files_modified'][:8]  # max 8 files per story
            line = "Story {} ({}): {}".format(
                s['story_number'],
                (s.get('title') or '')[:40],
                ", ".join(files) if files else "(no files)"
            )
            if total + len(line) + 2 > max_chars:
                break
            parts.append(line)
            total += len(line) + 2
        if not parts:
            return ""
        return "Already done (reuse, do not re-implement): " + "; ".join(parts)

    def append_recent_change(
        self,
        project_id: int,
        story_id: int,
        story_number: int,
        title: str,
        files_modified: List[str] = None
    ) -> None:
        """
        Append a one-liner to the recent changes log (handoff for other workers).
        Called when a story completes successfully.
        """
        files = (files_modified or [])[:6]
        one_liner = "Story {} ({}): {}".format(
            story_number,
            (title or "")[:50],
            ", ".join(files) if files else "done"
        )
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO recent_changes (project_id, story_id, story_number, one_liner)
                VALUES (?, ?, ?, ?)
            ''', (project_id, story_id, story_number, one_liner))

    def get_recent_changes(
        self,
        project_id: int,
        limit: int = 20,
        max_chars: int = 500
    ) -> str:
        """
        Get last N lines from recent_changes for prompt injection.
        Returns empty string if none.
        """
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT one_liner FROM recent_changes
                WHERE project_id = ?
                ORDER BY created_at DESC
                LIMIT ?
            ''', (project_id, limit))
            rows = cursor.fetchall()
        if not rows:
            return ""
        lines = [row[0] for row in reversed(rows)]  # oldest first
        out = []
        total = 0
        for line in lines:
            if total + len(line) + 1 > max_chars:
                break
            out.append(line)
            total += len(line) + 1
        if not out:
            return ""
        return "Recent changes by other workers:\n" + "\n".join(out)

    def get_recently_touched_files(
        self,
        project_id: int,
        limit_stories: int = 15,
        max_files: int = 30
    ) -> str:
        """
        Deduplicated list of files modified by recently completed stories.
        For "avoid modifying unless your story requires it" prompt line.
        """
        completed = self.get_project_stories(project_id, status='completed')
        if not completed:
            return ""
        completed = sorted(
            completed,
            key=lambda s: (s.get('completed_at') or ''), reverse=True
        )[:limit_stories]
        seen = set()
        files = []
        for s in completed:
            cps = self.get_story_checkpoints(s['id'])
            if not cps or not cps[0].get('files_modified'):
                continue
            for f in cps[0]['files_modified']:
                if f not in seen and len(files) < max_files:
                    seen.add(f)
                    files.append(f)
        if not files:
            return ""
        return "Avoid modifying these files unless your story requires it: " + ", ".join(files)

    def get_story_checkpoints(self, story_id: int) -> List[Dict]:
        """Get all checkpoints for a story, ordered by most recent first"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM checkpoints
                WHERE story_id = ?
                ORDER BY created_at DESC
            ''', (story_id,))

            rows = cursor.fetchall()
            checkpoints = []
            for row in rows:
                checkpoint = dict(row)
                checkpoint['data'] = json.loads(checkpoint['data']) if checkpoint['data'] else None
                checkpoint['files_modified'] = json.loads(checkpoint['files_modified']) if checkpoint['files_modified'] else []
                checkpoints.append(checkpoint)

            return checkpoints

    def get_checkpoint(self, checkpoint_id: int) -> Optional[Dict]:
        """Get a specific checkpoint by ID"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM checkpoints WHERE id = ?', (checkpoint_id,))

            row = cursor.fetchone()
            if row:
                checkpoint = dict(row)
                checkpoint['data'] = json.loads(checkpoint['data']) if checkpoint['data'] else None
                checkpoint['files_modified'] = json.loads(checkpoint['files_modified']) if checkpoint['files_modified'] else []
                return checkpoint
            return None

    def delete_checkpoint(self, checkpoint_id: int):
        """Delete a checkpoint"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('DELETE FROM checkpoints WHERE id = ?', (checkpoint_id,))

    # ========== EXECUTION LOG METHODS ==========

    def log_execution(self, story_id: int, execution_type: str, command: str = None,
                     output: str = None, exit_code: int = None, duration_seconds: float = None):
        """Log an execution event"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO executions (story_id, execution_type, command, output, exit_code, duration_seconds)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (story_id, execution_type, command, output, exit_code, duration_seconds))

    def get_story_executions(self, story_id: int, limit: int = 10) -> List[Dict]:
        """Get recent executions for a story"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT * FROM executions
                WHERE story_id = ?
                ORDER BY created_at DESC
                LIMIT ?
            ''', (story_id, limit))

            return [dict(row) for row in cursor.fetchall()]

    # ========== METRICS METHODS ==========

    def record_metric(self, project_id: int, metric_name: str, metric_value: float):
        """Record a metric value"""
        with self.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO metrics (project_id, metric_name, metric_value)
                VALUES (?, ?, ?)
            ''', (project_id, metric_name, metric_value))

    def get_metrics(self, project_id: int, metric_name: str = None, limit: int = 100) -> List[Dict]:
        """Get metrics for a project"""
        with self.get_connection() as conn:
            cursor = conn.cursor()

            if metric_name:
                cursor.execute('''
                    SELECT * FROM metrics
                    WHERE project_id = ? AND metric_name = ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                ''', (project_id, metric_name, limit))
            else:
                cursor.execute('''
                    SELECT * FROM metrics
                    WHERE project_id = ?
                    ORDER BY timestamp DESC
                    LIMIT ?
                ''', (project_id, limit))

            return [dict(row) for row in cursor.fetchall()]

    # ========== UTILITY METHODS ==========

    def get_project_summary(self, project_id: int) -> Dict:
        """Get comprehensive project summary with statistics"""
        project = self.get_project(project_id)
        if not project:
            return None

        with self.get_connection() as conn:
            cursor = conn.cursor()

            # Story statistics
            cursor.execute('''
                SELECT
                    status,
                    COUNT(*) as count,
                    AVG(retry_count) as avg_retries
                FROM stories
                WHERE project_id = ?
                GROUP BY status
            ''', (project_id,))

            story_stats = {}
            for row in cursor.fetchall():
                story_stats[row['status']] = {
                    'count': row['count'],
                    'avg_retries': row['avg_retries']
                }

            # Active workers
            cursor.execute('''
                SELECT DISTINCT worker_id
                FROM stories
                WHERE project_id = ?
                  AND status IN ('in_progress', 'planning', 'implementing', 'testing')
                  AND worker_id IS NOT NULL
            ''', (project_id,))

            active_workers = [row['worker_id'] for row in cursor.fetchall()]

            return {
                'project': project,
                'story_stats': story_stats,
                'active_workers': active_workers
            }


# Singleton instance
_db_instance = None

def get_db(db_path: str = None) -> Database:
    """Get or create database singleton"""
    global _db_instance
    if _db_instance is None:
        _db_instance = Database(db_path)
    return _db_instance
