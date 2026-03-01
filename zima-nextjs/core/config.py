"""
Zima Looper - Configuration Loader
Loads and validates configuration from config.yaml
"""

import yaml
import os
from typing import Dict, Any
from dataclasses import dataclass, field


@dataclass
class ZimaConfig:
    """Configuration data class for Zima Looper"""

    # Zima info
    version: str = "1.0.0"
    name: str = "Zima Looper"

    # Worker settings
    worker_count: int = 4
    max_concurrent_stories: int = 4
    poll_interval_seconds: int = 5

    # Memory limit: cap per-worker RAM (disabled by default - can cause workers to get stuck/killed)
    memory_limit_enabled: bool = False
    memory_limit_percent: float = 70.0

    # Cursor CLI (agent) path
    claude_cli_path: str = "agent"
    default_timeout_seconds: int = 300
    max_timeout_seconds: int = 900
    claude_model: str = "sonnet"

    # Retry settings
    max_retry_attempts: int = 3
    backoff_multiplier: int = 3
    base_delay_seconds: int = 5
    enable_claude_fix: bool = True

    # Checkpoint settings
    checkpoints_enabled: bool = True
    checkpoint_frequency_minutes: int = 5
    max_checkpoints_per_story: int = 10

    # Git settings
    git_auto_commit: bool = True
    git_commit_message_template: str = "Story {story_id}: {title}"
    git_use_branches: bool = True
    git_branch_prefix: str = "zima/story-"

    # Quality gates
    run_tests_before_complete: bool = True
    require_passing_tests: bool = False
    # Flutter
    run_flutter_analyze: bool = True
    run_flutter_build: bool = True
    flutter_build_target: str = "apk"
    # Next.js
    run_linter: bool = False  # set False to save RAM (ESLint can be heavy)
    run_npm_build: bool = True  # set False to save RAM (Next.js build is very heavy)

    # Monitoring
    dashboard_enabled: bool = True
    dashboard_port: int = 5000
    log_level: str = "INFO"
    metrics_enabled: bool = True

    # Notifications
    console_notifications: bool = True
    web_notifications: bool = True

    # Do not create .md / docs unless story explicitly asks
    skip_documentation: bool = True

    # Shared context: inject "already done" summary into prompts (fewer tokens, less duplicate work)
    shared_context_enabled: bool = True
    shared_context_max_stories: int = 15
    shared_context_max_chars: int = 1500
    shared_context_recent_changes_limit: int = 20
    shared_context_recent_changes_max_chars: int = 500
    shared_context_avoid_files_max: int = 30

    # Token optimization (reduce LLM usage)
    max_acceptance_criteria_items: int = 25
    max_acceptance_criteria_chars: int = 4000
    max_error_log_chars: int = 600
    max_error_context_lines: int = 15
    max_readme_chars: int = 6000
    prd_analysis_readme_chars: int = 5000
    prd_stories_readme_chars: int = 4000


