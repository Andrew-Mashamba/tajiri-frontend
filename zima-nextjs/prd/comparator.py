"""
Zima Looper - Implementation Comparator
Compares README requirements with existing implementation to identify gaps
"""

import os
import sys
import json
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from execution.claude_wrapper import ClaudeWrapper
from prd.project_analyzer import ProjectInventory


@dataclass
class ImplementationGap:
    """
    Represents a gap between requirements and implementation
    """
    category: str  # 'feature', 'route', 'model', 'test', 'configuration'
    description: str
    priority: int  # 1-5 (1 = highest)
    estimated_hours: float


@dataclass
class ComparisonResult:
    """
    Result of comparing README vs existing implementation
    """
    has_existing_code: bool
    completion_percentage: int
    total_gaps: int
    gaps: List[ImplementationGap]
    missing_features: List[str]
    partially_implemented: List[str]
    fully_implemented: List[str]

    def to_dict(self) -> Dict:
        """Convert to dictionary"""
        return {
            'has_existing_code': self.has_existing_code,
            'completion_percentage': self.completion_percentage,
            'total_gaps': self.total_gaps,
            'gaps': [asdict(gap) for gap in self.gaps],
            'missing_features': self.missing_features,
            'partially_implemented': self.partially_implemented,
            'fully_implemented': self.fully_implemented
        }

    def to_json(self) -> str:
        """Convert to JSON string"""
        return json.dumps(self.to_dict(), indent=2)


