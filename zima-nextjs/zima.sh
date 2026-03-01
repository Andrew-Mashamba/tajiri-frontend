#!/bin/bash
# Zima Looper - Main CLI Entry Point
# Autonomous project builder powered by Claude CLI

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PYTHONPATH="$SCRIPT_DIR:$PYTHONPATH"

# Banner
show_banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║               ⚡ ZIMA LOOPER v1.0.0 ⚡                       ║"
    echo "║                                                              ║"
    echo "║        Autonomous Next.js Project Builder                   ║"
    echo "║        Powered by Cursor CLI                                 ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Help
show_help() {
    show_banner
    echo -e "${GREEN}Usage:${NC}"
    echo "  ./zima.sh <command> [options]"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo "  ${YELLOW}generate-prd${NC}   Generate PRD from README"
    echo "  ${YELLOW}generate-stories-from-pages${NC}   Load scaffold pages from PAGES-TO-IMPLEMENT.md"
    echo "  ${YELLOW}load-tajiri-prd${NC} Load TAJIRI stories from docs/prd.json (Flutter)"
    echo "  ${YELLOW}execute${NC}        Execute project from PRD"
    echo "  ${YELLOW}status${NC}         Show project status"
    echo "  ${YELLOW}add-workers${NC}    Add more workers without stopping"
    echo "  ${YELLOW}pause${NC}          Pause execution"
    echo "  ${YELLOW}resume${NC}         Resume execution"
    echo "  ${YELLOW}report${NC}         Generate project report"
    echo "  ${YELLOW}dashboard${NC}      Start web dashboard"
    echo "  ${YELLOW}init${NC}           Initialize Zima database"
    echo "  ${YELLOW}sync-status${NC}    Mark stories completed from execution history (avoid redoing work)"
    echo "  ${YELLOW}version${NC}        Show version"
    echo "  ${YELLOW}help${NC}           Show this help"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo "  # Generate PRD from README"
    echo "  ${CYAN}./zima.sh generate-prd --readme contract-analyzer/README.md${NC}"
    echo ""
    echo "  # Load stories from PAGES-TO-IMPLEMENT.md (Next.js)"
    echo "  ${CYAN}./zima.sh generate-stories-from-pages --pages docs/PAGES-TO-IMPLEMENT.md --project-dir ../${NC}"
    echo ""
    echo "  # Load TAJIRI PRD (Flutter)"
    echo "  ${CYAN}./zima.sh load-tajiri-prd --prd docs/prd.json --project-dir ..${NC}"
    echo ""
    echo "  # Execute project with 4 workers"
    echo "  ${CYAN}./zima.sh execute --project contract-analyzer --workers 4${NC}"
    echo ""
    echo "  # Check status"
    echo "  ${CYAN}./zima.sh status --project contract-analyzer${NC}"
    echo ""
    echo "  # Start web dashboard"
    echo "  ${CYAN}./zima.sh dashboard${NC}"
    echo ""
}

# Check Python dependencies
check_dependencies() {
    if ! command -v python3 &> /dev/null; then
        echo -e "${RED}Error: Python 3 is not installed${NC}"
        echo "Please install Python 3.10 or higher"
        exit 1
    fi

    # Check if requirements are installed (skip for Phase 1 - core functionality only)
    # if ! python3 -c "import flask" 2>/dev/null; then
    #     echo -e "${YELLOW}Installing Python dependencies...${NC}"
    #     pip3 install --break-system-packages -r "$SCRIPT_DIR/requirements.txt" || {
    #         echo -e "${RED}Error: Failed to install dependencies${NC}"
    #         echo "Try manually: pip3 install --break-system-packages -r $SCRIPT_DIR/requirements.txt"
    #         exit 1
    #     }
    # fi
}

# Check Cursor CLI (agent)
check_claude() {
    if ! command -v agent &> /dev/null; then
        echo -e "${RED}Error: Cursor CLI (agent) is not installed.${NC}"
        echo ""
        echo "Install Cursor CLI:"
        echo "  curl https://cursor.com/install -fsSL | bash"
        echo ""
        exit 1
    fi
}

# Initialize database
init_db() {
    echo -e "${GREEN}Initializing Zima database...${NC}"
    python3 -c "
from core.database import Database
db = Database('$SCRIPT_DIR/zima.db')
print('✅ Database initialized at $SCRIPT_DIR/zima.db')
"
    echo -e "${GREEN}✅ Zima ready!${NC}"
}

