"""
Zima Looper - README Parser
Extracts structured information from README files
"""

import re
from typing import Dict, List, Optional
from pathlib import Path


class ReadmeParser:
    """Parse README.md files and extract project information"""

    def __init__(self, readme_path: str):
        """
        Initialize parser

        Args:
            readme_path: Path to README.md file
        """
        self.readme_path = Path(readme_path)
        if not self.readme_path.exists():
            raise FileNotFoundError(f"README not found: {readme_path}")

        with open(self.readme_path, 'r', encoding='utf-8') as f:
            self.content = f.read()

    def parse(self) -> Dict:
        """
        Parse README and extract structured information

        Returns:
            Dictionary with parsed data
        """
        return {
            'project_name': self._extract_project_name(),
            'description': self._extract_description(),
            'features': self._extract_features(),
            'tech_stack': self._extract_tech_stack(),
            'installation': self._extract_installation(),
            'usage': self._extract_usage(),
            'routes': self._extract_routes(),
            'database': self._extract_database_info(),
            'testing': self._extract_testing_info(),
            'deployment': self._extract_deployment_info(),
            'full_content': self.content,
            'file_path': str(self.readme_path)
        }

    def _extract_project_name(self) -> str:
        """Extract project name from title"""
        # Look for first H1 heading
        match = re.search(r'^#\s+(.+?)(?:\n|$)', self.content, re.MULTILINE)
        if match:
            return match.group(1).strip()

        # Fallback to directory name
        return self.readme_path.parent.name

    def _extract_description(self) -> str:
        """Extract project description"""
        # Look for content after H1 but before next heading
        match = re.search(r'^#\s+.+?\n+(.+?)(?=\n#{1,2}\s|\Z)', self.content, re.MULTILINE | re.DOTALL)
        if match:
            desc = match.group(1).strip()
            # Take first paragraph only
            first_para = desc.split('\n\n')[0]
            return first_para.strip()

        return ""

    def _extract_features(self) -> List[str]:
        """Extract feature list"""
        features = []

        # Look for Features section
        features_section = self._extract_section('Features')
        if features_section:
            # Extract bullet points
            features = self._extract_bullet_points(features_section)

        # Also look for What's Included, Capabilities, etc.
        if not features:
            for alt_heading in ['What\'s Included', 'Capabilities', 'What It Does', 'Functionality']:
                section = self._extract_section(alt_heading)
                if section:
                    features = self._extract_bullet_points(section)
                    break

        return features

    def _extract_tech_stack(self) -> Dict:
        """Extract technology stack information"""
        tech_stack = {
            'framework': None,
            'frontend': None,
            'database': None,
            'auth': None,
            'payments': None,
            'testing': None
        }

        # Look for Tech Stack section
        tech_section = self._extract_section('Tech Stack', include_subsections=False)
        if tech_section:
            # Parse technology mentions
            if 'laravel' in tech_section.lower():
                version_match = re.search(r'laravel\s+(\d+(?:\.\d+)?)', tech_section, re.IGNORECASE)
                tech_stack['framework'] = f"Laravel {version_match.group(1)}" if version_match else "Laravel"

            if 'breeze' in tech_section.lower():
                tech_stack['auth'] = 'Laravel Breeze'

            if 'cashier' in tech_section.lower() or 'stripe' in tech_section.lower():
                tech_stack['payments'] = 'Laravel Cashier (Stripe)'

            if 'sqlite' in tech_section.lower():
                tech_stack['database'] = 'SQLite'
            elif 'mysql' in tech_section.lower():
                tech_stack['database'] = 'MySQL'
            elif 'postgres' in tech_section.lower():
                tech_stack['database'] = 'PostgreSQL'

            if 'tailwind' in tech_section.lower():
                tech_stack['frontend'] = 'Tailwind CSS'
            if 'alpine' in tech_section.lower():
                tech_stack['frontend'] = (tech_stack['frontend'] or '') + ' + Alpine.js'

        return tech_stack

    def _extract_installation(self) -> List[str]:
        """Extract installation steps"""
        installation = []

        install_section = self._extract_section('Installation')
        if install_section:
            # Look for code blocks
            code_blocks = re.findall(r'```(?:bash|sh)?\n(.+?)```', install_section, re.DOTALL)
            for block in code_blocks:
                commands = [cmd.strip() for cmd in block.strip().split('\n') if cmd.strip() and not cmd.strip().startswith('#')]
                installation.extend(commands)

        return installation

    def _extract_usage(self) -> List[str]:
        """Extract usage examples"""
        usage = []

        usage_section = self._extract_section('Usage')
        if usage_section:
            code_blocks = re.findall(r'```(?:bash|php)?\n(.+?)```', usage_section, re.DOTALL)
            for block in code_blocks:
                usage.append(block.strip())

        return usage

    def _extract_routes(self) -> List[Dict]:
        """Extract route information"""
        routes = []

        routes_section = self._extract_section('Routes')
        if routes_section:
            # Look for route patterns like "GET /path - Description"
            route_pattern = r'(?:GET|POST|PUT|PATCH|DELETE)\s+(/[^\s]+)\s*[-–]\s*(.+?)(?:\n|$)'
            matches = re.findall(route_pattern, routes_section, re.MULTILINE)

            for path, description in matches:
                routes.append({
                    'path': path.strip(),
                    'description': description.strip()
                })

        return routes

    def _extract_database_info(self) -> Dict:
        """Extract database schema information"""
        database_info = {
            'tables': []
        }

        db_section = self._extract_section('Database')
        if db_section:
            # Look for table mentions
            table_pattern = r'(?:table|migration):\s*`?(\w+)`?'
            tables = re.findall(table_pattern, db_section, re.IGNORECASE)
            database_info['tables'] = list(set(tables))

        return database_info

    def _extract_testing_info(self) -> Dict:
        """Extract testing information"""
        testing_info = {
            'framework': None,
            'commands': []
        }

        test_section = self._extract_section('Testing')
        if test_section:
            if 'phpunit' in test_section.lower() or 'pest' in test_section.lower():
                testing_info['framework'] = 'PHPUnit' if 'phpunit' in test_section.lower() else 'Pest'

            # Extract test commands
            code_blocks = re.findall(r'```(?:bash)?\n(.+?)```', test_section, re.DOTALL)
            for block in code_blocks:
                commands = [cmd.strip() for cmd in block.strip().split('\n') if 'test' in cmd.lower()]
                testing_info['commands'].extend(commands)

        return testing_info

    def _extract_deployment_info(self) -> Dict:
        """Extract deployment information"""
        deployment_info = {
            'platforms': [],
            'steps': []
        }

        deploy_section = self._extract_section('Deployment')
        if deploy_section:
            # Check for platform mentions
            if 'forge' in deploy_section.lower():
                deployment_info['platforms'].append('Laravel Forge')
            if 'vapor' in deploy_section.lower():
                deployment_info['platforms'].append('Laravel Vapor')
            if 'heroku' in deploy_section.lower():
                deployment_info['platforms'].append('Heroku')

        return deployment_info

    def _extract_section(self, heading: str, include_subsections: bool = True) -> Optional[str]:
        """
        Extract content of a section by heading

        Args:
            heading: Section heading to find
            include_subsections: Include content until next same-level heading

        Returns:
            Section content or None
        """
        # Try different heading levels
        for level in range(1, 4):
            pattern = rf'^#{{{level}}}\s+{re.escape(heading)}.*?\n+(.*?)(?=\n#{{{level if include_subsections else level}}}\s|\Z)'
            match = re.search(pattern, self.content, re.MULTILINE | re.DOTALL | re.IGNORECASE)
            if match:
                return match.group(1).strip()

        return None

    def _extract_bullet_points(self, text: str) -> List[str]:
        """Extract bullet points from text"""
        # Match lines starting with -, *, or numbered lists
        pattern = r'^[\s]*(?:[-*]|\d+\.)\s+(.+?)$'
        matches = re.findall(pattern, text, re.MULTILINE)

        # Clean up bullet points
        bullets = []
        for match in matches:
            # Remove markdown formatting
            cleaned = re.sub(r'\*\*(.+?)\*\*', r'\1', match)  # Bold
            cleaned = re.sub(r'`(.+?)`', r'\1', cleaned)  # Code
            cleaned = cleaned.strip()
            if cleaned:
                bullets.append(cleaned)

        return bullets

    def get_summary(self) -> str:
        """Get a human-readable summary of parsed data"""
        data = self.parse()

        summary = []
        summary.append(f"Project: {data['project_name']}")
        summary.append(f"Description: {data['description'][:100]}...")
        summary.append(f"Features: {len(data['features'])} found")
        summary.append(f"Routes: {len(data['routes'])} found")
        summary.append(f"Database Tables: {len(data['database']['tables'])} found")

        return '\n'.join(summary)


def parse_readme(readme_path: str) -> Dict:
    """
    Convenience function to parse a README file

    Args:
        readme_path: Path to README.md

    Returns:
        Parsed data dictionary
    """
    parser = ReadmeParser(readme_path)
    return parser.parse()
