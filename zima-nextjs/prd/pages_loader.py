"""
Zima Next.js - Pages Loader
Loads scaffold pages from PAGES-TO-IMPLEMENT.md and converts to stories for execution.
"""

import re
import json
import sys
import os
from pathlib import Path
from typing import Dict, List, Optional

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()

# Standard acceptance criteria for each Next.js page implementation (full, functional page)
NEXTJS_ACCEPTANCE_CRITERIA = [
    "Do a real implementation: remove all placeholders, ScaffoldPage, and UnderConstruction content",
    "Get business logic from docs/prd.json and by studying existing code in the codebase",
    "Get design rules from docs/stories/DESIGN-SYSTEM.md (layout, spacing, colors, components)",
    "Implement the page fully so it is functional end-to-end (no stubs)",
    "Place or move the page in its proper module folder; integrate with existing module and system code",
    "Use shared sidebar and topbar (DashboardLayout) so the page fits the app shell",
    "Use existing components, APIs, and patterns where possible; add new backend APIs or components only when needed",
    "Implement business logic from the PRD for this feature (multi-step flows where applicable)",
    "Design system alignment: layout, spacing, typography, and tokens from DESIGN-SYSTEM.md",
    "Integration: auth (e.g. accessToken check, redirect to /login), validation, error handling, loading states",
    "Add or reuse forms, tables, workflows as required by the feature",
    "Fix all lint errors on the implemented page and any files you touch",
    "When the page is done, mark it as done in docs/PAGES-TO-IMPLEMENT.md (add ✅ to the line for this route)",
]


def parse_pages_file(pages_path: str) -> List[str]:
    """
    Parse PAGES-TO-IMPLEMENT.md and extract scaffold page routes.

    Looks for lines like:
    - `/accounting/approve-reject-request`
    - `/deposits/view-account-details`

    Excludes completed lines (with ✅) and section headers.

    Returns:
        List of route paths (e.g. ['/accounting/approve-reject-request', ...])
    """
    with open(pages_path, "r", encoding="utf-8") as f:
        content = f.read()

    routes = []
    # Match lines like: - `/path/to/page` or - `/path/to/page`
    pattern = re.compile(r'^-\s+`(/[^`]+)`\s*$', re.MULTILINE)

    in_scaffold_section = False
    for line in content.split("\n"):
        line_stripped = line.strip()
        # Start capturing after "## 1) Scaffold Pages"
        if "Scaffold Pages" in line and "no business logic" in line.lower():
            in_scaffold_section = True
            continue
        # Stop at next ## section
        if in_scaffold_section and line.startswith("## "):
            break
        if not in_scaffold_section:
            continue

        # Skip empty lines, skip completed (✅)
        if not line_stripped or "✅" in line_stripped:
            continue

        match = re.match(r'^-\s+`(/[^`]+)`\s*$', line_stripped)
        if match:
            route = match.group(1)
            if route and not route.startswith("/page"):
                routes.append(route)

    return routes


def route_to_story(route: str, story_number: int) -> Dict:
    """
    Convert a route path to a story dictionary.

    Args:
        route: e.g. /accounting/approve-reject-request
        story_number: 1-based story number

    Returns:
        Story dict compatible with db.create_story
    """
    # Derive title from route: /accounting/approve-reject-request -> Approve Reject Request
    parts = route.strip("/").split("/")
    module = parts[0] if parts else "app"
    slug = parts[-1] if len(parts) > 1 else parts[0]
    title_slug = slug.replace("-", " ").title()

    title = f"Implement {route}"
    description = (
        f"Implement the page at {route} as a fully functional feature. "
        f"Remove all placeholders and Under Construction content. "
        f"Get business logic from docs/prd.json and by studying existing code. "
        f"Apply design rules from docs/stories/DESIGN-SYSTEM.md. "
        f"Use DashboardLayout (shared sidebar and topbar), existing components and APIs, and proper auth, validation, error handling, and loading states. "
        f"When done, mark the page as done in docs/PAGES-TO-IMPLEMENT.md and fix all lint errors."
    )

    # File path in Next.js app router
    # /accounting/approve-reject-request -> frontend/src/app/accounting/approve-reject-request/page.tsx
    page_path = f"frontend/src/app{route}/page.tsx"

    acceptance = list(NEXTJS_ACCEPTANCE_CRITERIA) + [
        f"Page file: {page_path}",
        f"Route: {route}",
    ]

    return {
        "id": story_number,
        "story_number": story_number,
        "title": title,
        "description": description,
        "acceptance": acceptance,
        "priority": 1,
        "estimate_hours": 0.5,
        "route": route,
        "page_path": page_path,
    }