# Generate PRD
generate_prd() {
    local readme_path=""
    local output_path=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --readme)
                readme_path="$2"
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    if [ -z "$readme_path" ]; then
        echo -e "${RED}Error: --readme parameter is required${NC}"
        exit 1
    fi

    if [ ! -f "$readme_path" ]; then
        echo -e "${RED}Error: README file not found: $readme_path${NC}"
        exit 1
    fi

    echo -e "${GREEN}Generating PRD from README...${NC}"
    echo -e "  📄 README: ${CYAN}$readme_path${NC}"

    python3 "$SCRIPT_DIR/prd/generator.py" --readme "$readme_path" --output "$output_path"
}

# Load stories from PAGES-TO-IMPLEMENT.md (Next.js)
generate_stories_from_pages() {
    local pages_path="docs/PAGES-TO-IMPLEMENT.md"
    local project_dir=""
    local output_path=""
    local project_name="ENTERPRISESACCOS"
    local no_db=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --pages)
                pages_path="$2"
                shift 2
                ;;
            --project-dir)
                project_dir="$2"
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            --project-name)
                project_name="$2"
                shift 2
                ;;
            --no-db)
                no_db=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    # Default project_dir: parent of zima-nextjs (ENTERPRISESACCOS root)
    if [ -z "$project_dir" ]; then
        project_dir="$(cd "$SCRIPT_DIR/.." && pwd)"
    fi

    local full_pages="$project_dir/$pages_path"
    if [ ! -f "$full_pages" ]; then
        echo -e "${RED}Error: PAGES-TO-IMPLEMENT.md not found: $full_pages${NC}"
        exit 1
    fi

    echo -e "${GREEN}Loading scaffold pages from PAGES-TO-IMPLEMENT.md...${NC}"
    echo -e "  📄 Pages: ${CYAN}$full_pages${NC}"
    echo -e "  📦 Project: ${CYAN}$project_name${NC}"
    echo ""

    local args=("$SCRIPT_DIR/prd/pages_loader.py" --pages "$pages_path" --project-dir "$project_dir" --project-name "$project_name")
    [ -n "$output_path" ] && args+=(--output "$output_path")
    [ "$no_db" = true ] && args+=(--no-db)

    python3 "${args[@]}"
}

# Load TAJIRI PRD (Flutter)
load_tajiri_prd() {
    local prd_path="docs/prd.json"
    local project_dir=""
    local output_path=""
    local project_name="TAJIRI"
    local no_db=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --prd)
                prd_path="$2"
                shift 2
                ;;
            --project-dir)
                project_dir="$2"
                shift 2
                ;;
            --output)
                output_path="$2"
                shift 2
                ;;
            --project-name)
                project_name="$2"
                shift 2
                ;;
            --no-db)
                no_db=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    if [ -z "$project_dir" ]; then
        project_dir="$(cd "$SCRIPT_DIR/.." && pwd)"
    fi

    local full_prd="$project_dir/$prd_path"
    if [ ! -f "$full_prd" ]; then
        echo -e "${RED}Error: prd.json not found: $full_prd${NC}"
        exit 1
    fi

    echo -e "${GREEN}Loading TAJIRI PRD...${NC}"
    echo -e "  📄 PRD: ${CYAN}$full_prd${NC}"
    echo -e "  📦 Project: ${CYAN}$project_name${NC}"
    echo ""

    local args=("$SCRIPT_DIR/prd/tajiri_prd_loader.py" --prd "$prd_path" --project-dir "$project_dir" --project-name "$project_name")
    [ -n "$output_path" ] && args+=(--output "$output_path")
    [ "$no_db" = true ] && args+=(--no-db)

    python3 "${args[@]}"
}

# Execute project
execute_project() {
    local project_name=""
    local workers=4
    local with_dashboard=false
    local story=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                project_name="$2"
                shift 2
                ;;
            --workers)
                workers="$2"
                shift 2
                ;;
            --story)
                story="$2"
                shift 2
                ;;
            --dashboard)
                with_dashboard=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    if [ -z "$project_name" ]; then
        echo -e "${RED}Error: --project parameter is required${NC}"
        exit 1
    fi

    show_banner
    echo -e "${GREEN}Starting Zima Looper...${NC}"
    echo -e "  📦 Project: ${CYAN}$project_name${NC}"
    echo -e "  ⚙️  Workers: ${CYAN}$workers${NC}"
    [ -n "$story" ] && echo -e "  📌 Story: ${CYAN}$story${NC}"
    echo -e "  📊 Dashboard: ${CYAN}$with_dashboard${NC}"
    echo ""

    [ -n "$story" ] && export ZIMA_STORY_FILTER="$story"

    # Start dashboard in background if requested
    if [ "$with_dashboard" = true ]; then
        echo -e "${YELLOW}Starting web dashboard on http://localhost:5000...${NC}"
        python3 "$SCRIPT_DIR/monitoring/dashboard.py" &
        DASHBOARD_PID=$!
        sleep 2
        echo -e "${GREEN}✅ Dashboard started (PID: $DASHBOARD_PID)${NC}"
        echo ""
    fi

    # Run main orchestrator (unbuffered so worker spawn messages appear immediately)
    if [ -n "$story" ]; then
        PYTHONUNBUFFERED=1 python3 "$SCRIPT_DIR/core/main.py" --project "$project_name" --workers "$workers" --story "$story"
    else
        PYTHONUNBUFFERED=1 python3 "$SCRIPT_DIR/core/main.py" --project "$project_name" --workers "$workers"
    fi
}

