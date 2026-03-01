#!/usr/bin/env python3
"""
Sync story status from execution history.

Use when workers ran but did not persist status updates (e.g. before the
update_project_stats + WAL/busy_timeout fix). Marks as 'completed' any story
that has "Implementation complete" or "Commit created" in the executions table
but is still pending/in_progress, so they are not redone on the next run.

Usage:
  python3 scripts/sync_story_status_from_executions.py [--project-id ID] [--dry-run]
"""

import argparse
import os
import sys
from datetime import datetime

# Add zima root to path
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ZIMA_ROOT = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, ZIMA_ROOT)

from core.database import get_db


def main():
    parser = argparse.ArgumentParser(
        description="Set story status to completed using execution history (avoid redoing work)."
    )
    parser.add_argument(
        "--project-id",
        type=int,
        default=None,
        help="Only sync stories for this project_id (default: all projects)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Only print what would be updated, do not write",
    )
    args = parser.parse_args()

    db = get_db()

    # Story IDs that have completion evidence (Implementation complete or Commit created)
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            """
            SELECT e.story_id, MAX(e.created_at) AS last_done_at
            FROM executions e
            WHERE e.command IN ('Implementation complete', 'Commit created')
            GROUP BY e.story_id
            """
        )
        completion_evidence = {row[0]: row[1] for row in cursor.fetchall()}

    if not completion_evidence:
        print("No stories with 'Implementation complete' or 'Commit created' in executions.")
        return 0

    # Among those, find ones that are not already completed/failed/skipped
    with db.get_connection() as conn:
        cursor = conn.cursor()
        placeholders = ",".join("?" * len(completion_evidence))
        cursor.execute(
            f"""
            SELECT id, project_id, story_number, title, status
            FROM stories
            WHERE id IN ({placeholders})
              AND status NOT IN ('completed', 'failed', 'skipped')
            """,
            list(completion_evidence.keys()),
        )
        to_update = cursor.fetchall()

    if args.project_id is not None:
        to_update = [r for r in to_update if r[1] == args.project_id]

    if not to_update:
        print("No pending/in_progress stories to mark as completed (all with evidence are already completed/failed/skipped).")
        return 0

    print(f"Found {len(to_update)} story(ies) with completion evidence but status not completed:")
    for r in to_update:
        story_id, project_id, story_number, title, status = r
        last_done = completion_evidence.get(story_id, "")
        print(f"  story_id={story_id} story_number={story_number} status={status!r} last_done={last_done}")

    if args.dry_run:
        print("\n[DRY RUN] No changes written. Run without --dry-run to apply.")
        return 0

    updated = 0
    project_ids = set()
    for r in to_update:
        story_id, project_id, story_number, title, status = r
        last_done = completion_evidence.get(story_id)
        completed_at = last_done if last_done else datetime.now().isoformat()
        if isinstance(completed_at, bytes):
            completed_at = completed_at.decode("utf-8")
        db.update_story(
            story_id,
            {
                "status": "completed",
                "completed_at": completed_at,
                "worker_id": None,
                "error_message": None,
                "error_logs": None,
            },
        )
        updated += 1
        project_ids.add(project_id)

    for pid in project_ids:
        db.update_project_stats(pid)

    print(f"\nUpdated {updated} story(ies) to status=completed and refreshed project stats.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