def load_stories_from_pages(
    pages_path: str,
    output_path: Optional[str] = None,
    project_dir: Optional[str] = None,
    project_name: str = "ENTERPRISESACCOS",
) -> Dict:
    """
    Load scaffold pages from PAGES-TO-IMPLEMENT.md and generate PRD/stories.

    Args:
        pages_path: Path to docs/PAGES-TO-IMPLEMENT.md
        output_path: Optional path to save prd.json
        project_dir: Project root (parent of docs/)
        project_name: Project name for PRD

    Returns:
        PRD dictionary with stories
    """
    pages_path = Path(pages_path)
    if not pages_path.exists():
        raise FileNotFoundError(f"PAGES-TO-IMPLEMENT.md not found: {pages_path}")

    project_dir = project_dir or str(pages_path.parent.parent)
    project_dir = os.path.abspath(project_dir)

    console.print(f"\n[cyan]📄 Loading scaffold pages from:[/cyan] {pages_path}")

    routes = parse_pages_file(str(pages_path))
    console.print(f"[green]✓[/green] Found {len(routes)} scaffold pages")

    if not routes:
        console.print("[yellow]⚠️  No scaffold pages found. Check PAGES-TO-IMPLEMENT.md format.[/yellow]")
        return {"stories": [], "total_stories": 0}

    stories = []
    for i, route in enumerate(routes):
        story = route_to_story(route, i + 1)
        stories.append(story)

    prd = {
        "projectName": project_name,
        "description": "Implement remaining Next.js pages from PAGES-TO-IMPLEMENT.md",
        "techStack": "Next.js, React, TypeScript, Tailwind",
        "readme_path": str(pages_path),
        "prd_path": output_path or str(Path(project_dir) / "docs" / "pages-prd.json"),
        "stories": stories,
        "total_stories": len(stories),
        "total_estimate_hours": sum(s.get("estimate_hours", 0.5) for s in stories),
        "source": "PAGES-TO-IMPLEMENT.md",
    }

    # Save to file if output_path provided
    if output_path:
        out = Path(output_path)
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, "w", encoding="utf-8") as f:
            json.dump(prd, f, indent=2, ensure_ascii=False)
        console.print(f"[green]✓[/green] Saved PRD to: {output_path}")

    return prd


def load_into_database(db, project_name: str, project_dir: str, prd: Dict) -> int:
    """
    Load PRD stories into database (creates project if needed).

    Returns:
        project_id
    """
    existing = db.get_project_by_name(project_name)
    if existing:
        project_id = existing["id"]
        console.print(f"[yellow]Project already exists. Clearing and re-adding stories...[/yellow]")
        with db.get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM stories WHERE project_id = ?", (project_id,))
    else:
        project_id = db.create_project(
            name=project_name,
            directory=os.path.abspath(project_dir),
            readme_path=prd.get("readme_path", ""),
            prd_path=prd.get("prd_path", ""),
        )

    for story in prd.get("stories", []):
        db.create_story(project_id=project_id, story_data=story)

    db.update_project_stats(project_id)
    console.print(f"[green]✓[/green] Loaded {len(prd['stories'])} stories into database")
    return project_id


def main():
    """CLI entry point for loading stories from PAGES-TO-IMPLEMENT.md"""
    import argparse

    parser = argparse.ArgumentParser(
        description="Load scaffold pages from PAGES-TO-IMPLEMENT.md as stories"
    )
    parser.add_argument(
        "--pages",
        default="docs/PAGES-TO-IMPLEMENT.md",
        help="Path to PAGES-TO-IMPLEMENT.md (relative to project root)",
    )
    parser.add_argument(
        "--project-dir",
        default=None,
        help="Project root directory (default: parent of zima-nextjs)",
    )
    parser.add_argument(
        "--output",
        help="Output path for prd.json",
    )
    parser.add_argument(
        "--project-name",
        default="ENTERPRISESACCOS",
        help="Project name",
    )
    parser.add_argument(
        "--no-db",
        action="store_true",
        help="Only generate PRD file, do not load into database",
    )

    args = parser.parse_args()

    # Resolve paths
    script_dir = Path(__file__).resolve().parent.parent
    project_dir = args.project_dir or str(script_dir.parent)  # ENTERPRISESACCOS root
    pages_path = Path(project_dir) / args.pages

    if not pages_path.exists():
        console.print(f"[red]Error:[/red] File not found: {pages_path}")
        sys.exit(1)

    output_path = args.output or str(Path(project_dir) / "docs" / "pages-prd.json")

    try:
        prd = load_stories_from_pages(
            pages_path=str(pages_path),
            output_path=output_path,
            project_dir=project_dir,
            project_name=args.project_name,
        )

        if not args.no_db:
            from core.database import get_db

            db_path = script_dir / "zima.db"
            db = get_db(str(db_path))
            load_into_database(db, args.project_name, project_dir, prd)

        console.print(f"\n[green]✅ Done![/green] {prd['total_stories']} stories loaded.")
        sys.exit(0)

    except Exception as e:
        console.print(f"\n[red]Error:[/red] {e}")
        import traceback

        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
