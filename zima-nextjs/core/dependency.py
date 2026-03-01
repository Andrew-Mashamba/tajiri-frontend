"""
Zima Looper - Dependency Detection
Detects and manages story dependencies
"""

import re
from typing import List, Set, Dict, Optional
from dataclasses import dataclass


@dataclass
class Dependency:
    """Story dependency"""
    story_id: int
    depends_on_story_number: int
    dependency_type: str  # 'requires', 'depends_on', 'after'
    extracted_from: str  # The acceptance criterion text


class DependencyDetector:
    """
    Detects dependencies between stories by parsing acceptance criteria
    """

    def __init__(self):
        """Initialize dependency detector"""

        # Dependency patterns to match in acceptance criteria
        self.dependency_patterns = [
            # "Requires Story 23 complete"
            (r'requires?\s+story\s+(\d+)', 'requires'),
            # "Depends on Story 5"
            (r'depends?\s+on\s+story\s+(\d+)', 'depends_on'),
            # "After Story 10"
            (r'after\s+story\s+(\d+)', 'after'),
            # "Story 15 must be complete"
            (r'story\s+(\d+)\s+must\s+be\s+complete', 'requires'),
            # "Needs Story 8"
            (r'needs?\s+story\s+(\d+)', 'requires'),
            # "Following Story 12"
            (r'following\s+story\s+(\d+)', 'after'),
        ]

    def detect_dependencies(self, story: Dict) -> List[Dependency]:
        """
        Detect dependencies for a story

        Args:
            story: Story dictionary with acceptance_criteria

        Returns:
            List of Dependency objects
        """
        dependencies = []

        acceptance_criteria = story.get('acceptance_criteria', [])
        if isinstance(acceptance_criteria, str):
            import json
            try:
                acceptance_criteria = json.loads(acceptance_criteria)
            except:
                acceptance_criteria = []

        for criterion in acceptance_criteria:
            if not isinstance(criterion, str):
                continue

            # Check each pattern
            for pattern, dep_type in self.dependency_patterns:
                matches = re.finditer(pattern, criterion, re.IGNORECASE)

                for match in matches:
                    depends_on = int(match.group(1))

                    # Don't create self-dependencies
                    if depends_on != story['story_number']:
                        dependencies.append(Dependency(
                            story_id=story['id'],
                            depends_on_story_number=depends_on,
                            dependency_type=dep_type,
                            extracted_from=criterion
                        ))

        return dependencies

    def detect_all_dependencies(self, stories: List[Dict]) -> Dict[int, List[Dependency]]:
        """
        Detect dependencies for all stories

        Args:
            stories: List of story dictionaries

        Returns:
            Dictionary mapping story_id to list of dependencies
        """
        dependency_map = {}

        for story in stories:
            deps = self.detect_dependencies(story)
            if deps:
                dependency_map[story['id']] = deps

        return dependency_map

    def get_prerequisite_stories(self, story: Dict, stories: List[Dict]) -> List[int]:
        """
        Get list of story numbers that must complete before this story

        Args:
            story: Story dictionary
            stories: All stories in project

        Returns:
            List of prerequisite story numbers
        """
        dependencies = self.detect_dependencies(story)
        return [dep.depends_on_story_number for dep in dependencies]

    def are_dependencies_met(
        self,
        story: Dict,
        stories: List[Dict]
    ) -> bool:
        """
        Check if all dependencies for a story are met

        Args:
            story: Story to check
            stories: All stories in project

        Returns:
            True if all dependencies are met
        """
        dependencies = self.detect_dependencies(story)

        if not dependencies:
            return True  # No dependencies

        # Build map of story_number → status
        status_map = {s['story_number']: s['status'] for s in stories}

        # Check if all dependencies are completed
        for dep in dependencies:
            prerequisite_status = status_map.get(dep.depends_on_story_number)

            if prerequisite_status != 'completed':
                return False

        return True

    def get_ready_stories(self, stories: List[Dict]) -> List[Dict]:
        """
        Get stories that are pending and have all dependencies met

        Args:
            stories: All stories in project

        Returns:
            List of stories ready to execute
        """
        ready_stories = []

        pending_stories = [s for s in stories if s['status'] == 'pending']

        for story in pending_stories:
            if self.are_dependencies_met(story, stories):
                ready_stories.append(story)

        return ready_stories

    def build_dependency_graph(self, stories: List[Dict]) -> Dict[int, Set[int]]:
        """
        Build dependency graph for topological sorting

        Args:
            stories: All stories

        Returns:
            Dictionary mapping story_number to set of prerequisite story_numbers
        """
        graph = {}

        for story in stories:
            prerequisites = self.get_prerequisite_stories(story, stories)
            graph[story['story_number']] = set(prerequisites)

        return graph

    def topological_sort(self, stories: List[Dict]) -> List[int]:
        """
        Sort stories by dependencies (topological sort)

        Args:
            stories: All stories

        Returns:
            List of story numbers in execution order
        """
        graph = self.build_dependency_graph(stories)

        # Kahn's algorithm for topological sort
        in_degree = {story['story_number']: 0 for story in stories}

        # Calculate in-degrees
        for story_num, prerequisites in graph.items():
            for prereq in prerequisites:
                if prereq in in_degree:
                    in_degree[story_num] += 1

        # Queue of stories with no dependencies
        queue = [num for num, degree in in_degree.items() if degree == 0]
        result = []

        while queue:
            # Sort by story number for consistent ordering
            queue.sort()

            current = queue.pop(0)
            result.append(current)

            # Reduce in-degree for dependent stories
            for story_num, prerequisites in graph.items():
                if current in prerequisites:
                    in_degree[story_num] -= 1
                    if in_degree[story_num] == 0:
                        queue.append(story_num)

        # Check for cycles
        if len(result) != len(stories):
            print("⚠️  Warning: Circular dependencies detected!")
            # Return remaining stories in original order
            remaining = [s['story_number'] for s in stories if s['story_number'] not in result]
            result.extend(sorted(remaining))

        return result

    def validate_dependencies(self, stories: List[Dict]) -> List[str]:
        """
        Validate dependencies (check for invalid references, cycles, etc.)

        Args:
            stories: All stories

        Returns:
            List of validation warnings
        """
        warnings = []

        story_numbers = {s['story_number'] for s in stories}

        # Check for invalid dependencies
        for story in stories:
            dependencies = self.detect_dependencies(story)

            for dep in dependencies:
                # Check if prerequisite story exists
                if dep.depends_on_story_number not in story_numbers:
                    warnings.append(
                        f"Story {story['story_number']}: References non-existent Story {dep.depends_on_story_number}"
                    )

                # Check for forward dependencies (warning, not error)
                if dep.depends_on_story_number > story['story_number']:
                    warnings.append(
                        f"Story {story['story_number']}: Forward dependency on Story {dep.depends_on_story_number} "
                        f"(may cause delays)"
                    )

        # Check for circular dependencies
        graph = self.build_dependency_graph(stories)
        if self._has_cycle(graph):
            warnings.append("Circular dependencies detected! Some stories may never execute.")

        return warnings

    def _has_cycle(self, graph: Dict[int, Set[int]]) -> bool:
        """Check if dependency graph has cycles using DFS"""

        visited = set()
        rec_stack = set()

        def dfs(node):
            visited.add(node)
            rec_stack.add(node)

            for neighbor in graph.get(node, set()):
                if neighbor not in visited:
                    if dfs(neighbor):
                        return True
                elif neighbor in rec_stack:
                    return True

            rec_stack.remove(node)
            return False

        for node in graph:
            if node not in visited:
                if dfs(node):
                    return True

        return False

    def print_dependency_report(self, stories: List[Dict]):
        """Print dependency analysis report"""

        print("\n" + "="*60)
        print("DEPENDENCY ANALYSIS")
        print("="*60 + "\n")

        dependency_map = self.detect_all_dependencies(stories)

        if not dependency_map:
            print("✓ No dependencies detected\n")
            return

        print(f"Found dependencies for {len(dependency_map)} story/stories:\n")

        for story in stories:
            if story['id'] in dependency_map:
                deps = dependency_map[story['id']]
                print(f"Story {story['story_number']}: {story['title']}")
                for dep in deps:
                    print(f"  → Depends on Story {dep.depends_on_story_number} ({dep.dependency_type})")
                    print(f"     From: \"{dep.extracted_from[:60]}...\"")
                print()

        # Validate
        warnings = self.validate_dependencies(stories)
        if warnings:
            print("⚠️  Warnings:")
            for warning in warnings:
                print(f"  - {warning}")
            print()

        # Show execution order
        sorted_order = self.topological_sort(stories)
        print("Recommended execution order:")
        print("  " + " → ".join(f"Story {num}" for num in sorted_order[:10]))
        if len(sorted_order) > 10:
            print(f"  ... and {len(sorted_order) - 10} more")
        print()

        print("="*60 + "\n")
