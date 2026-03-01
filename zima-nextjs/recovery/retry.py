"""
Zima Looper - Retry Manager
Handles retry logic with exponential backoff and strategy selection
"""

import time
from typing import Dict, Optional, Tuple
from datetime import datetime
from enum import Enum


class RetryStrategy(Enum):
    """Retry strategy types"""
    IMMEDIATE = "immediate"           # Retry immediately (for transient errors)
    EXPONENTIAL_BACKOFF = "exponential"  # Exponential backoff (default)
    LINEAR_BACKOFF = "linear"         # Linear backoff (for rate limits)
    NO_RETRY = "no_retry"             # Don't retry (permanent errors)


class RetryDecision:
    """Decision about whether and how to retry"""

    def __init__(
        self,
        should_retry: bool,
        strategy: RetryStrategy,
        wait_seconds: int = 0,
        reason: str = ""
    ):
        self.should_retry = should_retry
        self.strategy = strategy
        self.wait_seconds = wait_seconds
        self.reason = reason


class RetryManager:
    """
    Manages retry logic with configurable strategies
    """

    def __init__(self, config):
        """
        Initialize retry manager

        Args:
            config: Configuration object
        """
        self.config = config
        self.max_retries = config.max_retry_attempts
        self.base_delay = config.base_delay_seconds
        self.backoff_multiplier = config.backoff_multiplier

    def should_retry(
        self,
        story: Dict,
        error_type: str,
        error_message: str
    ) -> RetryDecision:
        """
        Decide if story should be retried

        Args:
            story: Story dictionary
            error_type: Type of error (syntax, runtime, test_failure, timeout)
            error_message: Error message

        Returns:
            RetryDecision object
        """
        retry_count = story['retry_count']
        max_retries = story['max_retries']

        # Check if max retries reached
        if retry_count >= max_retries:
            return RetryDecision(
                should_retry=False,
                strategy=RetryStrategy.NO_RETRY,
                reason=f"Max retries ({max_retries}) reached"
            )

        # Determine strategy based on error type
        strategy = self._select_strategy(error_type, error_message)

        # Check if error is non-retryable
        if strategy == RetryStrategy.NO_RETRY:
            return RetryDecision(
                should_retry=False,
                strategy=strategy,
                reason=f"Non-retryable error: {error_type}"
            )

        # Calculate wait time
        wait_seconds = self._calculate_wait_time(retry_count + 1, strategy)

        return RetryDecision(
            should_retry=True,
            strategy=strategy,
            wait_seconds=wait_seconds,
            reason=f"Retry {retry_count + 1}/{max_retries}"
        )

    def _select_strategy(self, error_type: str, error_message: str) -> RetryStrategy:
        """
        Select retry strategy based on error type

        Args:
            error_type: Type of error
            error_message: Error message

        Returns:
            RetryStrategy
        """
        # Non-retryable errors
        non_retryable_patterns = [
            "invalid syntax",
            "authentication failed",
            "permission denied",
            "not found: claude",  # Claude CLI not installed
            "not found: agent",   # Cursor CLI not installed
            "no such file or directory" # Missing required files
        ]

        error_lower = error_message.lower() if error_message else ""

        for pattern in non_retryable_patterns:
            if pattern in error_lower:
                return RetryStrategy.NO_RETRY

        # Immediate retry for transient errors
        transient_patterns = [
            "connection reset",
            "timeout",
            "temporarily unavailable"
        ]

        for pattern in transient_patterns:
            if pattern in error_lower:
                return RetryStrategy.IMMEDIATE

        # Linear backoff for rate limits
        if "rate limit" in error_lower or "too many requests" in error_lower:
            return RetryStrategy.LINEAR_BACKOFF

        # Default: exponential backoff
        return RetryStrategy.EXPONENTIAL_BACKOFF

    def _calculate_wait_time(self, retry_attempt: int, strategy: RetryStrategy) -> int:
        """
        Calculate wait time based on retry attempt and strategy

        Args:
            retry_attempt: Current retry attempt (1-based)
            strategy: Retry strategy

        Returns:
            Wait time in seconds
        """
        if strategy == RetryStrategy.IMMEDIATE:
            return 0

        if strategy == RetryStrategy.LINEAR_BACKOFF:
            # Linear: 10s, 20s, 30s
            return self.base_delay * 2 * retry_attempt

        if strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            # Exponential: 5s, 15s, 45s (with multiplier=3)
            return int(self.base_delay * (self.backoff_multiplier ** (retry_attempt - 1)))

        return 0

    def execute_retry(
        self,
        decision: RetryDecision,
        on_wait_callback=None
    ) -> bool:
        """
        Execute retry with wait time

        Args:
            decision: RetryDecision object
            on_wait_callback: Optional callback during wait (for progress updates)

        Returns:
            True if should proceed with retry
        """
        if not decision.should_retry:
            return False

        if decision.wait_seconds > 0:
            if on_wait_callback:
                on_wait_callback(decision.wait_seconds)

            time.sleep(decision.wait_seconds)

        return True

    def get_retry_stats(self, db, story_id: int) -> Dict:
        """
        Get retry statistics for a story

        Args:
            db: Database instance
            story_id: Story ID

        Returns:
            Statistics dictionary
        """
        story = db.get_story(story_id)
        if not story:
            return {}

        executions = db.get_story_executions(story_id, limit=100)

        # Count failures by type
        failure_types = {}
        for execution in executions:
            if execution['exit_code'] != 0:
                exec_type = execution['execution_type']
                failure_types[exec_type] = failure_types.get(exec_type, 0) + 1

        return {
            'story_id': story_id,
            'total_retries': story['retry_count'],
            'max_retries': story['max_retries'],
            'retries_remaining': story['max_retries'] - story['retry_count'],
            'failure_types': failure_types,
            'total_executions': len(executions)
        }

    def format_retry_message(self, decision: RetryDecision, retry_count: int) -> str:
        """
        Format human-readable retry message

        Args:
            decision: RetryDecision object
            retry_count: Current retry count

        Returns:
            Formatted message string
        """
        if not decision.should_retry:
            return f"❌ {decision.reason}"

        strategy_name = decision.strategy.value.replace('_', ' ').title()

        if decision.wait_seconds > 0:
            return f"🔄 Retry {retry_count} using {strategy_name} (waiting {decision.wait_seconds}s)"
        else:
            return f"🔄 Retry {retry_count} using {strategy_name}"