# Show status
show_status() {
    local project_name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                project_name="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    if [ -z "$project_name" ]; then
        echo -e "${RED}Error: --project parameter is required${NC}"
        exit 1
    fi

    python3 -c "
from core.database import get_db
from rich import print
from rich.table import Table

db = get_db('$SCRIPT_DIR/zima.db')
project = db.get_project_by_name('$project_name')

if not project:
    print('[red]Project not found: $project_name[/red]')
    exit(1)

summary = db.get_project_summary(project['id'])

print(f\"\\n[cyan]Project:[/cyan] {project['name']}\")
print(f\"[cyan]Status:[/cyan] {project['status']}\")
print(f\"[cyan]Stories:[/cyan] {project['completed_stories']}/{project['total_stories']} completed\")
print(f\"[cyan]Failed:[/cyan] {project['failed_stories']}\")
print(f\"\\n[cyan]Active Workers:[/cyan] {', '.join(map(str, summary['active_workers'])) if summary['active_workers'] else 'None'}\")
"
}

# Add workers dynamically
add_workers() {
    local project_name=""
    local count=2

    while [[ $# -gt 0 ]]; do
        case $1 in
            --project)
                project_name="$2"
                shift 2
                ;;
            --count)
                count="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                exit 1
                ;;
        esac
    done

    if [ -z "$project_name" ]; then
        echo -e "${RED}Error: --project parameter is required${NC}"
        exit 1
    fi

    echo -e "${GREEN}Adding $count worker(s) to project $project_name...${NC}"

    python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from core.database import get_db
from execution.worker import run_worker
from multiprocessing import Process
import os

db = get_db('$SCRIPT_DIR/zima.db')
project = db.get_project_by_name('$project_name')

if not project:
    print('[red]Project not found: $project_name[/red]')
    exit(1)

project_id = project['id']
project_dir = project['directory']

# Find the highest current worker ID by checking active stories
import sqlite3
conn = sqlite3.connect('$SCRIPT_DIR/zima.db')
cursor = conn.cursor()
cursor.execute('SELECT MAX(worker_id) FROM stories WHERE project_id = ?', (project_id,))
max_id = cursor.fetchone()[0] or 0
conn.close()

# Spawn new workers
count = $count
print(f'⚡ Spawning {count} new worker(s) starting from ID {max_id + 1}')

for i in range(count):
    worker_id = max_id + i + 1
    process = Process(
        target=run_worker,
        args=(worker_id, project_id, project_dir),
        name=f'Worker-{worker_id}'
    )
    process.start()
    print(f'✓ Worker #{worker_id} started (PID: {process.pid})')

print(f'\\n✅ Added {count} workers. They will automatically pick up pending stories.')
"
}

# Show version
show_version() {
    echo -e "${CYAN}Zima Looper v1.0.0${NC}"
    echo "Built with ❤️  by Claude"
}

# Main command router
COMMAND="${1:-help}"
shift || true

case "$COMMAND" in
    generate-prd)
        check_dependencies
        check_claude
        generate_prd "$@"
        ;;
    generate-stories-from-pages)
        check_dependencies
        generate_stories_from_pages "$@"
        ;;
    load-tajiri-prd)
        check_dependencies
        load_tajiri_prd "$@"
        ;;
    execute)
        check_dependencies
        check_claude
        execute_project "$@"
        ;;
    status)
        check_dependencies
        show_status "$@"
        ;;
    add-workers)
        check_dependencies
        add_workers "$@"
        ;;
    init)
        check_dependencies
        init_db
        ;;
    sync-status)
        check_dependencies
        python3 "$SCRIPT_DIR/scripts/sync_story_status_from_executions.py" "$@"
        ;;
    dashboard)
        check_dependencies
        python3 "$SCRIPT_DIR/monitoring/dashboard.py"
        ;;
    version)
        show_version
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: $COMMAND${NC}"
        echo "Run './zima.sh help' for usage"
        exit 1
        ;;
esac
