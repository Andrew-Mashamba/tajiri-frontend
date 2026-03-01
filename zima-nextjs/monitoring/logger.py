"""
Zima Looper - Structured Logging
Rich console logging with file output
"""

import os
import sys
import logging
from datetime import datetime
from typing import Optional
from enum import Enum

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from rich.console import Console
from rich.logging import RichHandler
from rich.theme import Theme


class LogLevel(Enum):
    """Log levels"""
    DEBUG = "DEBUG"
    INFO = "INFO"
    WARNING = "WARNING"
    ERROR = "ERROR"
    CRITICAL = "CRITICAL"


class ZimaLogger:
    """
    Structured logger with rich console output and file logging
    """

    def __init__(
        self,
        name: str = "zima",
        log_file: Optional[str] = None,
        level: str = "INFO"
    ):
        """
        Initialize logger

        Args:
            name: Logger name
            log_file: Optional log file path
            level: Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
        """
        self.name = name
        self.log_file = log_file

        # Create rich console with custom theme
        custom_theme = Theme({
            "info": "cyan",
            "warning": "yellow",
            "error": "red bold",
            "success": "green bold"
        })
        self.console = Console(theme=custom_theme)

        # Setup Python logger
        self.logger = logging.getLogger(name)
        self.logger.setLevel(getattr(logging, level.upper()))

        # Clear existing handlers
        self.logger.handlers = []

        # Add rich console handler
        console_handler = RichHandler(
            console=self.console,
            rich_tracebacks=True,
            tracebacks_show_locals=True
        )
        console_handler.setLevel(getattr(logging, level.upper()))
        self.logger.addHandler(console_handler)

        # Add file handler if log file specified
        if log_file:
            # Ensure log directory exists
            log_dir = os.path.dirname(log_file)
            if log_dir and not os.path.exists(log_dir):
                os.makedirs(log_dir)

            file_handler = logging.FileHandler(log_file)
            file_handler.setLevel(logging.DEBUG)  # Log everything to file
            file_formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S'
            )
            file_handler.setFormatter(file_formatter)
            self.logger.addHandler(file_handler)

    def debug(self, message: str, **kwargs):
        """Log debug message"""
        self.logger.debug(message, extra=kwargs)

    def info(self, message: str, **kwargs):
        """Log info message"""
        self.logger.info(message, extra=kwargs)

    def warning(self, message: str, **kwargs):
        """Log warning message"""
        self.logger.warning(message, extra=kwargs)

    def error(self, message: str, **kwargs):
        """Log error message"""
        self.logger.error(message, extra=kwargs)

    def critical(self, message: str, **kwargs):
        """Log critical message"""
        self.logger.critical(message, extra=kwargs)

    def success(self, message: str):
        """Log success message (custom)"""
        self.console.print(f"[success]✅ {message}[/success]")
        self.logger.info(f"SUCCESS: {message}")

    def progress(self, message: str):
        """Log progress message (custom)"""
        self.console.print(f"[info]⚡ {message}[/info]")
        self.logger.info(f"PROGRESS: {message}")

    def section(self, title: str):
        """Log section header"""
        separator = "=" * 60
        self.console.print(f"\n[cyan]{separator}[/cyan]")
        self.console.print(f"[cyan bold]{title}[/cyan bold]")
        self.console.print(f"[cyan]{separator}[/cyan]\n")
        self.logger.info(f"SECTION: {title}")

    def story_start(self, story_number: int, title: str):
        """Log story execution start"""
        self.console.print(f"\n[cyan]{'='*60}[/cyan]")
        self.console.print(f"[cyan bold]📖 Story {story_number}: {title}[/cyan bold]")
        self.console.print(f"[cyan]{'='*60}[/cyan]\n")
        self.logger.info(f"STORY_START: #{story_number} - {title}")

    def story_complete(self, story_number: int, title: str):
        """Log story completion"""
        self.console.print(f"\n[success]✅ Story {story_number} completed: {title}[/success]\n")
        self.logger.info(f"STORY_COMPLETE: #{story_number} - {title}")

    def story_failed(self, story_number: int, title: str, error: str):
        """Log story failure"""
        self.console.print(f"\n[error]❌ Story {story_number} failed: {title}[/error]")
        self.console.print(f"[error]Error: {error}[/error]\n")
        self.logger.error(f"STORY_FAILED: #{story_number} - {title} - {error}")

    def worker_start(self, worker_id: int):
        """Log worker start"""
        self.console.print(f"[cyan]⚙️  Worker #{worker_id} started[/cyan]")
        self.logger.info(f"WORKER_START: #{worker_id}")

    def worker_stop(self, worker_id: int):
        """Log worker stop"""
        self.console.print(f"[yellow]⚙️  Worker #{worker_id} stopped[/yellow]")
        self.logger.info(f"WORKER_STOP: #{worker_id}")

    def worker_error(self, worker_id: int, error: str):
        """Log worker error"""
        self.console.print(f"[error]⚠️  Worker #{worker_id} error: {error}[/error]")
        self.logger.error(f"WORKER_ERROR: #{worker_id} - {error}")

    def execution_phase(self, phase: str):
        """Log execution phase"""
        self.console.print(f"[cyan]→ Phase: {phase}[/cyan]")
        self.logger.info(f"PHASE: {phase}")

    def checkpoint(self, checkpoint_type: str):
        """Log checkpoint"""
        self.console.print(f"[cyan]💾 Checkpoint: {checkpoint_type}[/cyan]")
        self.logger.info(f"CHECKPOINT: {checkpoint_type}")

    def retry(self, attempt: int, max_attempts: int):
        """Log retry attempt"""
        self.console.print(f"[yellow]🔄 Retry attempt {attempt}/{max_attempts}[/yellow]")
        self.logger.warning(f"RETRY: attempt {attempt}/{max_attempts}")

    def dependency_wait(self, story_number: int, depends_on: list):
        """Log dependency wait"""
        deps_str = ", ".join(f"Story {n}" for n in depends_on)
        self.console.print(f"[yellow]⏳ Story {story_number} waiting for: {deps_str}[/yellow]")
        self.logger.info(f"DEPENDENCY_WAIT: Story {story_number} <- {deps_str}")

    def metrics(self, metrics_dict: dict):
        """Log metrics"""
        self.console.print("\n[cyan]📊 Metrics:[/cyan]")
        for key, value in metrics_dict.items():
            if isinstance(value, float):
                self.console.print(f"  {key}: {value:.2f}")
            else:
                self.console.print(f"  {key}: {value}")
        self.logger.info(f"METRICS: {metrics_dict}")

    def table(self, title: str, rows: list):
        """Log table (using rich)"""
        from rich.table import Table

        table = Table(title=title)

        if not rows:
            return

        # Add columns from first row
        for col in rows[0].keys():
            table.add_column(col, style="cyan")

        # Add rows
        for row in rows:
            table.add_row(*[str(v) for v in row.values()])

        self.console.print(table)


