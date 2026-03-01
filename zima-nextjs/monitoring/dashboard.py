"""
Zima Looper - Web Dashboard
Flask-based real-time monitoring dashboard
"""

import os
import sys
import json
import time
from datetime import datetime
from typing import Dict, List, Optional

# Add parent directory to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from flask import Flask, render_template, jsonify, Response, request
from core.database import get_db
from core.state_machine import StoryStateMachine

app = Flask(__name__)
app.config['SECRET_KEY'] = 'zima-looper-dashboard'

# Get database path
SCRIPT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB_PATH = os.path.join(SCRIPT_DIR, 'zima.db')


def get_database():
    """Get database instance"""
    return get_db(DB_PATH)


def get_all_projects() -> List[Dict]:
    """Get all projects from database with up-to-date story counts"""
    db = get_database()
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT * FROM projects
            ORDER BY created_at DESC
        ''')
        columns = [desc[0] for desc in cursor.description]
        projects = [dict(zip(columns, row)) for row in cursor.fetchall()]

    # Refresh project stats from stories table so list shows accurate counts
    for p in projects:
        db.update_project_stats(p['id'])

    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT * FROM projects
            ORDER BY created_at DESC
        ''')
        columns = [desc[0] for desc in cursor.description]
        projects = [dict(zip(columns, row)) for row in cursor.fetchall()]

    for p in projects:
        p['display_name'] = db.get_project_display_name(p)
    return projects