def load_config(config_path: str = None) -> ZimaConfig:
    """
    Load configuration from YAML file

    Args:
        config_path: Path to config.yaml file. If None, uses default location.

    Returns:
        ZimaConfig object
    """
    if config_path is None:
        # Default: scripts/zima/config.yaml
        config_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            "config.yaml"
        )

    if not os.path.exists(config_path):
        print(f"Warning: Config file not found at {config_path}. Using defaults.")
        return ZimaConfig()

    try:
        with open(config_path, 'r') as f:
            config_data = yaml.safe_load(f)

        return ZimaConfig(
            # Zima info
            version=config_data.get('zima', {}).get('version', '1.0.0'),
            name=config_data.get('zima', {}).get('name', 'Zima Looper'),

            # Workers
            worker_count=config_data.get('workers', {}).get('count', 4),
            max_concurrent_stories=config_data.get('workers', {}).get('max_concurrent_stories', 4),
            poll_interval_seconds=config_data.get('workers', {}).get('poll_interval_seconds', 5),
            memory_limit_enabled=config_data.get('workers', {}).get('memory_limit', {}).get('enabled', False),
            memory_limit_percent=float(config_data.get('workers', {}).get('memory_limit', {}).get('max_percent', 70)),

            # Claude
            claude_cli_path=config_data.get('claude', {}).get('cli_path', 'agent'),
            default_timeout_seconds=config_data.get('claude', {}).get('default_timeout_seconds', 300),
            max_timeout_seconds=config_data.get('claude', {}).get('max_timeout_seconds', 900),
            claude_model=config_data.get('claude', {}).get('model', 'sonnet'),

            # Retry
            max_retry_attempts=config_data.get('retry', {}).get('max_attempts', 3),
            backoff_multiplier=config_data.get('retry', {}).get('backoff_multiplier', 3),
            base_delay_seconds=config_data.get('retry', {}).get('base_delay_seconds', 5),
            enable_claude_fix=config_data.get('retry', {}).get('enable_claude_fix', True),

            # Checkpoints
            checkpoints_enabled=config_data.get('checkpoints', {}).get('enabled', True),
            checkpoint_frequency_minutes=config_data.get('checkpoints', {}).get('frequency_minutes', 5),
            max_checkpoints_per_story=config_data.get('checkpoints', {}).get('max_checkpoints_per_story', 10),

            # Git
            git_auto_commit=config_data.get('git', {}).get('auto_commit', True),
            git_commit_message_template=config_data.get('git', {}).get('commit_message_template', 'Story {story_id}: {title}'),
            git_use_branches=config_data.get('git', {}).get('use_branches', True),
            git_branch_prefix=config_data.get('git', {}).get('branch_prefix', 'zima/story-'),

            # Quality
            run_tests_before_complete=config_data.get('quality', {}).get('run_tests_before_complete', True),
            require_passing_tests=config_data.get('quality', {}).get('require_passing_tests', False),
            run_flutter_analyze=config_data.get('quality', {}).get('run_flutter_analyze', True),
            run_flutter_build=config_data.get('quality', {}).get('run_flutter_build', True),
            flutter_build_target=config_data.get('quality', {}).get('flutter_build_target', 'apk'),
            run_linter=config_data.get('quality', {}).get('run_linter', False),
            run_npm_build=config_data.get('quality', {}).get('run_npm_build', True),

            # Monitoring
            dashboard_enabled=config_data.get('monitoring', {}).get('dashboard_enabled', True),
            dashboard_port=config_data.get('monitoring', {}).get('dashboard_port', 5000),
            log_level=config_data.get('monitoring', {}).get('log_level', 'INFO'),
            metrics_enabled=config_data.get('monitoring', {}).get('metrics_enabled', True),

            # Notifications
            console_notifications=config_data.get('notifications', {}).get('console_enabled', True),
            web_notifications=config_data.get('notifications', {}).get('web_enabled', True),

            # Behavior
            skip_documentation=config_data.get('behavior', {}).get('skip_documentation', True),

            # Shared context (workers share "already done" to reduce tokens)
            shared_context_enabled=config_data.get('shared_context', {}).get('enabled', True),
            shared_context_max_stories=config_data.get('shared_context', {}).get('max_recent_stories', 15),
            shared_context_max_chars=config_data.get('shared_context', {}).get('max_summary_chars', 1500),
            shared_context_recent_changes_limit=config_data.get('shared_context', {}).get('recent_changes_limit', 20),
            shared_context_recent_changes_max_chars=config_data.get('shared_context', {}).get('recent_changes_max_chars', 500),
            shared_context_avoid_files_max=config_data.get('shared_context', {}).get('avoid_files_max', 30),

            # Token optimization
            max_acceptance_criteria_items=config_data.get('token_optimization', {}).get('max_acceptance_criteria_items', 25),
            max_acceptance_criteria_chars=config_data.get('token_optimization', {}).get('max_acceptance_criteria_chars', 4000),
            max_error_log_chars=config_data.get('token_optimization', {}).get('max_error_log_chars', 600),
            max_error_context_lines=config_data.get('token_optimization', {}).get('max_error_context_lines', 15),
            max_readme_chars=config_data.get('token_optimization', {}).get('max_readme_chars', 6000),
            prd_analysis_readme_chars=config_data.get('token_optimization', {}).get('prd_analysis_readme_chars', 5000),
            prd_stories_readme_chars=config_data.get('token_optimization', {}).get('prd_stories_readme_chars', 4000),
        )

    except Exception as e:
        print(f"Error loading config: {e}")
        print("Using default configuration.")
        return ZimaConfig()


# Singleton instance
_config_instance = None

def get_config(config_path: str = None) -> ZimaConfig:
    """Get or create config singleton"""
    global _config_instance
    if _config_instance is None:
        _config_instance = load_config(config_path)
    return _config_instance
