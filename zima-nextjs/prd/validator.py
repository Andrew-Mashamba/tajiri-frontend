"""
Zima Looper - PRD Validator
Validates PRD structure and completeness
"""

import json
from typing import Dict, List, Tuple
from pathlib import Path


class PRDValidator:
    """Validate PRD structure and content"""

    def __init__(self, prd_data: Dict = None, prd_path: str = None):
        """
        Initialize validator

        Args:
            prd_data: PRD dictionary (if already loaded)
            prd_path: Path to PRD JSON file (if not loaded)
        """
        if prd_data:
            self.prd = prd_data
        elif prd_path:
            with open(prd_path, 'r') as f:
                self.prd = json.load(f)
        else:
            raise ValueError("Either prd_data or prd_path must be provided")

        self.errors = []
        self.warnings = []

    def validate(self) -> Tuple[bool, List[str], List[str]]:
        """
        Validate PRD

        Returns:
            (is_valid, errors, warnings)
        """
        self.errors = []
        self.warnings = []

        # Check required top-level fields
        self._check_required_fields()

        # Validate stories
        self._validate_stories()

        # Check story ordering
        self._check_story_ordering()

        # Validate acceptance criteria
        self._validate_acceptance_criteria()

        is_valid = len(self.errors) == 0

        return is_valid, self.errors, self.warnings

    def _check_required_fields(self):
        """Check that required top-level fields exist"""
        required = ['projectName', 'stories']

        for field in required:
            if field not in self.prd:
                self.errors.append(f"Missing required field: {field}")

        # Recommended fields
        recommended = ['description', 'techStack', 'total_stories']
        for field in recommended:
            if field not in self.prd:
                self.warnings.append(f"Missing recommended field: {field}")

    def _validate_stories(self):
        """Validate story structure"""
        if 'stories' not in self.prd:
            return

        stories = self.prd['stories']

        if not isinstance(stories, list):
            self.errors.append("'stories' must be an array")
            return

        if len(stories) == 0:
            self.errors.append("PRD must have at least one story")
            return

        # Validate each story
        for i, story in enumerate(stories):
            self._validate_story(story, i)

    def _validate_story(self, story: Dict, index: int):
        """Validate individual story"""
        # Required fields
        required = ['id', 'title', 'acceptance']
        for field in required:
            if field not in story:
                self.errors.append(f"Story {index}: Missing required field '{field}'")

        # Check ID is sequential
        if 'id' in story:
            expected_id = index + 1
            if story['id'] != expected_id:
                self.warnings.append(
                    f"Story {index}: ID is {story['id']}, expected {expected_id} (IDs should be sequential)"
                )

        # Check title
        if 'title' in story:
            if not story['title'] or not story['title'].strip():
                self.errors.append(f"Story {story.get('id', index)}: Title cannot be empty")

            if len(story['title']) > 100:
                self.warnings.append(
                    f"Story {story.get('id', index)}: Title is very long ({len(story['title'])} chars)"
                )

        # Check description
        if 'description' not in story:
            self.warnings.append(f"Story {story.get('id', index)}: Missing description")

        # Check acceptance criteria
        if 'acceptance' in story:
            if not isinstance(story['acceptance'], list):
                self.errors.append(f"Story {story.get('id', index)}: 'acceptance' must be an array")
            elif len(story['acceptance']) == 0:
                self.errors.append(f"Story {story.get('id', index)}: Must have at least one acceptance criterion")
            elif len(story['acceptance']) < 3:
                self.warnings.append(
                    f"Story {story.get('id', index)}: Only {len(story['acceptance'])} acceptance criteria (recommended: 5-10)"
                )

        # Check priority
        if 'priority' not in story:
            self.warnings.append(f"Story {story.get('id', index)}: Missing priority")

        # Check estimate
        if 'estimate_hours' not in story and 'estimate' not in story:
            self.warnings.append(f"Story {story.get('id', index)}: Missing time estimate")

    def _check_story_ordering(self):
        """Check that stories are ordered by priority"""
        if 'stories' not in self.prd:
            return

        stories = self.prd['stories']

        # Check IDs are sequential
        for i, story in enumerate(stories):
            expected_id = i + 1
            if story.get('id') != expected_id:
                self.warnings.append(f"Stories are not sequentially numbered (found ID {story.get('id')} at position {i})")
                break

        # Check priorities are sequential
        priorities = [s.get('priority', 0) for s in stories]
        if priorities != sorted(priorities):
            self.warnings.append("Story priorities are not in order")

    def _validate_acceptance_criteria(self):
        """Validate acceptance criteria quality"""
        if 'stories' not in self.prd:
            return

        for story in self.prd['stories']:
            if 'acceptance' not in story:
                continue

            story_id = story.get('id', '?')

            for i, criterion in enumerate(story['acceptance']):
                if not isinstance(criterion, str):
                    self.errors.append(
                        f"Story {story_id}, criterion {i+1}: Must be a string"
                    )
                    continue

                if not criterion.strip():
                    self.errors.append(
                        f"Story {story_id}, criterion {i+1}: Cannot be empty"
                    )
                    continue

                # Check for vague criteria
                vague_words = ['should', 'might', 'could', 'maybe', 'probably']
                if any(word in criterion.lower() for word in vague_words):
                    self.warnings.append(
                        f"Story {story_id}, criterion {i+1}: Contains vague language: '{criterion[:50]}...'"
                    )

                # Check criteria is specific enough
                if len(criterion) < 10:
                    self.warnings.append(
                        f"Story {story_id}, criterion {i+1}: Very short, may be too vague"
                    )

    def get_summary(self) -> str:
        """Get validation summary"""
        is_valid, errors, warnings = self.validate()

        lines = []
        lines.append("=" * 60)
        lines.append("PRD VALIDATION SUMMARY")
        lines.append("=" * 60)

        if is_valid:
            lines.append("✅ VALID - PRD passed all validation checks")
        else:
            lines.append(f"❌ INVALID - {len(errors)} error(s) found")

        lines.append("")
        lines.append(f"Total Stories: {len(self.prd.get('stories', []))}")
        lines.append(f"Errors: {len(errors)}")
        lines.append(f"Warnings: {len(warnings)}")

        if errors:
            lines.append("")
            lines.append("ERRORS:")
            for error in errors:
                lines.append(f"  ❌ {error}")

        if warnings:
            lines.append("")
            lines.append("WARNINGS:")
            for warning in warnings[:10]:  # Limit to 10
                lines.append(f"  ⚠️  {warning}")

            if len(warnings) > 10:
                lines.append(f"  ... and {len(warnings) - 10} more warnings")

        lines.append("=" * 60)

        return '\n'.join(lines)


def validate_prd_file(prd_path: str) -> bool:
    """
    Validate a PRD file

    Args:
        prd_path: Path to PRD JSON file

    Returns:
        True if valid, False otherwise
    """
    try:
        validator = PRDValidator(prd_path=prd_path)
        is_valid, errors, warnings = validator.validate()

        print(validator.get_summary())

        return is_valid

    except FileNotFoundError:
        print(f"❌ PRD file not found: {prd_path}")
        return False
    except json.JSONDecodeError:
        print(f"❌ Invalid JSON in PRD file: {prd_path}")
        return False
    except Exception as e:
        print(f"❌ Error validating PRD: {e}")
        return False


def main():
    """CLI entry point"""
    import sys
    import argparse

    parser = argparse.ArgumentParser(description="Validate PRD JSON file")
    parser.add_argument('prd_file', help="Path to PRD JSON file")

    args = parser.parse_args()

    is_valid = validate_prd_file(args.prd_file)

    sys.exit(0 if is_valid else 1)


if __name__ == "__main__":
    main()
