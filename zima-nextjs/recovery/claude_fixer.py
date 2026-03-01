"""
Zima Looper - Claude-Powered Fixer
Uses Claude to analyze and fix errors with context-aware prompts
"""

import os
import sys
import json
import subprocess
from typing import Dict, Optional, List, Tuple
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from execution.claude_wrapper import ClaudeWrapper, ClaudeResponse
from recovery.error_analyzer import ErrorAnalyzer, ErrorAnalysis, ErrorCategory


class ClaudeFixer:
    """
    Uses Claude to analyze and fix errors
    """

    def __init__(self, db, config, project_dir: str):
        """
        Initialize Claude fixer

        Args:
            db: Database instance
            config: Configuration object
            project_dir: Project directory path
        """
        self.db = db
        self.config = config
        self.project_dir = Path(project_dir)
        self.claude = ClaudeWrapper(
            cli_path=getattr(config, 'claude_cli_path', 'agent'),
            model=getattr(config, 'claude_model', 'sonnet'),
            timeout=600,  # Extended timeout for complex fixes
            project_dir=str(self.project_dir)
        )
        self.analyzer = ErrorAnalyzer()

    def attempt_fix(
        self,
        story_id: int,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> Tuple[bool, str]:
        """
        Attempt to fix error using Claude

        Args:
            story_id: Story ID
            error_analysis: ErrorAnalysis object
            error_logs: Full error logs

        Returns:
            (success: bool, message: str)
        """
        story = self.db.get_story(story_id)
        if not story:
            return False, "Story not found"

        print(f"\n{'='*60}")
        print(f"🔧 Attempting Claude-powered fix for Story {story['story_number']}")
        print(f"{'='*60}")
        print(f"Error Category: {error_analysis.category.value}")
        print(f"Severity: {error_analysis.severity.value}")
        print(f"Confidence: {error_analysis.confidence:.0%}\n")

        # Check if error is recoverable
        if not error_analysis.is_recoverable:
            return False, f"Error is not recoverable: {error_analysis.error_message}"

        # Build fix prompt based on error category
        prompt = self._build_fix_prompt(
            story=story,
            error_analysis=error_analysis,
            error_logs=error_logs
        )

        # Log fix attempt
        self.db.log_execution(
            story_id=story_id,
            execution_type='claude_fix',
            command='Attempting Claude-powered fix',
            output=f"Category: {error_analysis.category.value}, Confidence: {error_analysis.confidence:.0%}"
        )

        # Call Claude
        print("🤖 Calling Claude to analyze and fix the error...")
        response = self.claude.call(
            prompt=prompt,
            output_format="text",
            max_tokens=8192
        )

        if not response.success:
            error_msg = f"Claude fix failed: {response.error}"
            self.db.log_execution(
                story_id=story_id,
                execution_type='claude_fix',
                command='Claude fix failed',
                output=error_msg,
                exit_code=1
            )
            return False, error_msg

        # Log successful fix attempt
        self.db.log_execution(
            story_id=story_id,
            execution_type='claude_fix',
            command='Claude fix completed',
            output=response.output[:1000],
            exit_code=0
        )

        print(f"✓ Claude provided fix ({len(response.output)} chars)")
        print(f"\nFix applied. The story will be re-executed to verify the fix works.\n")

        return True, "Fix applied by Claude"

    def _build_fix_prompt(
        self,
        story: Dict,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        """
        Build context-aware fix prompt based on error type

        Args:
            story: Story dictionary
            error_analysis: ErrorAnalysis object
            error_logs: Full error logs

        Returns:
            Prompt string
        """
        acceptance_criteria = story.get('acceptance_criteria')
        if isinstance(acceptance_criteria, str):
            acceptance_criteria = json.loads(acceptance_criteria) if acceptance_criteria else []
        max_log = getattr(self.config, 'max_error_log_chars', 600)
        max_ctx = getattr(self.config, 'max_error_context_lines', 15)
        err_log = (error_logs or "")[-max_log:]
        ctx_lines = (error_analysis.context_lines or [])[:max_ctx]

        base_prompt = f"""Project: {self.project_dir}
Story {story['story_number']}: {story['title']}
Error: {error_analysis.category.value} — {error_analysis.error_message[:400]}
"""
        if ctx_lines:
            base_prompt += f"Context (file):\n" + "\n".join(ctx_lines) + "\n\n"

        if error_analysis.category == ErrorCategory.SYNTAX_ERROR:
            return self._build_syntax_fix_prompt(base_prompt, error_analysis, err_log)
        elif error_analysis.category == ErrorCategory.TEST_FAILURE:
            return self._build_test_fix_prompt(base_prompt, error_analysis, err_log)
        elif error_analysis.category == ErrorCategory.RUNTIME_ERROR:
            return self._build_runtime_fix_prompt(base_prompt, error_analysis, err_log)
        elif error_analysis.category == ErrorCategory.FILE_NOT_FOUND:
            return self._build_file_fix_prompt(base_prompt, error_analysis, err_log)
        elif error_analysis.category == ErrorCategory.TIMEOUT:
            return self._build_timeout_fix_prompt(base_prompt, error_analysis, err_log)
        else:
            return self._build_general_fix_prompt(base_prompt, error_analysis, err_log)

    def _build_syntax_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        loc = f"{error_analysis.file_path}:{error_analysis.line_number}"
        return base_prompt + f"Location: {loc}\nTask: Fix syntax error. Output: code only.\n"

    def _build_test_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        prompt = base_prompt + f"Test failure: {error_analysis.error_message[:300]}\n"
        if error_logs:
            prompt += f"Output:\n{error_logs}\n"
        return prompt + "Task: Fix failing test. Output: code only.\n"

        # Try to extract failing test name
        failing_test = self._extract_failing_test(error_logs)
        if failing_test:
            prompt += f"**Failing Test:** {failing_test}\n\n"

        prompt += """**Task:**
1. Analyze why the test is failing
2. Review the test expectations vs actual implementation
3. Fix the implementation to make the test pass
4. Ensure the fix doesn't break other tests

**Common Test Failure Causes:**
- Incorrect return values
- Missing database records
- Wrong HTTP status codes
- Missing or incorrect validation
- Incorrect assertions in test code

**IMPORTANT:**
- Fix the implementation, not the test (unless test is genuinely wrong)
- Ensure all acceptance criteria are still met
- Consider edge cases and validation

Begin fixing now.
"""

        return prompt

    def _build_runtime_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        loc = error_analysis.file_path or ""
        if error_analysis.line_number:
            loc += f":{error_analysis.line_number}"
        out = base_prompt + f"Location: {loc}\n"
        if error_analysis.stack_trace:
            out += error_analysis.stack_trace[:500] + "\n"
        if error_logs:
            out += error_logs + "\n"
        return out + "Task: Fix runtime error. Output: code only.\n"

    def _build_file_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        return base_prompt + f"Missing: {error_analysis.error_message[:200]}\nTask: Create file. Output: code only.\n"

    def _build_timeout_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        out = base_prompt + "Timeout.\n"
        if error_logs:
            out += error_logs + "\n"
        return out + "Task: Optimize or split work. Output: code only.\n"

    def _build_general_fix_prompt(
        self,
        base_prompt: str,
        error_analysis: ErrorAnalysis,
        error_logs: str
    ) -> str:
        out = base_prompt
        if error_logs:
            out += error_logs + "\n"
        return out + "Task: Fix error. Output: code only.\n"

    def _extract_failing_test(self, test_output: str) -> Optional[str]:
        """Extract failing test name from test output"""

        patterns = [
            r"FAILED.*?(Tests\\.*?)::",
            r"Failed: (.*?)\n",
            r"✗ (.*?) \("
        ]

        for pattern in patterns:
            import re
            match = re.search(pattern, test_output)
            if match:
                return match.group(1)

        return None

    def _format_acceptance_criteria(self, criteria: List[str]) -> str:
        """Format acceptance criteria as numbered list"""
        return '\n'.join(f"{i+1}. {criterion}" for i, criterion in enumerate(criteria))

    def get_fix_success_rate(self, project_id: int) -> Dict:
        """
        Calculate success rate of Claude fixes

        Args:
            project_id: Project ID

        Returns:
            Statistics dictionary
        """
        stories = self.db.get_project_stories(project_id)

        total_fixes = 0
        successful_fixes = 0

        for story in stories:
            executions = self.db.get_story_executions(story['id'], limit=100)

            # Count claude_fix attempts
            fix_attempts = [e for e in executions if e['execution_type'] == 'claude_fix']

            if fix_attempts:
                total_fixes += len(fix_attempts)

                # If story eventually completed, consider fix successful
                if story['status'] == 'completed':
                    successful_fixes += 1

        success_rate = (successful_fixes / total_fixes * 100) if total_fixes > 0 else 0

        return {
            'project_id': project_id,
            'total_fix_attempts': total_fixes,
            'successful_fixes': successful_fixes,
            'success_rate': success_rate
        }
