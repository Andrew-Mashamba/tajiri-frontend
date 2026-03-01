"""
Zima Looper - Error Analyzer
Analyzes and categorizes errors to determine recovery strategies
"""

import re
from typing import Dict, List, Optional, Tuple
from enum import Enum
from dataclasses import dataclass


class ErrorCategory(Enum):
    """Error category types"""
    SYNTAX_ERROR = "syntax_error"           # PHP/JavaScript syntax errors
    RUNTIME_ERROR = "runtime_error"         # Runtime exceptions
    TEST_FAILURE = "test_failure"           # Failed tests
    TIMEOUT = "timeout"                     # Execution timeout
    FILE_NOT_FOUND = "file_not_found"       # Missing files
    PERMISSION_ERROR = "permission_error"   # Permission issues
    DATABASE_ERROR = "database_error"       # Database-related errors
    NETWORK_ERROR = "network_error"         # Network/API errors
    DEPENDENCY_ERROR = "dependency_error"   # Missing dependencies
    UNKNOWN = "unknown"                     # Unclassified errors


class ErrorSeverity(Enum):
    """Error severity levels"""
    CRITICAL = "critical"      # Cannot continue without manual intervention
    HIGH = "high"             # Difficult to auto-fix, likely needs manual help
    MEDIUM = "medium"         # Fixable with Claude assistance
    LOW = "low"               # Simple fix, high confidence


@dataclass
class ErrorAnalysis:
    """Result of error analysis"""
    category: ErrorCategory
    severity: ErrorSeverity
    is_recoverable: bool
    error_message: str
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    stack_trace: Optional[str] = None
    context_lines: List[str] = None
    suggested_fix: Optional[str] = None
    confidence: float = 0.0  # 0.0 to 1.0


