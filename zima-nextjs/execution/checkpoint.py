"""
Zima Looper - Checkpoint System
Save and restore story execution state for recovery
"""

import subprocess
import json
from typing import Dict, List, Optional, Set
from pathlib import Path
from datetime import datetime


class CheckpointManager:
    """
    Manages checkpoints for story execution
    Enables rollback on failure and resume from last good state
    """

    def __init__(self, db, project_dir: str):
        """
        Initialize checkpoint manager

        Args:
            db: Database instance
            project_dir: Project directory path
        """
        self.db = db
        self.project_dir = Path(project_dir)

    def create_checkpoint(
        self,
        story_id: int,
        checkpoint_type: str,
        data: Optional[Dict] = None,
        files_modified: Optional[List[str]] = None
    ) -> int:
        """
        Create a checkpoint for story

        Args:
            story_id: Story ID
            checkpoint_type: Type of checkpoint (plan, implementation, test, commit)
            data: Optional data to store with checkpoint
            files_modified: List of file paths modified since last checkpoint

        Returns:
            Checkpoint ID
        """
        # Get current git SHA
        git_sha = self._get_git_sha()

        # Get modified files if not provided
        if files_modified is None:
            files_modified = self._get_modified_files()

        # Save checkpoint to database
        checkpoint_id = self.db.create_checkpoint(
            story_id=story_id,
            checkpoint_type=checkpoint_type,
            data=json.dumps(data) if data else None,
            files_modified=json.dumps(files_modified),
            git_sha=git_sha
        )

        return checkpoint_id

    def get_story_checkpoints(self, story_id: int) -> List[Dict]:
        """
        Get all checkpoints for a story

        Args:
            story_id: Story ID

        Returns:
            List of checkpoint dictionaries
        """
        return self.db.get_story_checkpoints(story_id)

    def get_latest_checkpoint(self, story_id: int) -> Optional[Dict]:
        """
        Get latest checkpoint for story

        Args:
            story_id: Story ID

        Returns:
            Checkpoint dictionary or None
        """
        checkpoints = self.db.get_story_checkpoints(story_id)
        if not checkpoints:
            return None

        # Return most recent
        latest = checkpoints[0]

        # Parse JSON fields
        if latest['data']:
            try:
                latest['data'] = json.loads(latest['data'])
            except:
                pass

        if latest['files_modified']:
            try:
                latest['files_modified'] = json.loads(latest['files_modified'])
            except:
                latest['files_modified'] = []

        return latest

    def get_checkpoint(self, checkpoint_id: int) -> Optional[Dict]:
        """
        Get specific checkpoint

        Args:
            checkpoint_id: Checkpoint ID

        Returns:
            Checkpoint dictionary or None
        """
        checkpoint = self.db.get_checkpoint(checkpoint_id)
        if not checkpoint:
            return None

        # Parse JSON fields
        if checkpoint['data']:
            try:
                checkpoint['data'] = json.loads(checkpoint['data'])
            except:
                pass

        if checkpoint['files_modified']:
            try:
                checkpoint['files_modified'] = json.loads(checkpoint['files_modified'])
            except:
                checkpoint['files_modified'] = []

        return checkpoint

    def restore_checkpoint(self, checkpoint_id: int) -> bool:
        """
        Restore to checkpoint (rollback changes)

        Args:
            checkpoint_id: Checkpoint ID

        Returns:
            True if restore successful
        """
        checkpoint = self.get_checkpoint(checkpoint_id)
        if not checkpoint:
            return False

        git_sha = checkpoint['git_sha']
        if not git_sha:
            print("Warning: No git SHA in checkpoint, cannot restore")
            return False

        # Restore git state
        success = self._restore_git_state(git_sha)

        if success:
            print(f"✓ Restored to checkpoint {checkpoint_id} (git SHA: {git_sha[:8]})")

        return success

    def rollback_to_last_checkpoint(self, story_id: int) -> bool:
        """
        Rollback to last checkpoint for story

        Args:
            story_id: Story ID

        Returns:
            True if rollback successful
        """
        # DISABLED: Git rollback corrupts database by deleting zima.db
        # Even though zima.db is in .gitignore, git reset --hard removes it
        print("⚠️  Checkpoint rollback disabled to prevent database corruption")
        return True

        # Original code below (disabled):
        # checkpoint = self.get_latest_checkpoint(story_id)
        # if not checkpoint:
        #     print(f"No checkpoints found for story {story_id}")
        #     return False
        # return self.restore_checkpoint(checkpoint['id'])

    def create_commit_checkpoint(self, story_id: int, commit_message: str) -> Optional[int]:
        """
        Create git commit and checkpoint

        Args:
            story_id: Story ID
            commit_message: Commit message

        Returns:
            Checkpoint ID or None if commit failed
        """
        # Get modified files
        modified_files = self._get_modified_files()

        if not modified_files:
            print("No files modified, skipping commit")
            return None

        # Stage all changes
        try:
            subprocess.run(
                ['git', 'add', '.'],
                cwd=self.project_dir,
                check=True,
                capture_output=True
            )
        except subprocess.CalledProcessError as e:
            print(f"Failed to stage files: {e.stderr.decode()}")
            return None

        # Create commit
        try:
            result = subprocess.run(
                ['git', 'commit', '-m', commit_message],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True
            )

            # Create checkpoint with new commit SHA
            checkpoint_id = self.create_checkpoint(
                story_id=story_id,
                checkpoint_type='commit',
                data={'commit_message': commit_message, 'commit_output': result.stdout},
                files_modified=modified_files
            )

            print(f"✓ Committed: {commit_message}")
            return checkpoint_id

        except subprocess.CalledProcessError as e:
            print(f"Failed to commit: {e.stderr.decode()}")
            return None

    def _get_git_sha(self) -> Optional[str]:
        """
        Get current git SHA

        Returns:
            Git SHA string or None
        """
        try:
            result = subprocess.run(
                ['git', 'rev-parse', 'HEAD'],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True
            )
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            return None

    def _get_modified_files(self) -> List[str]:
        """
        Get list of modified files in working directory

        Returns:
            List of file paths
        """
        try:
            # Get staged files
            result_staged = subprocess.run(
                ['git', 'diff', '--name-only', '--cached'],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True
            )

            # Get unstaged files
            result_unstaged = subprocess.run(
                ['git', 'diff', '--name-only'],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True
            )

            # Get untracked files
            result_untracked = subprocess.run(
                ['git', 'ls-files', '--others', '--exclude-standard'],
                cwd=self.project_dir,
                check=True,
                capture_output=True,
                text=True
            )

            # Combine and deduplicate
            files: Set[str] = set()
            for result in [result_staged, result_unstaged, result_untracked]:
                if result.stdout.strip():
                    files.update(result.stdout.strip().split('\n'))

            return sorted(list(files))

        except subprocess.CalledProcessError:
            return []

    def _restore_git_state(self, git_sha: str) -> bool:
        """
        Restore git working directory to specific SHA

        Args:
            git_sha: Git commit SHA

        Returns:
            True if restore successful
        """
        try:
            # Reset to SHA (keep working directory)
            subprocess.run(
                ['git', 'reset', '--hard', git_sha],
                cwd=self.project_dir,
                check=True,
                capture_output=True
            )

            # Clean untracked files
            subprocess.run(
                ['git', 'clean', '-fd'],
                cwd=self.project_dir,
                check=True,
                capture_output=True
            )

            return True

        except subprocess.CalledProcessError as e:
            print(f"Failed to restore git state: {e.stderr.decode()}")
            return False

    def list_checkpoints(self, story_id: int) -> List[Dict]:
        """
        List all checkpoints for story

        Args:
            story_id: Story ID

        Returns:
            List of checkpoint dictionaries
        """
        checkpoints = self.db.get_story_checkpoints(story_id)

        # Parse JSON fields
        for checkpoint in checkpoints:
            if checkpoint['data']:
                try:
                    checkpoint['data'] = json.loads(checkpoint['data'])
                except:
                    pass

            if checkpoint['files_modified']:
                try:
                    checkpoint['files_modified'] = json.loads(checkpoint['files_modified'])
                except:
                    checkpoint['files_modified'] = []

        return checkpoints

    def cleanup_old_checkpoints(self, story_id: int, keep_last: int = 5):
        """
        Remove old checkpoints, keeping only most recent

        Args:
            story_id: Story ID
            keep_last: Number of checkpoints to keep
        """
        checkpoints = self.db.get_story_checkpoints(story_id)

        if len(checkpoints) <= keep_last:
            return

        # Delete old checkpoints
        to_delete = checkpoints[keep_last:]
        for checkpoint in to_delete:
            self.db.delete_checkpoint(checkpoint['id'])

        print(f"✓ Cleaned up {len(to_delete)} old checkpoints for story {story_id}")

    def get_checkpoint_summary(self, story_id: int) -> str:
        """
        Get human-readable summary of checkpoints

        Args:
            story_id: Story ID

        Returns:
            Summary string
        """
        checkpoints = self.list_checkpoints(story_id)

        if not checkpoints:
            return f"No checkpoints for story {story_id}"

        lines = [f"Checkpoints for story {story_id}:"]
        for i, cp in enumerate(checkpoints[:10], 1):  # Show last 10
            timestamp = cp['created_at']
            cp_type = cp['checkpoint_type']
            git_sha = cp['git_sha'][:8] if cp['git_sha'] else 'N/A'
            files_count = len(cp.get('files_modified', []))

            lines.append(f"  {i}. [{cp_type}] {timestamp} (SHA: {git_sha}, {files_count} files)")

        if len(checkpoints) > 10:
            lines.append(f"  ... and {len(checkpoints) - 10} more")

        return '\n'.join(lines)