class RetryHistory:
    """Track retry history for learning and optimization"""

    def __init__(self, db):
        self.db = db

    def record_retry_outcome(
        self,
        story_id: int,
        retry_attempt: int,
        strategy: RetryStrategy,
        success: bool,
        error_type: Optional[str] = None
    ):
        """
        Record outcome of retry attempt

        Args:
            story_id: Story ID
            retry_attempt: Retry attempt number
            strategy: Strategy used
            success: Whether retry succeeded
            error_type: Type of error (if failed)
        """
        self.db.log_execution(
            story_id=story_id,
            execution_type='retry',
            command=f"Retry attempt {retry_attempt} using {strategy.value}",
            output=f"Success: {success}, Error type: {error_type or 'N/A'}",
            exit_code=0 if success else 1
        )

    def get_success_rate_by_strategy(self, project_id: int) -> Dict:
        """
        Get success rate for each retry strategy

        Args:
            project_id: Project ID

        Returns:
            Dictionary of strategy -> success rate
        """
        stories = self.db.get_project_stories(project_id)

        strategy_stats = {
            'exponential': {'success': 0, 'total': 0},
            'linear': {'success': 0, 'total': 0},
            'immediate': {'success': 0, 'total': 0}
        }

        for story in stories:
            if story['retry_count'] > 0:
                # Simple heuristic: assume exponential by default
                strategy = 'exponential'

                strategy_stats[strategy]['total'] += story['retry_count']

                if story['status'] == 'completed':
                    strategy_stats[strategy]['success'] += 1

        # Calculate rates
        rates = {}
        for strategy, stats in strategy_stats.items():
            if stats['total'] > 0:
                rates[strategy] = (stats['success'] / stats['total']) * 100
            else:
                rates[strategy] = 0

        return rates

    def get_optimal_max_retries(self, project_id: int) -> int:
        """
        Suggest optimal max retries based on project history

        Args:
            project_id: Project ID

        Returns:
            Suggested max retries
        """
        stories = self.db.get_project_stories(project_id)

        # Count how many retries were needed for successful stories
        retry_counts = []
        for story in stories:
            if story['status'] == 'completed' and story['retry_count'] > 0:
                retry_counts.append(story['retry_count'])

        if not retry_counts:
            return 3  # Default

        # Use 90th percentile
        retry_counts.sort()
        percentile_90_index = int(len(retry_counts) * 0.9)

        return min(retry_counts[percentile_90_index], 5)  # Cap at 5
