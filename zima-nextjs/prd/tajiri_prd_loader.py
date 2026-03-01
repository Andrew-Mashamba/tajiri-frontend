"""
TAJIRI PRD Loader
Loads stories from TAJIRI's docs/prd.json (Flutter app format).
Maps stories to Flutter screens/services/widgets and enriches with design/navigation refs.
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Optional

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from rich.console import Console
from rich.progress import Progress, SpinnerColumn, TextColumn

console = Console()

# Module -> Flutter folder mapping (TAJIRI lib structure)
MODULE_TO_FLUTTER = {
    "Auth": "lib/screens/registration",
    "Profiles": "lib/screens/profile",
    "Reference Data": "lib/screens/registration",  # school/location pickers
    "Content": "lib/screens/feed",
    "Social": "lib/screens/friends",
    "Communities": "lib/screens/groups",
    "Media": "lib/screens/clips",
    "Communication": "lib/screens/messages",
    "Payments": "lib/screens/wallet",
    "Discovery": "lib/screens/search",
    "Settings": "lib/screens/settings",
    "UI Shell": "lib/screens/splash",
}


def _story_to_flutter_target(story: Dict) -> str:
    """Derive Flutter file/screen target from story metadata."""
    module = story.get("module", "")
    title = story.get("title", "")
    access = story.get("access_route") or {}
    flutter_screen = access.get("flutter_screen", "")

    if flutter_screen:
        # e.g. ProfileScreen -> lib/screens/profile/profile_screen.dart
        slug = flutter_screen.replace("Screen", "").lower()
        if "profile" in slug:
            return "lib/screens/profile/profile_screen.dart"
        if "feed" in slug or "home" in slug:
            return "lib/screens/feed/feed_screen.dart"
        if "registration" in slug:
            return "lib/screens/registration/registration_screen.dart"
        if "splash" in slug:
            return "lib/screens/splash/splash_screen.dart"
        # Generic: ProfileScreen -> profile_screen.dart in module folder
        folder = MODULE_TO_FLUTTER.get(module, "lib/screens")
        return f"{folder}/{slug}_screen.dart"

    folder = MODULE_TO_FLUTTER.get(module, "lib")
    # Widgets, services: infer from title
    if "service" in title.lower() or "api" in title.lower():
        return f"lib/services/"
    if "widget" in title.lower() or "picker" in title.lower():
        return f"lib/widgets/"
    return folder


def _enrich_acceptance(story: Dict) -> List[str]:
    """Prepend design/navigation refs and directives to acceptance criteria."""
    base = list(story.get("acceptance") or [])
    enriched = []

    # Required references (every TAJIRI story)
    enriched.append("Design reference: DOCS/DESIGN.md (layout, touch targets 48dp min, colors)")
    enriched.append("Navigation reference: DOCS/NAVIGATION.md (how users reach this feature)")

    nav_path = story.get("navigation_path")
    if nav_path:
        enriched.append(f"Navigation path: {nav_path}")

    impl_notes = story.get("implementation_notes")
    if impl_notes:
        enriched.append(f"Implementation notes: {impl_notes}")

    # Flutter target hint
    target = _story_to_flutter_target(story)
    if target:
        enriched.append(f"Flutter target: {target}")

    # Implementation directives (from PRD story_rules)
    enriched.append("Before implementing: Check if a similar story/implementation exists. If exists → improve it; if not → implement from scratch; if exists and complete → skip to next task. Always use existing code when applicable.")
    enriched.append("After implementing, recheck that all story business logic is fully implemented.")
    enriched.append("Check and fix any lint errors in files you touched.")
    enriched.append("If this story requires backend data or sends data to backend: Append to docs/BACKEND.md all API endpoints, request/response formats, and expectations this story requires.")

    enriched.extend(base)
    return enriched


def load_tajiri_prd(
    prd_path: str,
    output_path: Optional[str] = None,
    project_dir: Optional[str] = None,
    project_name: str = "TAJIRI",
) -> Dict:
    """
    Load TAJIRI PRD from docs/prd.json and convert to Zima story format.

    Args:
        prd_path: Path to docs/prd.json (or DOCS/prd.json)
        output_path: Optional path to save converted PRD
        project_dir: Project root (parent of docs/)
        project_name: Project name

    Returns:
        PRD dictionary with stories compatible with db.create_story
    """
    prd_path = Path(prd_path)
    if not prd_path.exists():
        raise FileNotFoundError(f"PRD not found: {prd_path}")

    project_dir = project_dir or str(prd_path.parent.parent)
    project_dir = os.path.abspath(project_dir)

    with open(prd_path, "r", encoding="utf-8") as f:
        data = json.load(f)

    project_section = data.get("project", {})
    stories_raw = data.get("stories", [])

    console.print(f"\n[cyan]📄 Loading TAJIRI PRD from:[/cyan] {prd_path}")
    console.print(f"[cyan]   Project:[/cyan] {project_section.get('name', project_name)}")

    stories = []
    for s in stories_raw:
        sid = s.get("id")
        if sid is None:
            continue
        enriched_acceptance = _enrich_acceptance(s)
        story = {
            "id": sid,
            "story_number": sid,
            "title": s.get("title", f"Story {sid}"),
            "description": s.get("description", ""),
            "acceptance": enriched_acceptance,
            "priority": s.get("priority", sid),
            "estimate_hours": s.get("estimate_hours", 2.0),
            "module": s.get("module", ""),
            "epic": s.get("epic", ""),
            "navigation_path": s.get("navigation_path", ""),
        }
        stories.append(story)

    prd = {
        "projectName": project_name,
        "description": project_section.get("description", "TAJIRI Flutter social platform"),
        "techStack": "Flutter, Dart, Material 3",
        "readme_path": str(Path(project_dir) / "README.md"),
        "prd_path": str(prd_path),
        "stories": stories,
        "total_stories": len(stories),
        "total_estimate_hours": sum(s.get("estimate_hours", 2.0) for s in stories),
        "source": "docs/prd.json",
        "project_type": "flutter",
    }

    if output_path:
        out = Path(output_path)
        out.parent.mkdir(parents=True, exist_ok=True)
        with open(out, "w", encoding="utf-8") as f:
            json.dump(prd, f, indent=2, ensure_ascii=False)
        console.print(f"[green]✓[/green] Saved converted PRD to: {output_path}")

    return prd


def load_into_database(db, project_name: str, project_dir: str, prd: Dict) -> int:
    """Load PRD stories into database. Returns project_id."""
    existing = db.get_project_by_name(project_name)
    if existing:
        project_id = existing["id"]
        console.print("[yellow]Project already exists. Clearing and re-adding stories...[/yellow]")
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
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Load TAJIRI PRD from docs/prd.json as stories"
    )
    parser.add_argument(
        "--prd",
        default="docs/prd.json",
        help="Path to prd.json (relative to project-dir)",
    )
    parser.add_argument(
        "--project-dir",
        default=None,
        help="Project root (default: parent of zima-nextjs)",
    )
    parser.add_argument(
        "--output",
        help="Output path for converted prd",
    )
    parser.add_argument(
        "--project-name",
        default="TAJIRI",
        help="Project name",
    )
    parser.add_argument(
        "--no-db",
        action="store_true",
        help="Only convert PRD, do not load into database",
    )

    args = parser.parse_args()
    script_dir = Path(__file__).resolve().parent.parent
    project_dir = args.project_dir or str(script_dir.parent)
    prd_path = Path(project_dir) / args.prd

    if not prd_path.exists():
        console.print(f"[red]Error:[/red] PRD not found: {prd_path}")
        sys.exit(1)

    output_path = args.output or str(Path(project_dir) / "docs" / "tajiri-zima-prd.json")

    try:
        prd = load_tajiri_prd(
            prd_path=str(prd_path),
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