# Global logger instance
_global_logger: Optional[ZimaLogger] = None


def get_logger(
    name: str = "zima",
    log_file: Optional[str] = None,
    level: str = "INFO"
) -> ZimaLogger:
    """
    Get or create global logger instance

    Args:
        name: Logger name
        log_file: Optional log file path
        level: Log level

    Returns:
        ZimaLogger instance
    """
    global _global_logger

    if _global_logger is None:
        _global_logger = ZimaLogger(name, log_file, level)

    return _global_logger


def setup_logging(
    log_dir: str = "./logs",
    level: str = "INFO"
) -> ZimaLogger:
    """
    Setup logging with default configuration

    Args:
        log_dir: Directory for log files
        level: Log level

    Returns:
        ZimaLogger instance
    """
    # Create log directory
    if not os.path.exists(log_dir):
        os.makedirs(log_dir)

    # Create log file with timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file = os.path.join(log_dir, f"zima_{timestamp}.log")

    return get_logger("zima", log_file, level)


def main():
    """Test logger"""
    logger = setup_logging()

    logger.section("Testing Zima Logger")

    logger.info("This is an info message")
    logger.warning("This is a warning")
    logger.error("This is an error")
    logger.success("This is a success message")
    logger.progress("Processing something...")

    logger.story_start(1, "Initialize Laravel project")
    logger.execution_phase("Planning")
    logger.execution_phase("Implementing")
    logger.checkpoint("implementation")
    logger.story_complete(1, "Initialize Laravel project")

    logger.story_start(2, "Create database schema")
    logger.story_failed(2, "Create database schema", "Migration failed")
    logger.retry(1, 3)

    logger.worker_start(1)
    logger.worker_stop(1)

    logger.dependency_wait(5, [3, 4])

    logger.metrics({
        'stories_per_hour': 12.5,
        'success_rate': 95.2,
        'avg_retry_count': 0.8
    })

    logger.table("Project Summary", [
        {'Project': 'contract-analyzer', 'Stories': 20, 'Status': 'completed'},
        {'Project': 'video-to-blog', 'Stories': 15, 'Status': 'executing'}
    ])


if __name__ == '__main__':
    main()
