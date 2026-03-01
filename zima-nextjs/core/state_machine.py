"""
Zima Looper - Story State Machine
Manages story lifecycle and state transitions
"""

from typing import Optional, Dict, List, Tuple
from enum import Enum
from datetime import datetime


class StoryStatus(Enum):
    """Story status enumeration"""
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    PLANNING = "planning"
    IMPLEMENTING = "implementing"
    TESTING = "testing"
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"


class StateTransition:
    """Valid state transitions"""
    TRANSITIONS = {
        StoryStatus.PENDING: [StoryStatus.IN_PROGRESS, StoryStatus.SKIPPED],
        StoryStatus.IN_PROGRESS: [StoryStatus.PLANNING, StoryStatus.IMPLEMENTING, StoryStatus.FAILED],
        StoryStatus.PLANNING: [StoryStatus.IMPLEMENTING, StoryStatus.FAILED],
        StoryStatus.IMPLEMENTING: [StoryStatus.TESTING, StoryStatus.FAILED],
        StoryStatus.TESTING: [StoryStatus.COMPLETED, StoryStatus.FAILED],
        StoryStatus.FAILED: [StoryStatus.IN_PROGRESS, StoryStatus.SKIPPED],  # Retry or skip
        StoryStatus.COMPLETED: [],  # Terminal state
        StoryStatus.SKIPPED: []  # Terminal state
    }


