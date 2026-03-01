"""
Zima Looper - PRD Generator
Generates Product Requirements Documents from README files using Claude CLI
"""

import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Optional

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from prd.parser import ReadmeParser
from prd.project_analyzer import ProjectAnalyzer, ProjectInventory
from prd.comparator import ImplementationComparator, ComparisonResult
from execution.claude_wrapper import ClaudeWrapper, ClaudeResponse
from core.database import get_db
from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()


class PRDGenerator:
    """Generate PRD from README using two-phase Claude analysis"""

    def __init__(self, readme_path: str, output_path: Optional[str] = None):
        """
        Initialize PRD generator

        Args:
            readme_path: Path to README.md
            output_path: Optional output path for generated PRD
        """
        self.readme_path = Path(readme_path)
        self.output_path = Path(output_path) if output_path else self.readme_path.parent / "prd.json"

        if not self.readme_path.exists():
            raise FileNotFoundError(f"README not found: {readme_path}")

        self.parser = ReadmeParser(str(self.readme_path))
        self.claude = ClaudeWrapper(model="sonnet", timeout=1200)  # 20 min for complex analysis

    def generate(self) -> Dict:
        """
        Generate complete PRD from README

        Returns:
            PRD dictionary
        """
        console.print(f"\n[cyan]🔍 Analyzing README:[/cyan] {self.readme_path}")

        # Phase 0: Analyze existing implementation
        project_dir = self.readme_path.parent
        console.print(f"\n[cyan]📂 Scanning project directory:[/cyan] {project_dir}")

        inventory = None
        comparison = None

        try:
            analyzer = ProjectAnalyzer(str(project_dir))
            inventory = analyzer.analyze()

            if inventory.has_existing_code:
                console.print(f"[yellow]⚠️  Existing implementation detected![/yellow]")
                console.print(analyzer.generate_summary(inventory))

                # Compare README vs existing implementation
                console.print("\n[cyan]🔍 Comparing README requirements with existing code...[/cyan]")

                with open(self.readme_path, 'r') as f:
                    readme_content = f.read()

                comparator = ImplementationComparator()
                comparison = comparator.compare(readme_content, inventory)

                console.print(comparator.generate_summary(comparison))
                console.print(f"[cyan]💡 Will generate PRD for remaining work only ({comparison.total_gaps} gaps)[/cyan]")
            else:
                console.print(f"[green]✓[/green] No existing code found. Starting from scratch.")

        except Exception as e:
            console.print(f"[yellow]Warning: Could not analyze existing code: {e}[/yellow]")
            console.print("[cyan]Continuing with full PRD generation...[/cyan]")

        # Phase 1: Parse README
        with console.status("[yellow]Parsing README structure..."):
            readme_data = self.parser.parse()

        console.print(f"[green]✓[/green] Parsed README: {len(readme_data['features'])} features found")

        # Phase 2: Claude analysis
        console.print("\n[cyan]🤖 Phase 1: Analyzing project requirements with Claude...[/cyan]")
        analysis = self._analyze_readme(readme_data)

        if not analysis:
            console.print("[red]✗[/red] Failed to analyze README")
            return None

        console.print(f"[green]✓[/green] Analysis complete")

        # Phase 3: Generate stories (considering existing implementation)
        console.print("\n[cyan]🤖 Phase 2: Generating implementation stories...[/cyan]")
        stories = self._generate_stories(readme_data, analysis, comparison)

        if not stories:
            console.print("[red]✗[/red] Failed to generate stories")
            return None

        console.print(f"[green]✓[/green] Generated {len(stories)} stories")

        # Build complete PRD
        prd = self._build_prd(readme_data, analysis, stories, inventory, comparison)

        # Save to file
        self._save_prd(prd)

        console.print(f"\n[green]✅ PRD saved to:[/green] {self.output_path}")

        return prd

    def _analyze_readme(self, readme_data: Dict) -> Optional[Dict]:
        """
        Phase 1: Analyze README and extract requirements using Claude

        Args:
            readme_data: Parsed README data

        Returns:
            Analysis dictionary
        """
        prompt = self._build_analysis_prompt(readme_data)

        response = self.claude.call(
            prompt=prompt,
            output_format="json",
            max_tokens=4096
        )

        if not response.success:
            console.print(f"[red]Error:[/red] {response.error}")
            return None

        # Parse Claude's JSON response
        try:
            analysis = json.loads(response.output)
            return analysis
        except json.JSONDecodeError:
            # Try to extract JSON from response
            json_match = response.output.find('{')
            if json_match != -1:
                try:
                    analysis = json.loads(response.output[json_match:])
                    return analysis
                except:
                    pass

            console.print("[yellow]Warning: Could not parse analysis as JSON. Using raw response.[/yellow]")
            return {'raw_analysis': response.output}

    def _generate_stories(self, readme_data: Dict, analysis: Dict, comparison: Optional[ComparisonResult] = None) -> Optional[List[Dict]]:
        """
        Phase 2: Generate implementation stories using Claude

        Args:
            readme_data: Parsed README data
            analysis: Analysis from Phase 1
            comparison: Optional comparison result if existing code found

        Returns:
            List of story dictionaries
        """
        prompt = self._build_stories_prompt(readme_data, analysis, comparison)

        response = self.claude.call(
            prompt=prompt,
            output_format="json",
            max_tokens=8192  # More tokens for story generation
        )

        if not response.success:
            console.print(f"[red]Error:[/red] {response.error}")
            return None

        # Parse stories JSON
        try:
            stories_data = json.loads(response.output)

            # Handle different response formats
            if isinstance(stories_data, dict) and 'stories' in stories_data:
                return stories_data['stories']
            elif isinstance(stories_data, list):
                return stories_data
            else:
                console.print("[yellow]Warning: Unexpected stories format[/yellow]")
                console.print(f"[dim]Received type: {type(stories_data)}[/dim]")
                return None

        except json.JSONDecodeError as e:
            console.print(f"[red]Error:[/red] Could not parse stories JSON: {e}")
            console.print(f"[dim]Response preview (first 500 chars):[/dim]")
            console.print(f"[dim]{response.output[:500]}...[/dim]")

            # Try to extract JSON from markdown code blocks
            if '```json' in response.output:
                try:
                    json_start = response.output.find('```json') + 7
                    json_end = response.output.find('```', json_start)
                    json_str = response.output[json_start:json_end].strip()
                    stories_data = json.loads(json_str)

                    if isinstance(stories_data, dict) and 'stories' in stories_data:
                        console.print("[yellow]✓ Extracted JSON from markdown code block[/yellow]")
                        return stories_data['stories']
                    elif isinstance(stories_data, list):
                        console.print("[yellow]✓ Extracted JSON from markdown code block[/yellow]")
                        return stories_data
                except:
                    pass

            return None

    def _build_analysis_prompt(self, readme_data: Dict) -> str:
        """Build minimal analysis prompt (token-optimized)."""
        max_chars = 5000
        content = (readme_data.get('full_content') or '')[:max_chars]
        return f"""README: {readme_data.get('project_name', '')}
{readme_data.get('description', '')[:500]}

Content:
{content}

Output JSON only (no markdown):
{{"overview": {{"problem": "", "users": "", "value": ""}}, "technical": {{"framework": "", "database": "", "integrations": []}}, "features": [{{"name": "", "components": [], "dependencies": []}}], "database": {{"tables": [{{"name": "", "columns": [], "relationships": []}}]}}, "user_flows": [], "external_services": [], "testing": {{"unit_tests": [], "feature_tests": []}}}}"""

    def _build_stories_prompt(self, readme_data: Dict, analysis: Dict, comparison: Optional[ComparisonResult] = None) -> str:
        """Build minimal stories prompt (token-optimized)."""
        max_analysis = 4000
        analysis_str = json.dumps(analysis, indent=0)[:max_analysis]
        existing = ""
        if comparison and comparison.has_existing_code:
            existing = f"Existing: {comparison.completion_percentage}% done. Gaps: {self._format_gaps(comparison.gaps) if comparison.gaps else 'none'}. Generate stories only for missing work.\n"
        return f"""Project: {readme_data['project_name']}
Stack: Laravel, Livewire, Tailwind, SQLite. Layout: app-layout, app-header, app-sidebar. Routes: /dashboard, /users, /reports.
{existing}
Analysis:
{analysis_str}

Output JSON only. One array "stories" of objects: id, title, description (1 sentence), acceptance (5-10 testable items), priority, estimate_hours. Be specific (file paths, routes). No markdown."""

    def _format_list(self, items: List[str]) -> str:
        """Format list items for prompt"""
        if not items:
            return "(none)"

        return '\n'.join(f"- {item}" for item in items[:20])  # Limit to 20 items

    def _format_gaps(self, gaps: List) -> str:
        """Format implementation gaps for prompt"""
        if not gaps:
            return "(none)"

        formatted = []
        for gap in gaps[:15]:  # Limit to 15 gaps
            priority_label = {1: "HIGH", 2: "MEDIUM", 3: "LOW"}.get(gap.priority, "NORMAL")
            formatted.append(f"- [{priority_label}] {gap.description} (~{gap.estimated_hours}h)")

        return '\n'.join(formatted)

    def _get_story_count_guidance(self, comparison: Optional[ComparisonResult]) -> str:
        """Get guidance on how many stories to generate"""
        if not comparison or not comparison.has_existing_code:
            return "as many stories as needed based on project complexity (no artificial limits - let the requirements dictate the number)"

        # Adjust based on remaining work
        completion = comparison.completion_percentage
        if completion >= 75:
            return "as many stories as needed to complete the remaining work - analyze what's missing and create appropriate stories"
        elif completion >= 50:
            return "as many stories as needed to complete the remaining work - thoroughly cover all incomplete features"
        elif completion >= 25:
            return "as many stories as needed to complete the remaining work - create comprehensive coverage of all gaps"
        else:
            return "as many stories as needed to complete the remaining work - extensive coverage required for mostly-incomplete project"

    def _build_prd(
        self,
        readme_data: Dict,
        analysis: Dict,
        stories: List[Dict],
        inventory: Optional[ProjectInventory] = None,
        comparison: Optional[ComparisonResult] = None
    ) -> Dict:
        """Build complete PRD structure"""
        prd = {
            'projectName': readme_data['project_name'],
            'description': readme_data['description'],
            'branchName': f"feature/{readme_data['project_name'].lower().replace(' ', '-')}",
            'techStack': readme_data['tech_stack'],
            'readme_path': str(self.readme_path),
            'analysis': analysis,
            'stories': stories,
            'total_stories': len(stories),
            'total_estimate_hours': sum(s.get('estimate_hours', 1.0) for s in stories)
        }

        # Add existing implementation data if available
        if inventory and inventory.has_existing_code:
            prd['existing_implementation'] = inventory.to_dict()

        if comparison and comparison.has_existing_code:
            prd['completion_analysis'] = comparison.to_dict()

        return prd

    def _save_prd(self, prd: Dict):
        """Save PRD to JSON file"""
        self.output_path.parent.mkdir(parents=True, exist_ok=True)

        with open(self.output_path, 'w', encoding='utf-8') as f:
            json.dump(prd, f, indent=2, ensure_ascii=False)


def main():
    """CLI entry point for PRD generation"""
    import argparse

    parser = argparse.ArgumentParser(description="Generate PRD from README using Claude")
    parser.add_argument('--readme', required=True, help="Path to README.md")
    parser.add_argument('--output', help="Output path for PRD (default: README_DIR/prd.json)")

    args = parser.parse_args()

    try:
        generator = PRDGenerator(args.readme, args.output)
        prd = generator.generate()

        if prd:
            console.print("\n[green]✅ PRD generation complete![/green]")
            console.print(f"   Stories: {prd['total_stories']}")
            console.print(f"   Estimated hours: {prd['total_estimate_hours']:.1f}h")
            sys.exit(0)
        else:
            console.print("\n[red]❌ PRD generation failed[/red]")
            sys.exit(1)

    except Exception as e:
        console.print(f"\n[red]Error:[/red] {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