class ErrorAnalyzer:
    """
    Analyzes errors and extracts actionable information
    """

    def __init__(self):
        """Initialize error analyzer"""
        self.syntax_patterns = [
            (r"Parse error: syntax error, (.+?) in (.+?) on line (\d+)", ErrorCategory.SYNTAX_ERROR),
            (r"SyntaxError: (.+?)", ErrorCategory.SYNTAX_ERROR),
            (r"unexpected '(.+?)' in (.+?):(\d+)", ErrorCategory.SYNTAX_ERROR),
        ]

        self.runtime_patterns = [
            (r"Fatal error: (.+?) in (.+?) on line (\d+)", ErrorCategory.RUNTIME_ERROR),
            (r"Uncaught (.+?): (.+?) in (.+?):(\d+)", ErrorCategory.RUNTIME_ERROR),
            (r"Error: (.+?) at (.+?):(\d+)", ErrorCategory.RUNTIME_ERROR),
        ]

        self.test_patterns = [
            (r"FAILED.*Tests: (\d+) failed", ErrorCategory.TEST_FAILURE),
            (r"Failed asserting that (.+?)", ErrorCategory.TEST_FAILURE),
            (r"Test.*failed with message: (.+?)", ErrorCategory.TEST_FAILURE),
        ]

        self.file_patterns = [
            (r"No such file or directory: '(.+?)'", ErrorCategory.FILE_NOT_FOUND),
            (r"failed to open stream: No such file or directory", ErrorCategory.FILE_NOT_FOUND),
            (r"require\((.+?)\): Failed to open stream", ErrorCategory.FILE_NOT_FOUND),
        ]

    def analyze(
        self,
        error_logs: str,
        execution_type: str,
        exit_code: int
    ) -> ErrorAnalysis:
        """
        Analyze error logs and categorize

        Args:
            error_logs: Error output/logs
            execution_type: Type of execution (claude_call, test_run, git_commit)
            exit_code: Exit code

        Returns:
            ErrorAnalysis object
        """
        if not error_logs or exit_code == 0:
            # No error
            return ErrorAnalysis(
                category=ErrorCategory.UNKNOWN,
                severity=ErrorSeverity.LOW,
                is_recoverable=True,
                error_message="No error",
                confidence=1.0
            )

        # Categorize error
        category, extracted_info = self._categorize_error(error_logs, execution_type)

        # Determine severity
        severity = self._determine_severity(category, error_logs)

        # Check if recoverable
        is_recoverable = self._is_recoverable(category, severity, error_logs)

        # Extract file and line if available
        file_path, line_number = extracted_info.get('file'), extracted_info.get('line')

        # Extract stack trace
        stack_trace = self._extract_stack_trace(error_logs)

        # Get context lines if file and line are known
        context_lines = []
        if file_path and line_number:
            context_lines = self._get_context_lines(file_path, line_number)

        # Suggest fix
        suggested_fix = self._suggest_fix(category, extracted_info, error_logs)

        # Calculate confidence
        confidence = self._calculate_confidence(category, extracted_info, is_recoverable)

        return ErrorAnalysis(
            category=category,
            severity=severity,
            is_recoverable=is_recoverable,
            error_message=extracted_info.get('message', error_logs[:200]),
            file_path=file_path,
            line_number=line_number,
            stack_trace=stack_trace,
            context_lines=context_lines,
            suggested_fix=suggested_fix,
            confidence=confidence
        )

    def _categorize_error(
        self,
        error_logs: str,
        execution_type: str
    ) -> Tuple[ErrorCategory, Dict]:
        """
        Categorize error based on patterns

        Args:
            error_logs: Error logs
            execution_type: Execution type

        Returns:
            (ErrorCategory, extracted_info dict)
        """
        extracted_info = {}

        # Check syntax errors
        for pattern, category in self.syntax_patterns:
            match = re.search(pattern, error_logs, re.IGNORECASE)
            if match:
                extracted_info['message'] = match.group(1) if match.lastindex >= 1 else ""
                extracted_info['file'] = match.group(2) if match.lastindex >= 2 else None
                extracted_info['line'] = int(match.group(3)) if match.lastindex >= 3 else None
                return category, extracted_info

        # Check runtime errors
        for pattern, category in self.runtime_patterns:
            match = re.search(pattern, error_logs, re.IGNORECASE)
            if match:
                extracted_info['message'] = match.group(1) if match.lastindex >= 1 else ""
                extracted_info['file'] = match.group(2) if match.lastindex >= 2 else None
                extracted_info['line'] = int(match.group(3)) if match.lastindex >= 3 else None
                return category, extracted_info

        # Check test failures
        if execution_type == 'test_run':
            for pattern, category in self.test_patterns:
                match = re.search(pattern, error_logs, re.IGNORECASE | re.DOTALL)
                if match:
                    extracted_info['message'] = match.group(1) if match.lastindex >= 1 else ""
                    return category, extracted_info

        # Check file not found
        for pattern, category in self.file_patterns:
            match = re.search(pattern, error_logs, re.IGNORECASE)
            if match:
                extracted_info['message'] = f"File not found: {match.group(1)}"
                extracted_info['missing_file'] = match.group(1)
                return category, extracted_info

        # Check timeout
        if "timed out" in error_logs.lower() or "timeout expired" in error_logs.lower():
            extracted_info['message'] = "Execution timed out"
            return ErrorCategory.TIMEOUT, extracted_info

        # Check permission errors
        if "permission denied" in error_logs.lower():
            extracted_info['message'] = "Permission denied"
            return ErrorCategory.PERMISSION_ERROR, extracted_info

        # Check database errors
        db_keywords = ["sqlstate", "query exception", "database", "migration failed"]
        if any(keyword in error_logs.lower() for keyword in db_keywords):
            extracted_info['message'] = "Database error"
            return ErrorCategory.DATABASE_ERROR, extracted_info

        # Default: unknown
        extracted_info['message'] = error_logs[:200]
        return ErrorCategory.UNKNOWN, extracted_info

    def _determine_severity(
        self,
        category: ErrorCategory,
        error_logs: str
    ) -> ErrorSeverity:
        """Determine error severity"""

        # Critical errors
        if category in [ErrorCategory.PERMISSION_ERROR, ErrorCategory.DEPENDENCY_ERROR]:
            return ErrorSeverity.CRITICAL

        # High severity
        if category in [ErrorCategory.DATABASE_ERROR, ErrorCategory.NETWORK_ERROR]:
            return ErrorSeverity.HIGH

        # Medium severity
        if category in [ErrorCategory.RUNTIME_ERROR, ErrorCategory.TEST_FAILURE]:
            return ErrorSeverity.MEDIUM

        # Low severity
        if category in [ErrorCategory.SYNTAX_ERROR, ErrorCategory.FILE_NOT_FOUND]:
            return ErrorSeverity.LOW

        # Timeout depends on frequency
        if category == ErrorCategory.TIMEOUT:
            return ErrorSeverity.MEDIUM

        return ErrorSeverity.MEDIUM

    def _is_recoverable(
        self,
        category: ErrorCategory,
        severity: ErrorSeverity,
        error_logs: str
    ) -> bool:
        """Determine if error is recoverable"""

        # Non-recoverable categories
        if category in [ErrorCategory.PERMISSION_ERROR]:
            return False

        # Critical severity usually not recoverable
        if severity == ErrorSeverity.CRITICAL:
            return False

        # Check for specific non-recoverable patterns
        non_recoverable_patterns = [
            "authentication failed",
            "access denied",
            "not installed",
            "command not found: claude",
            "command not found: agent",
        ]

        for pattern in non_recoverable_patterns:
            if pattern in error_logs.lower():
                return False

        return True

    def _extract_stack_trace(self, error_logs: str) -> Optional[str]:
        """Extract stack trace from error logs"""

        # Look for stack trace patterns
        stack_patterns = [
            r"(Stack trace:.*?)(?=\n\n|\Z)",
            r"(#0.*?)(?=\n\n|\Z)",
            r"(at .*?:\d+.*?)(?=\n\n|\Z)"
        ]

        for pattern in stack_patterns:
            match = re.search(pattern, error_logs, re.DOTALL | re.MULTILINE)
            if match:
                return match.group(1).strip()

        return None

    def _get_context_lines(
        self,
        file_path: str,
        line_number: int,
        context: int = 5
    ) -> List[str]:
        """
        Get context lines around error line

        Args:
            file_path: File path
            line_number: Line number
            context: Number of lines before/after

        Returns:
            List of context lines
        """
        try:
            with open(file_path, 'r') as f:
                lines = f.readlines()

            start = max(0, line_number - context - 1)
            end = min(len(lines), line_number + context)

            context_lines = []
            for i in range(start, end):
                prefix = ">>> " if i == line_number - 1 else "    "
                context_lines.append(f"{prefix}{i+1}: {lines[i].rstrip()}")

            return context_lines

        except Exception:
            return []

    def _suggest_fix(
        self,
        category: ErrorCategory,
        extracted_info: Dict,
        error_logs: str
    ) -> Optional[str]:
        """Suggest potential fix based on error category"""

        if category == ErrorCategory.SYNTAX_ERROR:
            return "Check syntax at the indicated line. Look for missing semicolons, brackets, or quotes."

        if category == ErrorCategory.FILE_NOT_FOUND:
            missing_file = extracted_info.get('missing_file')
            if missing_file:
                return f"Create the missing file: {missing_file}"
            return "Ensure all required files exist and paths are correct."

        if category == ErrorCategory.TEST_FAILURE:
            return "Review test assertions and ensure implementation matches expected behavior."

        if category == ErrorCategory.RUNTIME_ERROR:
            return "Add error handling, check for null values, or validate input data."

        if category == ErrorCategory.TIMEOUT:
            return "Optimize the operation or break it into smaller steps."

        if category == ErrorCategory.DATABASE_ERROR:
            return "Check database schema, run migrations, or verify database connection."

        return "Review the error logs and implement a fix based on the specific issue."

    def _calculate_confidence(
        self,
        category: ErrorCategory,
        extracted_info: Dict,
        is_recoverable: bool
    ) -> float:
        """Calculate confidence in fix success"""

        confidence = 0.5  # Base confidence

        # Higher confidence for well-structured errors
        if extracted_info.get('file') and extracted_info.get('line'):
            confidence += 0.2

        # Higher confidence for recoverable errors
        if is_recoverable:
            confidence += 0.2

        # Category-specific confidence
        if category == ErrorCategory.SYNTAX_ERROR:
            confidence += 0.1  # Usually easy to fix

        if category == ErrorCategory.TEST_FAILURE:
            confidence += 0.05  # Can be tricky

        if category == ErrorCategory.UNKNOWN:
            confidence -= 0.3  # Low confidence on unknown errors

        return min(1.0, max(0.0, confidence))

    def format_analysis(self, analysis: ErrorAnalysis) -> str:
        """Format analysis for display"""

        lines = []
        lines.append("=" * 60)
        lines.append("ERROR ANALYSIS")
        lines.append("=" * 60)

        lines.append(f"Category: {analysis.category.value}")
        lines.append(f"Severity: {analysis.severity.value}")
        lines.append(f"Recoverable: {'Yes' if analysis.is_recoverable else 'No'}")
        lines.append(f"Confidence: {analysis.confidence:.0%}")

        lines.append(f"\nError: {analysis.error_message}")

        if analysis.file_path and analysis.line_number:
            lines.append(f"\nLocation: {analysis.file_path}:{analysis.line_number}")

        if analysis.context_lines:
            lines.append("\nContext:")
            for line in analysis.context_lines:
                lines.append(line)

        if analysis.stack_trace:
            lines.append(f"\nStack Trace:\n{analysis.stack_trace[:500]}")

        if analysis.suggested_fix:
            lines.append(f"\nSuggested Fix:\n{analysis.suggested_fix}")

        lines.append("=" * 60)

        return '\n'.join(lines)
