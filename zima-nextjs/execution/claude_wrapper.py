"""
Zima Looper - Cursor CLI Wrapper
Handles all interactions with Cursor CLI (agent) only.
"""

import subprocess
import json
import os
from typing import Tuple, Optional, Dict
from dataclasses import dataclass


@dataclass
class ClaudeResponse:
    """Structured response from Cursor CLI."""
    success: bool
    output: str
    error: Optional[str] = None
    usage: Optional[Dict] = None
    model: str = "claude-sonnet-4"
    exit_code: int = 0


class ClaudeWrapper:
    """
    Wrapper for Cursor CLI (agent) only.
    Uses agent --print, --workspace, --force.

    Apply-edits mode: In headless/print mode, the agent only applies file changes
    when --force is passed (see Cursor docs: "Using Headless CLI"). We always
    pass --force so implementation prompts result in actual workspace edits,
    not just printed suggestions.
    """

    def __init__(
        self,
        cli_path: str = "agent",
        model: str = "sonnet",
        timeout: int = 300,
        dangerously_skip_permissions: bool = True,
        project_dir: str = None
    ):
        """
        Initialize Cursor CLI wrapper.

        Args:
            cli_path: Path to agent binary (default "agent")
            model: Model to use (e.g. sonnet, sonnet-4, gpt-5)
            timeout: Timeout in seconds
            project_dir: Project directory (--workspace)
        """
        self.cli_path = cli_path
        self.model = model
        self.timeout = timeout
        self.project_dir = project_dir or os.getcwd()

    def call(
        self,
        prompt: str,
        output_format: str = "json",
        max_tokens: int = 4096,
        verbose: bool = False
    ) -> ClaudeResponse:
        """
        Call Cursor CLI (agent) with a prompt.

        Args:
            prompt: The prompt to send
            output_format: Output format (json, stream-json, text)
            max_tokens: Ignored; kept for compatibility
            verbose: Include verbose output

        Returns:
            ClaudeResponse object
        """
        work_dir = os.path.abspath(self.project_dir)
        args = [
            self.cli_path,
            '--print',
            '--output-format', output_format,
            '--model', self.model,
            '--workspace', work_dir,
            '--force',  # Required for apply-edits in headless: agent modifies files, not just proposes
        ]
        if verbose:
            args.append('--verbose')

        try:
            # Cursor agent does not read prompt from stdin; pass as positional arg
            process = subprocess.Popen(
                args + [prompt],
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=work_dir,  # same as --workspace so agent file writes go to project
            )
            stdout, stderr = process.communicate(timeout=self.timeout)

            if output_format == 'json':
                return self._parse_json_response(stdout, stderr, process.returncode)
            return ClaudeResponse(
                success=process.returncode == 0,
                output=stdout.strip(),
                error=stderr.strip() if stderr.strip() else None,
                exit_code=process.returncode
            )
        except subprocess.TimeoutExpired:
            process.kill()
            return ClaudeResponse(
                success=False,
                output="",
                error=f"Cursor CLI timed out after {self.timeout} seconds",
                exit_code=-1
            )
        except FileNotFoundError:
            return ClaudeResponse(
                success=False,
                output="",
                error=f"Cursor CLI not found at: {self.cli_path}",
                exit_code=-1
            )
        except Exception as e:
            return ClaudeResponse(
                success=False,
                output="",
                error=f"Unexpected error: {str(e)}",
                exit_code=-1
            )

    def _parse_json_response(self, stdout: str, stderr: str, exit_code: int) -> ClaudeResponse:
        """
        Parse JSON response from Cursor CLI.

        Args:
            stdout: Standard output
            stderr: Standard error
            exit_code: Process exit code

        Returns:
            ClaudeResponse
        """
        error_lines = []
        if stderr:
            for line in stderr.split('\n'):
                if line.strip() and 'deprecated' not in line.lower():
                    error_lines.append(line)
        error_msg = '\n'.join(error_lines) if error_lines else None

        if exit_code != 0:
            return ClaudeResponse(
                success=False,
                output=stdout,
                error=error_msg or f"CLI exited with code {exit_code}",
                exit_code=exit_code
            )

        try:
            data = json.loads(stdout.strip())
            output = data.get('result') or data.get('text') or data.get('output') or ""
            if not output and 'result' in data:
                output = data['result']
            usage = data.get('usage', None)
            return ClaudeResponse(
                success=True,
                output=output.strip() if isinstance(output, str) else str(output).strip(),
                error=error_msg,
                usage=usage,
                model=data.get('model', 'unknown'),
                exit_code=0
            )
        except json.JSONDecodeError:
            # Cursor may return plain text; treat as success if exit_code 0
            return ClaudeResponse(
                success=(exit_code == 0),
                output=stdout.strip(),
                error=error_msg,
                exit_code=exit_code
            )

    def call_streaming(
        self,
        prompt: str,
        on_chunk=None,
        max_tokens: int = 4096
    ) -> ClaudeResponse:
        """
        Call Cursor CLI; streaming not used, falls back to non-streaming call.
        """
        return self.call(prompt, output_format="text", max_tokens=max_tokens)

    def validate_installation(self) -> Tuple[bool, str]:
        """
        Check if Cursor CLI (agent) is properly installed.

        Returns:
            (is_installed, version_or_error)
        """
        try:
            result = subprocess.run(
                [self.cli_path, '--version'],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                return True, (result.stdout or result.stderr or "").strip()
            return False, "CLI found but returned error"
        except FileNotFoundError:
            return False, f"CLI not found at: {self.cli_path}"
        except Exception as e:
            return False, f"Error checking CLI: {str(e)}"


# Convenience function
def call_claude(
    prompt: str,
    model: str = "sonnet",
    timeout: int = 300,
    output_format: str = "json",
    cli_path: str = "agent",
    project_dir: str = None
) -> ClaudeResponse:
    """
    Convenience function to call Cursor CLI (agent).

    Args:
        prompt: Prompt to send
        model: Model to use
        timeout: Timeout in seconds
        output_format: Output format
        cli_path: Path to agent binary
        project_dir: Workspace directory

    Returns:
        ClaudeResponse
    """
    wrapper = ClaudeWrapper(
        cli_path=cli_path,
        model=model,
        timeout=timeout,
        project_dir=project_dir
    )
    return wrapper.call(prompt, output_format=output_format)