def get_project_details(project_id: int) -> Optional[Dict]:
    """Get detailed project information"""
    db = get_database()
    project = db.get_project(project_id)

    if not project:
        return None

    project['display_name'] = db.get_project_display_name(project)

    # Get stories
    stories = db.get_project_stories(project_id)

    # Get state machine for progress
    state_machine = StoryStateMachine(db)
    progress = state_machine.get_project_progress(project_id)

    # Get project summary
    summary = db.get_project_summary(project_id)

    # Calculate additional metrics
    total_stories = len(stories)
    completed_stories = sum(1 for s in stories if s['status'] == 'completed')
    failed_stories = sum(1 for s in stories if s['status'] == 'failed')
    in_progress_stories = sum(1 for s in stories if s['status'] in ['in_progress', 'planning', 'implementing', 'testing'])
    pending_stories = sum(1 for s in stories if s['status'] == 'pending')
    skipped_stories = sum(1 for s in stories if s['status'] == 'skipped')

    # If status is "executing" but no workers and nothing in progress, treat as paused
    if project.get('status') == 'executing' and in_progress_stories == 0 and len(summary['active_workers']) == 0:
        db.update_project_status(project_id, 'paused')
        project = db.get_project(project_id)

    # Calculate time estimates
    started_at = project.get('started_at')
    elapsed_time = None
    estimated_remaining = None

    if started_at and in_progress_stories > 0:
        start_time = datetime.fromisoformat(started_at)
        elapsed = (datetime.now() - start_time).total_seconds() / 60  # minutes
        elapsed_time = f"{int(elapsed // 60)}h {int(elapsed % 60)}m"

        # Rough estimate: avg time per story * remaining stories
        if completed_stories > 0:
            avg_time_per_story = elapsed / completed_stories
            remaining_stories = pending_stories + in_progress_stories
            est_minutes = avg_time_per_story * remaining_stories
            estimated_remaining = f"{int(est_minutes // 60)}h {int(est_minutes % 60)}m"

    # Get recent activity (last 50 executions so more data is visible)
    recent_activity = []
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT e.*, s.story_number, s.title
            FROM executions e
            JOIN stories s ON e.story_id = s.id
            WHERE s.project_id = ?
            ORDER BY e.created_at DESC
            LIMIT 50
        ''', (project_id,))

        columns = [desc[0] for desc in cursor.description]
        for row in cursor.fetchall():
            recent_activity.append(dict(zip(columns, row)))

    return {
        'project': project,
        'stories': stories,
        'progress': progress,
        'summary': summary,
        'metrics': {
            'total_stories': total_stories,
            'completed_stories': completed_stories,
            'failed_stories': failed_stories,
            'in_progress_stories': in_progress_stories,
            'pending_stories': pending_stories,
            'skipped_stories': skipped_stories,
            'active_workers': len(summary['active_workers']),
            'elapsed_time': elapsed_time,
            'estimated_remaining': estimated_remaining,
            'success_rate': progress['success_rate'],
            'completion_percentage': progress['completion_percentage']
        },
        'recent_activity': recent_activity
    }


# Routes

@app.route('/')
def index():
    """Dashboard home page"""
    projects = get_all_projects()
    return render_template('dashboard.html', projects=projects)


@app.route('/project/<int:project_id>')
def project_detail(project_id: int):
    """Project detail page"""
    details = get_project_details(project_id)

    if not details:
        return jsonify({'error': 'Project not found'}), 404

    return render_template('project.html', **details)


@app.route('/api/projects')
def api_projects():
    """API: Get all projects"""
    projects = get_all_projects()
    return jsonify(projects)


@app.route('/api/project/<int:project_id>')
def api_project(project_id: int):
    """API: Get project details"""
    details = get_project_details(project_id)

    if not details:
        return jsonify({'error': 'Project not found'}), 404

    return jsonify(details)


@app.route('/api/project/<int:project_id>/stories')
def api_stories(project_id: int):
    """API: Get project stories"""
    db = get_database()
    stories = db.get_project_stories(project_id)
    return jsonify(stories)


@app.route('/api/project/<int:project_id>/metrics')
def api_metrics(project_id: int):
    """API: Get project metrics"""
    db = get_database()

    with db.get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute('''
            SELECT * FROM metrics
            WHERE project_id = ?
            ORDER BY timestamp DESC
            LIMIT 100
        ''', (project_id,))

        columns = [desc[0] for desc in cursor.description]
        metrics = []

        for row in cursor.fetchall():
            metrics.append(dict(zip(columns, row)))

        return jsonify(metrics)


@app.route('/api/project/<int:project_id>/stream')
def api_stream(project_id: int):
    """API: Server-Sent Events stream for real-time updates"""

    def generate():
        """Generate SSE events"""
        last_check = time.time()

        while True:
            # Check for updates every 2 seconds
            time.sleep(2)

            # Get current project state
            details = get_project_details(project_id)

            if not details:
                yield f"data: {json.dumps({'error': 'Project not found'})}\n\n"
                break

            # Send update
            data = {
                'timestamp': datetime.now().isoformat(),
                'metrics': details['metrics'],
                'progress': details['progress'],
                'active_workers': details['summary']['active_workers']
            }

            yield f"data: {json.dumps(data)}\n\n"

            # Check if project is complete
            if details['project']['status'] == 'completed':
                yield f"data: {json.dumps({'status': 'complete'})}\n\n"
                break

    return Response(generate(), mimetype='text/event-stream')


@app.route('/api/health')
def api_health():
    """API: Health check"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })


@app.route('/api/project/add', methods=['POST'])
def api_add_project():
    """API: Add new project by generating PRD from README"""
    import subprocess

    data = request.get_json()
    readme_path = data.get('readme_path')

    if not readme_path:
        return jsonify({'error': 'readme_path is required'}), 400

    if not os.path.exists(readme_path):
        return jsonify({'error': f'README not found: {readme_path}'}), 404

    try:
        # Run PRD generation
        result = subprocess.run(
            ['./zima.sh', 'generate-prd', '--readme', readme_path],
            cwd=SCRIPT_DIR,
            capture_output=True,
            text=True,
            timeout=300
        )

        if result.returncode == 0:
            return jsonify({
                'success': True,
                'message': 'Project PRD generated successfully',
                'output': result.stdout
            })
        else:
            return jsonify({
                'error': 'PRD generation failed',
                'output': result.stderr
            }), 500

    except subprocess.TimeoutExpired:
        return jsonify({'error': 'PRD generation timeout'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/project/<int:project_id>/start', methods=['POST'])
def api_start_project(project_id: int):
    """API: Start project execution"""
    import subprocess

    db = get_database()
    project = db.get_project(project_id)

    if not project:
        return jsonify({'error': 'Project not found'}), 404

    data = request.get_json() or {}
    workers = data.get('workers', 4)

    try:
        # Start project execution in background
        process = subprocess.Popen(
            ['./zima.sh', 'execute', '--project', project['name'], '--workers', str(workers)],
            cwd=SCRIPT_DIR,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )

        return jsonify({
            'success': True,
            'message': f'Project execution started',
            'pid': process.pid,
            'project': project['name'],
            'workers': workers
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


def main():
    """Run dashboard server"""
    port = int(os.environ.get('DASHBOARD_PORT', 0)) or 5001
    try:
        from core.config import get_config
        port = port or get_config().dashboard_port
    except Exception:
        pass

    print("\n" + "="*60)
    print("⚡ ZIMA LOOPER DASHBOARD")
    print("="*60)
    print(f"\n🌐 Dashboard URL: http://localhost:{port}")
    print("📊 Real-time monitoring enabled")
    print("\nPress Ctrl+C to stop\n")

    app.run(
        host='0.0.0.0',
        port=port,
        debug=False,
        threaded=True
    )


if __name__ == '__main__':
    main()
