"""
Zima Looper - Story Executor
Executes individual stories using Claude CLI
"""

import os
import sys
import json
import subprocess
from typing import Dict, Optional, List, Tuple
from pathlib import Path
from datetime import datetime

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from execution.claude_wrapper import ClaudeWrapper, ClaudeResponse
from execution.checkpoint import CheckpointManager
from core.state_machine import StoryStateMachine
from quality.quality_gate import QualityGate, QualityGatePolicy


class StoryExecutor:
    """
    Executes stories using Claude CLI
    Manages full story lifecycle from implementation to completion (planning skipped to save tokens)
    """

    def __init__(
        self,
        db,
        config,
        project_dir: str,
        worker_id: int = 1
    ):
        """
        Initialize story executor

        Args:
            db: Database instance
            config: Configuration object
            project_dir: Project directory path
            worker_id: Worker ID for this executor
        """
        self.db = db
        self.config = config
        self.project_dir = Path(project_dir)
        self.worker_id = worker_id

        # Initialize components
        self.claude = ClaudeWrapper(
            cli_path=config.claude_cli_path,
            model=config.claude_model,
            timeout=config.default_timeout_seconds,
            project_dir=str(self.project_dir)
        )
        self.checkpoint_manager = CheckpointManager(db, str(self.project_dir))
        self.state_machine = StoryStateMachine(db)

    def execute_story(self, story_id: int) -> bool:
        """
        Execute a complete story

        Args:
            story_id: Story ID to execute

        Returns:
            True if story completed successfully
        """
        story = self.db.get_story(story_id)
        if not story:
            print(f"Story {story_id} not found")
            return False

        print(f"\n{'='*60}")
        print(f"🚀 Executing Story {story['story_number']}: {story['title']}")
        print(f"{'='*60}\n")

        # Transition to in_progress
        self.state_machine.transition(story_id, 'in_progress')

        # Create initial checkpoint
        self.checkpoint_manager.create_checkpoint(
            story_id=story_id,
            checkpoint_type='start',
            data={'started_at': datetime.now().isoformat()}
        )

        try:
            # Phase 1: Implementation (planning skipped to save tokens)
            impl_success = self._implementation_phase(story_id, story)
            if not impl_success:
                return self._handle_failure(story_id, "Implementation phase failed")

            # Phase 2: Testing (if enabled)
            if self.config.run_tests_before_complete:
                test_success = self._testing_phase(story_id, story)
                if not test_success:
                    if self.config.require_passing_tests:
                        return self._handle_failure(story_id, "Tests failed")
                    else:
                        print("⚠️  Tests failed but continuing (require_passing_tests=false)")

            # Phase 3: Commit
            commit_success = self._commit_phase(story_id, story)
            if not commit_success:
                print("⚠️  Commit failed but story execution completed")

            # Mark as completed (persists to DB)
            self.state_machine.transition(story_id, 'completed')
            # Keep project-level counts in sync so status/monitors see correct totals
            if story.get('project_id'):
                self.db.update_project_stats(story['project_id'])

            # Append to recent_changes log so other workers see what was done (shared context)
            if getattr(self.config, 'shared_context_enabled', True) and story.get('project_id'):
                cps = self.checkpoint_manager.get_story_checkpoints(story_id)
                files = (cps[0]['files_modified'] if cps and cps[0].get('files_modified') else None) or []
                self.db.append_recent_change(
                    story['project_id'],
                    story_id,
                    story['story_number'],
                    story.get('title', ''),
                    files
                )

            print(f"\n✅ Story {story['story_number']} completed successfully!\n")

            return True

        except Exception as e:
            error_msg = f"Unexpected error: {str(e)}"
            print(f"❌ {error_msg}")
            import traceback
            traceback.print_exc()
            return self._handle_failure(story_id, error_msg)

    def _implementation_phase(self, story_id: int, story: Dict) -> bool:
        """
        Implementation phase: Execute story implementation

        Args:
            story_id: Story ID
            story: Story dictionary

        Returns:
            True if implementation successful
        """
        print("🔨 Implementation...")
        self.state_machine.transition(story_id, 'implementing')

        # Ensure Cursor CLI can write to the project (see docs: permissions in .cursor/cli.json)
        self._ensure_cursor_write_permissions()

        # Build implementation prompt
        prompt = self._build_implementation_prompt(story)

        # Call Claude with longer timeout
        self._log_execution(story_id, 'claude_call', 'Implementation phase')
        response = self.claude.call(
            prompt=prompt,
            output_format="text",
            max_tokens=8192
        )

        if not response.success:
            err_msg = response.error or "(no stderr)"
            log_output = err_msg
            if response.output:
                log_output += "\n--- stdout (last 2000 chars) ---\n" + response.output[-2000:]
            self._log_execution(
                story_id, 'claude_call', 'Implementation failed',
                output=log_output, exit_code=response.exit_code if response.exit_code is not None else 1
            )
            return False

        # Save implementation checkpoint
        modified_files = self.checkpoint_manager._get_modified_files()
        self.checkpoint_manager.create_checkpoint(
            story_id=story_id,
            checkpoint_type='implementation',
            data={
                'response': response.output[:1000],  # Truncate for storage
                'modified_files_count': len(modified_files)
            },
            files_modified=modified_files
        )

        self._log_execution(
            story_id, 'claude_call', 'Implementation complete',
            output=f"Modified {len(modified_files)} files", exit_code=0
        )

        print(f"✓ Implementation complete ({len(modified_files)} files modified)")
        return True

    def _testing_phase(self, story_id: int, story: Dict) -> bool:
        """
        Testing phase: Run quality gate checks

        Args:
            story_id: Story ID
            story: Story dictionary

        Returns:
            True if quality gate passes
        """
        print("🧪 Phase 2: Quality Gate...")
        self.state_machine.transition(story_id, 'testing')

        # Create quality gate with policy (Next.js: lint+build; Laravel checks disabled)
        policy = QualityGatePolicy(
            require_tests_pass=self.config.require_passing_tests,
            require_syntax_valid=True,
            require_composer_valid=False,
            require_env_valid=False,
            allow_no_tests=True
        )

        gate = QualityGate(self.db, str(self.project_dir), policy, config=self.config)

        # Run quality gate check
        print("  Running quality checks...")
        gate_result = gate.check_story_quality(story_id, run_tests=True)

        # Display results
        print(f"\n{gate_result['message']}")

        if gate_result['warnings']:
            for warning in gate_result['warnings']:
                print(f"  ⚠️  {warning}")

        if gate_result['failures']:
            print("\nFailures:")
            for failure in gate_result['failures']:
                print(f"  ❌ {failure}")

        # Check if tests ran
        if gate_result.get('checks', {}).get('tests'):
            tests = gate_result['checks']['tests']
            if tests.get('tests_run', 0) > 0:
                print(f"\n  Tests: {tests['tests_passed']}/{tests['tests_run']} passed")
                print(f"  Duration: {tests.get('duration', 0):.1f}s")

        # Rollback if gate failed
        if not gate_result['passed']:
            if gate.should_rollback_story(story_id, gate_result):
                print("\n⚠️  Quality gate failed - initiating rollback...")
                self._rollback_story(story_id)
                return False

        return gate_result['passed']

    def _rollback_story(self, story_id: int):
        """
        Rollback story changes due to quality gate failure

        Args:
            story_id: Story ID
        """
        print("🔄 Rolling back story changes...")

        # Find most recent checkpoint before implementation
        checkpoints = self.checkpoint_manager.get_story_checkpoints(story_id)

        # Find the 'start' checkpoint (planning phase removed)
        rollback_checkpoint = None
        for checkpoint in reversed(checkpoints):
            if checkpoint['checkpoint_type'] == 'start':
                rollback_checkpoint = checkpoint
                break

        if rollback_checkpoint:
            print(f"  Rolling back to checkpoint: {rollback_checkpoint['checkpoint_type']}")
            self.checkpoint_manager.restore_checkpoint(rollback_checkpoint['id'])
            print("✓ Rollback complete")
        else:
            print("⚠️  No suitable checkpoint found for rollback")
            print("  Manual intervention may be required")

    def _commit_phase(self, story_id: int, story: Dict) -> bool:
        """
        Commit phase: Create git commit for story

        Args:
            story_id: Story ID
            story: Story dictionary

        Returns:
            True if commit successful
        """
        print("📦 Phase 3: Committing...")

        # Build commit message
        commit_message = self._build_commit_message(story)

        # Create commit checkpoint
        checkpoint_id = self.checkpoint_manager.create_commit_checkpoint(
            story_id=story_id,
            commit_message=commit_message
        )

        if checkpoint_id:
            self._log_execution(
                story_id, 'git_commit', 'Commit created',
                output=commit_message, exit_code=0
            )
            return True
        else:
            print("⚠️  No changes to commit")
            return True  # Not a failure if no changes

    def _handle_failure(self, story_id: int, error_message: str) -> bool:
        """
        Handle story failure

        Args:
            story_id: Story ID
            error_message: Error message

        Returns:
            False (always, since it's a failure)
        """
        print(f"\n❌ Story failed: {error_message}\n")

        # Update story with error
        self.db.update_story(story_id, {
            'error_message': error_message,
            'error_logs': error_message  # Store full error logs
        })

        # Transition to failed (persists status; state_machine also updates DB)
        self.state_machine.transition(story_id, 'failed', error_message)
        # Keep project-level counts in sync
        story = self.db.get_story(story_id)
        if story and story.get('project_id'):
            self.db.update_project_stats(story['project_id'])

        return False

    def _build_implementation_prompt(self, story: Dict) -> str:
        """Build minimal implementation prompt (token-optimized)."""
        acceptance_criteria = story['acceptance_criteria']
        if isinstance(acceptance_criteria, str):
            acceptance_criteria = json.loads(acceptance_criteria)
        ac_text = self._format_acceptance_criteria(acceptance_criteria)
        max_items = getattr(self.config, 'max_acceptance_criteria_items', 25)
        max_chars = getattr(self.config, 'max_acceptance_criteria_chars', 4000)
        if len(acceptance_criteria) > max_items:
            acceptance_criteria = acceptance_criteria[:max_items]
            ac_text = self._format_acceptance_criteria(acceptance_criteria)
        if len(ac_text) > max_chars:
            ac_text = ac_text[:max_chars] + "\n... (truncated)"

        shared = ""
        if getattr(self.config, 'shared_context_enabled', True):
            project_id = story.get('project_id')
            if project_id:
                limit_s = getattr(self.config, 'shared_context_max_stories', 15)
                limit_c = getattr(self.config, 'shared_context_max_chars', 1500)
                shared = self.db.get_recent_completions_summary(
                    project_id, limit_stories=limit_s, max_chars=limit_c
                )
                # Recent changes log (handoff from other workers)
                rc_limit = getattr(self.config, 'shared_context_recent_changes_limit', 20)
                rc_chars = getattr(self.config, 'shared_context_recent_changes_max_chars', 500)
                recent = self.db.get_recent_changes(project_id, limit=rc_limit, max_chars=rc_chars)
                if recent:
                    shared = shared + "\n" + recent + "\n" if shared else recent + "\n"
                # "Avoid these files" list (reduce conflicts)
                avoid_max = getattr(self.config, 'shared_context_avoid_files_max', 30)
                avoid = self.db.get_recently_touched_files(
                    project_id, limit_stories=limit_s, max_files=avoid_max
                )
                if avoid:
                    shared = shared + avoid + "\n" if shared else avoid + "\n"
        if shared:
            shared = shared + "\n"

        # Lead with imperative to use write tool so the agent actually edits files (Cursor headless)
        workspace_path = os.path.abspath(self.project_dir)
        is_flutter = self._is_flutter_project()

        if is_flutter:
            global_rules = """Global implementation rules (every story):
- Before implementing: Check if a similar story/implementation already exists. If exists → improve it; if not → implement from scratch; if exists and complete → skip to next task. Always use existing code when applicable.
- Deliver a fully functional Flutter screen, widget, or service: no placeholders; real business logic and UI.
- Business logic: from docs/prd.json (or DOCS/prd.json) and by studying existing code in lib/.
- Design: DOCS/DESIGN.md for layout, touch targets (48dp min), spacing, colors, overflow prevention.
- Navigation: DOCS/NAVIGATION.md for how users reach this feature; ensure the screen is reachable.
- Flutter structure: lib/screens/ for screens, lib/widgets/ for widgets, lib/services/ for services, lib/models/ for models.
- Use existing components (e.g. CachedMediaImage, PostCard) and services; add new only when needed.
- Auth, validation, error handling, and loading states on every screen.
- If this story requires backend data or sends data to backend: Append to docs/BACKEND.md (project root) all API endpoints, request/response formats, and expectations this story requires.
- Fix all lint errors (run flutter analyze) on files you change."""
        else:
            global_rules = """Global implementation rules (every story):
- Deliver a fully functional page or feature: no placeholders, no Under Construction; real business logic and UI.
- Business logic: from docs/prd.json and by studying existing code; implement and test the behavior.
- Design: docs/stories/DESIGN-SYSTEM.md for layout, spacing, and components.
- Put the page in its proper module folder; integrate with existing module and system; use shared sidebar and topbar (DashboardLayout).
- Add new backend APIs or new components (forms, tables, workflows) only when needed; prefer reusing existing code.
- Auth, validation, error handling, and loading states on every page.
- When this page is done, mark it as done in docs/PAGES-TO-IMPLEMENT.md (add ✅ to the line for this route).
- Fix all lint errors on the page and any files you change."""

        prompt = f"""You MUST use your file write tool to create or modify source files in this workspace. Do not respond with only a description—actually edit the codebase. By the end you must have created or modified at least one file.

Workspace (edit files here): {workspace_path}
{shared}Story {story['story_number']}: {story['title']}

Description: {story['description'][:800]}

Acceptance criteria (all required):
{ac_text}

{global_rules}

Task: Implement the story by creating or editing the necessary files. Apply all code changes in the workspace. Do not only describe—use your write tool to save changes."""
        # Documentation: skip unless required (Next.js: may update PAGES-TO-IMPLEMENT.md)
        if getattr(self.config, 'skip_documentation', True):
            if is_flutter:
                prompt += "\nDo not create or update .md files or README unless an acceptance criterion explicitly requires it. Exception: You MUST append to docs/BACKEND.md when the story requires backend APIs or sends data to the backend."
            else:
                prompt += "\nDo not create or update other .md files or README unless an acceptance criterion explicitly requires it. You MAY update docs/PAGES-TO-IMPLEMENT.md to mark the page as done (✅)."
        return prompt

    def _is_flutter_project(self) -> bool:
        """Check if project has pubspec.yaml (Flutter)"""
        pubspec = self.project_dir / "pubspec.yaml"
        return pubspec.exists()

    def _ensure_cursor_write_permissions(self) -> None:
        """
        Ensure project has .cursor/cli.json with Write permissions so the Cursor CLI
        agent can modify files in headless mode (see cursor.com/docs/cli/reference/permissions).
        """
        cursor_dir = self.project_dir / ".cursor"
        config_path = cursor_dir / "cli.json"
        allow_writes = [
            "Write(frontend/**)",
            "Write(backend/**)",
            "Write(lib/**)",
            "Write(**/*.dart)",
            "Write(**/*.tsx)",
            "Write(**/*.ts)",
            "Write(**/*.jsx)",
            "Write(**/*.js)",
            "Write(**/*.java)",
            "Write(**/*.yml)",
            "Write(**/*.yaml)",
            "Write(**/*.json)",
            "Write(**/*.css)",
            "Write(**/*.sql)",
            "Read(**/*)",
            "Shell(npm)",
            "Shell(mvn)",
            "Shell(flutter)",
        ]
        try:
            cursor_dir.mkdir(parents=True, exist_ok=True)
            config = {"permissions": {"allow": allow_writes, "deny": []}}
            with open(config_path, "w") as f:
                json.dump(config, f, indent=2)
        except Exception as e:
            print(f"  ⚠️  Could not write {config_path}: {e}")

    def _format_acceptance_criteria(self, criteria: List[str]) -> str:
        """Format acceptance criteria as numbered list."""
        return '\n'.join(f"{i+1}. {criterion}" for i, criterion in enumerate(criteria))

    def _build_commit_message(self, story: Dict) -> str:
        """Build git commit message for story"""
        template = self.config.git_commit_message_template

        message = template.format(
            story_id=story['id'],
            story_number=story['story_number'],
            title=story['title']
        )

        return message

    def _log_execution(
        self,
        story_id: int,
        execution_type: str,
        command: str,
        output: Optional[str] = None,
        exit_code: Optional[int] = None,
        duration_seconds: float = 0.0
    ):
        """
        Log execution to database

        Args:
            story_id: Story ID
            execution_type: Type of execution (claude_call, test_run, git_commit)
            command: Command or description
            output: Command output
            exit_code: Exit code
            duration_seconds: Execution duration in seconds (future enhancement)

        Note:
            Duration tracking not yet implemented. Pass 0.0 for now.
            Future enhancement: Track actual execution time for metrics.
        """
        self.db.log_execution(
            story_id=story_id,
            execution_type=execution_type,
            command=command,
            output=output,
            exit_code=exit_code,
            duration_seconds=duration_seconds
        )
