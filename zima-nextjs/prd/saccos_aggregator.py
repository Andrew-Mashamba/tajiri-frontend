"""
SACCOS Story Aggregator
Parses EPIC markdown files and generates prd.json for Zima Looper
"""

import os
import re
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict


@dataclass
class Story:
    id: int
    story_id: str
    title: str
    description: str
    acceptance: List[str]
    priority: int
    estimate_hours: float
    module: str
    epic_id: str


def parse_story_points_to_hours(points: int) -> float:
    """Convert story points to estimated hours"""
    mapping = {
        1: 0.5,
        2: 1.0,
        3: 2.0,
        5: 4.0,
        8: 6.0,
        13: 10.0,
    }
    return mapping.get(points, points * 0.75)


def priority_to_int(priority_str: str) -> int:
    """Convert priority string to integer (1=highest)"""
    mapping = {
        'critical': 1,
        'high': 2,
        'medium': 3,
        'low': 4,
    }
    return mapping.get(priority_str.lower(), 3)


def parse_epic_file(file_path: Path) -> List[Story]:
    """Parse an EPIC markdown file and extract stories"""
    stories = []

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract module info from header
    module_match = re.search(r'\*\*Module\*\*:\s*(.+)', content)
    module_name = module_match.group(1).strip() if module_match else file_path.parent.name

    epic_match = re.search(r'\*\*Epic ID\*\*:\s*(EPIC-\d+)', content)
    epic_id = epic_match.group(1) if epic_match else "EPIC-000"

    # Split into story sections
    story_pattern = r'###\s+STORY-(\d+):\s*(.+?)(?=###\s+STORY-|\Z|---\s*\n##)'
    story_matches = re.finditer(story_pattern, content, re.DOTALL)

    for match in story_matches:
        story_num = match.group(1)
        story_section = match.group(0)

        # Extract title
        title_match = re.search(r'###\s+STORY-\d+:\s*(.+)', story_section)
        title = title_match.group(1).strip() if title_match else f"Story {story_num}"

        # Extract story ID
        story_id = f"STORY-{story_num.zfill(3)}"

        # Extract priority
        priority_match = re.search(r'\*\*Priority\*\*:\s*(\w+)', story_section)
        priority_str = priority_match.group(1) if priority_match else "Medium"
        priority = priority_to_int(priority_str)

        # Extract story points
        points_match = re.search(r'\*\*Story Points\*\*:\s*(\d+)', story_section)
        points = int(points_match.group(1)) if points_match else 3
        estimate_hours = parse_story_points_to_hours(points)

        # Extract "As a / I want / So that"
        as_a_match = re.search(r'\*\*As a\*\*\s+(.+)', story_section)
        i_want_match = re.search(r'\*\*I want\*\*\s+(.+)', story_section)
        so_that_match = re.search(r'\*\*So that\*\*\s+(.+)', story_section)

        as_a = as_a_match.group(1).strip() if as_a_match else ""
        i_want = i_want_match.group(1).strip() if i_want_match else ""
        so_that = so_that_match.group(1).strip() if so_that_match else ""

        description = f"As a {as_a}, I want {i_want} so that {so_that}".strip()
        if not description or description == "As a , I want  so that ":
            description = title

        # Extract acceptance criteria
        acceptance = []
        criteria_section = re.search(
            r'####\s+Acceptance Criteria\s*\n((?:[-*]\s*\[.\].+\n?)+)',
            story_section,
            re.MULTILINE
        )
        if criteria_section:
            criteria_text = criteria_section.group(1)
            criteria_lines = re.findall(r'[-*]\s*\[.\]\s*(.+)', criteria_text)
            acceptance = [line.strip() for line in criteria_lines if line.strip()]

        # Extract tasks as additional acceptance criteria
        tasks_section = re.search(
            r'####\s+Tasks\s*\n((?:\d+\.\s*\[.\].+\n?)+)',
            story_section,
            re.MULTILINE
        )
        if tasks_section:
            tasks_text = tasks_section.group(1)
            task_lines = re.findall(r'\d+\.\s*\[.\]\s*(.+)', tasks_text)
            for task in task_lines:
                if task.strip():
                    acceptance.append(f"Task: {task.strip()}")

        if not acceptance:
            acceptance = [f"Implement {title}"]

        story = Story(
            id=int(story_num),
            story_id=story_id,
            title=title,
            description=description,
            acceptance=acceptance,
            priority=priority,
            estimate_hours=estimate_hours,
            module=module_name,
            epic_id=epic_id
        )
        stories.append(story)

    return stories