class StoryStateMachine:
    """
    State machine for managing story lifecycle
    """

    def __init__(self, db):
        """
        Initialize state machine

        Args:
            db: Database instance
        """
        self.db = db

    def can_transition(self, current_status: str, new_status: str) -> bool:
        """
        Check if transition is valid

        Args:
            current_status: Current story status
            new_status: Desired new status

        Returns:
            True if transition is valid
        """
        try:
            current = StoryStatus(current_status)
            new = StoryStatus(new_status)

            valid_transitions = StateTransition.TRANSITIONS.get(current, [])
            return new in valid_transitions

        except ValueError:
            return False

    def transition(self, story_id: int, new_status: str, error_message: Optional[str] = None) -> bool:
        """
        Transition story to new status

        Args:
            story_id: Story ID
            new_status: New status
            error_message: Optional error message for failed transitions

        Returns:
            True if transition successful
        """
        # Get current story
        story = self.db.get_story(story_id)
        if not story:
            return False

        current_status = story['status']

        if current_status == new_status:
            return True

        # Check if transition is valid
        if not self.can_transition(current_status, new_status):
            print(f"Invalid transition: {current_status} → {new_status}")
            return False

        # Update story status
        updates = {'status': new_status}

        # Set timestamps
        if new_status == StoryStatus.IN_PROGRESS.value:
            updates['started_at'] = datetime.now().isoformat()

        if new_status in [StoryStatus.COMPLETED.value, StoryStatus.FAILED.value, StoryStatus.SKIPPED.value]:
            updates['completed_at'] = datetime.now().isoformat()
            updates['worker_id'] = None  # Release worker so counts and active_workers are correct

        # Set error message for failed transitions
        if new_status == StoryStatus.FAILED.value and error_message:
            updates['error_message'] = error_message

        # Increment retry count if transitioning from FAILED to IN_PROGRESS
        if current_status == StoryStatus.FAILED.value and new_status == StoryStatus.IN_PROGRESS.value:
            updates['retry_count'] = story['retry_count'] + 1

        # Update database
        self.db.update_story(story_id, updates)

        return True

    def get_valid_next_states(self, story_id: int) -> List[str]:
        """
        Get list of valid next states for story

        Args:
            story_id: Story ID

        Returns:
            List of valid status strings
        """
        story = self.db.get_story(story_id)
        if not story:
            return []

        try:
            current = StoryStatus(story['status'])
            valid_transitions = StateTransition.TRANSITIONS.get(current, [])
            return [status.value for status in valid_transitions]
        except ValueError:
            return []

    def can_retry(self, story_id: int) -> bool:
        """
        Check if story can be retried

        Args:
            story_id: Story ID

        Returns:
            True if story can be retried
        """
        story = self.db.get_story(story_id)
        if not story:
            return False

        return (
            story['status'] == StoryStatus.FAILED.value and
            story['retry_count'] < story['max_retries']
        )

    def should_skip(self, story_id: int) -> bool:
        """
        Check if story should be skipped (max retries reached)

        Args:
            story_id: Story ID

        Returns:
            True if story should be skipped
        """
        story = self.db.get_story(story_id)
        if not story:
            return False

        return (
            story['status'] == StoryStatus.FAILED.value and
            story['retry_count'] >= story['max_retries']
        )

    def get_story_progress(self, story_id: int) -> Dict:
        """
        Get story execution progress

        Args:
            story_id: Story ID

        Returns:
            Progress dictionary with status, duration, etc.
        """
        story = self.db.get_story(story_id)
        if not story:
            return {}

        progress = {
            'story_id': story_id,
            'status': story['status'],
            'retry_count': story['retry_count'],
            'max_retries': story['max_retries'],
            'can_retry': self.can_retry(story_id),
            'should_skip': self.should_skip(story_id)
        }

        # Calculate duration
        if story['started_at'] and story['completed_at']:
            try:
                start = datetime.fromisoformat(story['started_at'])
                end = datetime.fromisoformat(story['completed_at'])
                progress['duration_seconds'] = (end - start).total_seconds()
            except:
                progress['duration_seconds'] = None
        elif story['started_at']:
            try:
                start = datetime.fromisoformat(story['started_at'])
                now = datetime.now()
                progress['elapsed_seconds'] = (now - start).total_seconds()
            except:
                progress['elapsed_seconds'] = None

        return progress

    def get_project_progress(self, project_id: int) -> Dict:
        """
        Get overall project progress

        Args:
            project_id: Project ID

        Returns:
            Progress dictionary with counts and percentages
        """
        project = self.db.get_project(project_id)
        stories = self.db.get_project_stories(project_id)

        if not project or not stories:
            return {}

        # Count stories by status
        status_counts = {
            'pending': 0,
            'in_progress': 0,
            'completed': 0,
            'failed': 0,
            'skipped': 0
        }

        for story in stories:
            status = story['status']
            if status in status_counts:
                status_counts[status] += 1
            elif status in ['planning', 'implementing', 'testing']:
                status_counts['in_progress'] += 1

        total = len(stories)
        completed = status_counts['completed']
        failed = status_counts['failed']

        return {
            'project_id': project_id,
            'project_name': project['name'],
            'total_stories': total,
            'completed_stories': completed,
            'failed_stories': failed,
            'skipped_stories': status_counts['skipped'],
            'in_progress_stories': status_counts['in_progress'],
            'pending_stories': status_counts['pending'],
            'completion_percentage': (completed / total * 100) if total > 0 else 0,
            'success_rate': (completed / (completed + failed) * 100) if (completed + failed) > 0 else 0
        }

    def validate_story_state(self, story_id: int) -> Tuple[bool, str]:
        """
        Validate story state is consistent

        Args:
            story_id: Story ID

        Returns:
            (is_valid, error_message)
        """
        story = self.db.get_story(story_id)
        if not story:
            return False, "Story not found"

        # Check status is valid
        try:
            StoryStatus(story['status'])
        except ValueError:
            return False, f"Invalid status: {story['status']}"

        # Check retry count doesn't exceed max
        if story['retry_count'] > story['max_retries']:
            return False, f"Retry count ({story['retry_count']}) exceeds max ({story['max_retries']})"

        # Check timestamps are consistent
        if story['started_at'] and story['completed_at']:
            try:
                start = datetime.fromisoformat(story['started_at'])
                end = datetime.fromisoformat(story['completed_at'])
                if end < start:
                    return False, "completed_at is before started_at"
            except:
                return False, "Invalid timestamp format"

        # Check worker assignment
        if story['status'] in ['in_progress', 'planning', 'implementing', 'testing']:
            if not story['worker_id']:
                return False, f"Story is {story['status']} but no worker assigned"

        return True, "Valid"