class ImplementationComparator:
    """
    Compares README requirements with existing implementation using Claude
    """

    def __init__(self, claude_model: str = "sonnet", timeout: int = 180):
        """
        Initialize comparator

        Args:
            claude_model: Claude model to use
            timeout: Timeout in seconds
        """
        self.claude = ClaudeWrapper(model=claude_model, timeout=timeout)

    def compare(
        self,
        readme_content: str,
        inventory: ProjectInventory
    ) -> ComparisonResult:
        """
        Compare README requirements with existing implementation

        Args:
            readme_content: Content of README.md
            inventory: ProjectInventory from analyzer

        Returns:
            ComparisonResult with identified gaps
        """
        if not inventory.has_existing_code:
            # No existing code - everything is a gap
            return ComparisonResult(
                has_existing_code=False,
                completion_percentage=0,
                total_gaps=0,
                gaps=[],
                missing_features=[],
                partially_implemented=[],
                fully_implemented=[]
            )

        # Build comparison prompt
        prompt = self._build_comparison_prompt(readme_content, inventory)

        # Call Claude to analyze
        print("🔍 Analyzing existing implementation vs README requirements...")
        response = self.claude.call(
            prompt=prompt,
            output_format="json",
            max_tokens=4096
        )

        if not response.success:
            raise Exception(f"Claude analysis failed: {response.error}")

        # Parse response
        try:
            comparison_data = json.loads(response.output)
        except json.JSONDecodeError as e:
            raise Exception(f"Failed to parse Claude response: {e}\n{response.output}")

        # Convert to ComparisonResult
        gaps = []
        for gap_data in comparison_data.get('gaps', []):
            gaps.append(ImplementationGap(
                category=gap_data.get('category', 'feature'),
                description=gap_data.get('description', ''),
                priority=gap_data.get('priority', 3),
                estimated_hours=gap_data.get('estimated_hours', 1.0)
            ))

        result = ComparisonResult(
            has_existing_code=True,
            completion_percentage=comparison_data.get('completion_percentage', inventory.estimated_completion),
            total_gaps=len(gaps),
            gaps=gaps,
            missing_features=comparison_data.get('missing_features', []),
            partially_implemented=comparison_data.get('partially_implemented', []),
            fully_implemented=comparison_data.get('fully_implemented', [])
        )

        return result

    def _build_comparison_prompt(
        self,
        readme_content: str,
        inventory: ProjectInventory
    ) -> str:
        """
        Build prompt for Claude to compare README vs implementation

        Args:
            readme_content: README content
            inventory: Project inventory

        Returns:
            Formatted prompt
        """
        max_readme = 4000
        readme_short = (readme_content or "")[:max_readme]
        return f"""README:
{readme_short}

Existing: Controllers {len(inventory.controllers)}, Models {len(inventory.models)}, Migrations {len(inventory.migrations)}, Routes {len(inventory.routes)}, Views {len(inventory.views)}, Tests {len(inventory.tests)}.
{self._format_file_list(inventory.controllers[:8])}
{self._format_file_list(inventory.models[:8])}

Output JSON only:
{{"completion_percentage": 0, "fully_implemented": [], "partially_implemented": [], "missing_features": [], "gaps": [{{"category": "feature", "description": "", "priority": 1, "estimated_hours": 0}}]}}
"""

    def _format_file_list(self, files: List[str]) -> str:
        """Format file list for prompt"""
        if not files:
            return "  (none)"
        return "\n".join(f"  - {file}" for file in files)

    def _format_dependency_list(self, dependencies: List[str]) -> str:
        """Format dependency list for prompt"""
        if not dependencies:
            return "  (none)"
        return "\n".join(f"  - {dep}" for dep in dependencies)

    def generate_summary(self, result: ComparisonResult) -> str:
        """
        Generate human-readable summary of comparison

        Args:
            result: ComparisonResult object

        Returns:
            Formatted summary string
        """
        if not result.has_existing_code:
            return "No existing implementation found. Will generate full PRD."

        summary = []
        summary.append("=" * 60)
        summary.append("IMPLEMENTATION GAP ANALYSIS")
        summary.append("=" * 60)
        summary.append(f"\nProject Completion: {result.completion_percentage}%")
        summary.append(f"Total Gaps Identified: {result.total_gaps}\n")

        if result.fully_implemented:
            summary.append("✅ Fully Implemented:")
            summary.append("-" * 60)
            for feature in result.fully_implemented:
                summary.append(f"  ✓ {feature}")
            summary.append("")

        if result.partially_implemented:
            summary.append("⚠️  Partially Implemented:")
            summary.append("-" * 60)
            for feature in result.partially_implemented:
                summary.append(f"  ⚡ {feature}")
            summary.append("")

        if result.missing_features:
            summary.append("❌ Missing Features:")
            summary.append("-" * 60)
            for feature in result.missing_features:
                summary.append(f"  ✗ {feature}")
            summary.append("")

        if result.gaps:
            summary.append("🔧 Work Required:")
            summary.append("-" * 60)

            # Group by category
            gaps_by_category = {}
            for gap in result.gaps:
                if gap.category not in gaps_by_category:
                    gaps_by_category[gap.category] = []
                gaps_by_category[gap.category].append(gap)

            for category, gaps in gaps_by_category.items():
                summary.append(f"\n  {category.upper()}:")
                for gap in sorted(gaps, key=lambda x: x.priority):
                    priority_label = {1: "🔴 HIGH", 2: "🟡 MEDIUM", 3: "🟢 LOW"}.get(gap.priority, "⚪ NORMAL")
                    summary.append(f"    [{priority_label}] {gap.description}")
                    summary.append(f"              Estimate: {gap.estimated_hours}h")

        # Calculate total hours
        total_hours = sum(gap.estimated_hours for gap in result.gaps)
        summary.append(f"\n{'=' * 60}")
        summary.append(f"Total Estimated Hours: {total_hours:.1f}h")
        summary.append(f"{'=' * 60}\n")

        return "\n".join(summary)


def main():
    """Test comparator"""
    if len(sys.argv) < 3:
        print("Usage: python3 comparator.py <readme_path> <inventory_json_path>")
        sys.exit(1)

    readme_path = sys.argv[1]
    inventory_path = sys.argv[2]

    # Read README
    with open(readme_path, 'r') as f:
        readme_content = f.read()

    # Load inventory
    with open(inventory_path, 'r') as f:
        inventory_data = json.load(f)

    # Convert to ProjectInventory
    inventory = ProjectInventory(**inventory_data)

    # Compare
    comparator = ImplementationComparator()
    result = comparator.compare(readme_content, inventory)

    # Print summary
    print(comparator.generate_summary(result))

    # Save result
    output_path = "zima-comparison.json"
    with open(output_path, 'w') as f:
        f.write(result.to_json())

    print(f"Comparison saved to: {output_path}")


if __name__ == '__main__':
    main()