def aggregate_stories(stories_dir: Path, modules_filter: List[str] = None) -> List[Story]:
    """Aggregate stories from all EPIC files"""
    all_stories = []

    # Find all EPIC files
    epic_files = list(stories_dir.glob("*/EPIC-*.md"))
    epic_files.sort(key=lambda p: p.parent.name)

    for epic_file in epic_files:
        module_dir = epic_file.parent.name

        # Filter by module if specified
        if modules_filter:
            if not any(m in module_dir for m in modules_filter):
                continue

        print(f"Parsing: {epic_file.name} ({module_dir})")
        stories = parse_epic_file(epic_file)
        all_stories.extend(stories)
        print(f"  Found {len(stories)} stories")

    return all_stories


def generate_prd(stories: List[Story], output_path: Path, project_info: Dict = None):
    """Generate prd.json file"""

    # Sort stories by module priority, then by story ID
    # Foundation modules first (ui-shell, members, users), then rest in dependency order
    module_order = [
        '00-ui-shell',      # 1. Foundation - Auth, Nav, Layout
        '02-members',       # 2. Core - Member management
        '22-users',         # 3. Core - User/Role management
        '01-branches',      # 4. Core - Branch setup
        '07-products-management',  # 5. Setup - Financial products
        '00-dashboard',     # 6. UI - Dashboard widgets
        '03-shares',        # 7. Financial - Share accounts
        '04-savings',       # 8. Financial - Savings accounts
        '05-deposits',      # 9. Financial - Fixed deposits
        '06-loans',         # 10. Financial - Loan products
        '23-active-loans',  # 11. Financial - Loan monitoring
        '08-accounting',    # 12. Accounting - GL & statements
        '28-transactions',  # 13. Operations - Transactions
        '15-teller-management',  # 14. Operations - Teller ops
        '26-cash-management',    # 15. Operations - Cash/vault
        '16-reconciliation',     # 16. Accounting - Reconciliation
        '09-expenses',      # 17. Finance - Expenses
        '13-budget-management',  # 18. Finance - Budgets
        '12-procurement',   # 19. Finance - Procurement
        '17-hr',            # 20. Admin - HR
        '19-approvals',     # 21. Workflow - Approvals
        '18-self-services', # 22. Portal - Self service
        '29-members-portal',# 23. Portal - Member portal
        '27-billing',       # 24. Integration - Billing
        '31-subscriptions', # 25. Integration - Subscriptions
        '20-reports',       # 26. Reports - All reports
        '21-profile-settings',  # 27. Settings - User profile
    ]

    def get_module_order(story):
        module = story.module.lower().replace(' ', '-').replace('(', '').replace(')', '')
        # Direct mapping for known modules - order matters! Check specific patterns first
        module_patterns = [
            ('ui-shell', 0), ('ui shell', 0), ('authentication,-navigation,-layout', 0),
            ('members-portal', 22), ('members portal', 22), ('member-portal', 22),  # Before 'members'!
            ('members', 1), ('member', 1),
            ('users', 2), ('user', 2),
            ('branches', 3), ('branch', 3),
            ('products-management', 4), ('products management', 4), ('products', 4),
            ('dashboard', 5),
            ('shares', 6), ('share', 6),
            ('savings', 7), ('saving', 7),
            ('deposits', 8), ('deposit', 8),
            ('active-loans', 10), ('active loans', 10), ('active-loan', 10),
            ('loans', 9), ('loan', 9),  # After active-loans
            ('accounting', 11),
            ('transactions', 12), ('transaction', 12),
            ('teller-management', 13), ('teller management', 13), ('teller', 13),
            ('cash-management', 14), ('cash management', 14), ('cash', 14),
            ('reconciliation', 15),
            ('expenses', 16), ('expense', 16),
            ('budget-management', 17), ('budget management', 17), ('budget', 17),
            ('procurement', 18),
            ('human-resources', 19), ('human resources', 19), ('hr', 19),
            ('approvals', 20), ('approval', 20),
            ('self-services', 21), ('self services', 21), ('self-service', 21),
            ('billing', 23),
            ('subscriptions', 24), ('subscription', 24),
            ('reports', 25), ('report', 25),
            ('profile-settings', 26), ('profile settings', 26), ('profile', 26),
        ]

        # Check patterns in order (specific patterns checked first)
        for pattern, order in module_patterns:
            if pattern in module:
                return order

        return 99  # Unknown modules go to end

    sorted_stories = sorted(stories, key=lambda s: (get_module_order(s), s.id))

    # Renumber stories sequentially
    prd_stories = []
    for idx, story in enumerate(sorted_stories, 1):
        prd_story = {
            "id": idx,
            "original_id": story.story_id,
            "title": story.title,
            "description": story.description,
            "acceptance": story.acceptance,
            "priority": idx,  # Priority matches execution order
            "estimate_hours": story.estimate_hours,
            "module": story.module,
            "epic": story.epic_id
        }
        prd_stories.append(prd_story)

    # Build PRD structure
    prd = {
        "project": project_info or {
            "name": "SACCOS CRDB",
            "description": "SACCOS Core System - Complete financial cooperative management system",
            "tech_stack": {
                "framework": "Laravel 12.x",
                "language": "PHP 8.2+",
                "frontend": "Livewire 4.x + Alpine.js + Tailwind CSS",
                "database": "MySQL 8.0 / PostgreSQL 15",
                "cache": "Redis",
                "realtime": "Laravel Reverb"
            }
        },
        "stories": prd_stories,
        "metadata": {
            "total_stories": len(prd_stories),
            "total_hours": sum(s["estimate_hours"] for s in prd_stories),
            "modules": list(set(s.module for s in stories)),
            "generated_by": "saccos_aggregator.py"
        }
    }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(prd, f, indent=2, ensure_ascii=False)

    print(f"\nPRD generated: {output_path}")
    print(f"Total stories: {len(prd_stories)}")
    print(f"Total estimated hours: {prd['metadata']['total_hours']:.1f}")

    return prd


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Aggregate SACCOS stories into PRD')
    parser.add_argument('--stories-dir', required=True, help='Path to stories directory')
    parser.add_argument('--output', required=True, help='Output prd.json path')
    parser.add_argument('--modules', nargs='*', help='Filter by module names')
    parser.add_argument('--project-name', default='SACCOS CRDB', help='Project name')

    args = parser.parse_args()

    stories_dir = Path(args.stories_dir)
    if not stories_dir.exists():
        print(f"Error: Stories directory not found: {stories_dir}")
        return 1

    stories = aggregate_stories(stories_dir, args.modules)

    if not stories:
        print("No stories found!")
        return 1

    project_info = {
        "name": args.project_name,
        "description": "SACCOS Core System - Complete financial cooperative management system",
        "tech_stack": {
            "framework": "Laravel 12.x",
            "language": "PHP 8.2+",
            "frontend": "Livewire 4.x + Alpine.js + Tailwind CSS",
            "database": "MySQL 8.0 / PostgreSQL 15",
            "cache": "Redis",
            "realtime": "Laravel Reverb"
        }
    }

    generate_prd(stories, Path(args.output), project_info)

    return 0


if __name__ == '__main__':
    exit(main())
