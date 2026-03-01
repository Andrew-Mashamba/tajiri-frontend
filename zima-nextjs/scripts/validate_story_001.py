#!/usr/bin/env python3
"""
Validate STORY-001 (User Login) acceptance criteria after a Zima run.

Checks frontend and backend for:
- Login route / login page
- Form with email/username and password fields
- Error message for invalid credentials
- Redirect to dashboard on success
- Remember device (30-day) option
- Backend auth endpoint (e.g. POST /api/auth/login)
- Optional: account lockout mention, login attempt logging

Usage:
  python scripts/validate_story_001.py
  python scripts/validate_story_001.py --project /path/to/project/root
"""

import argparse
import os
import re
import sys


def read_file(path: str) -> str:
    if not os.path.isfile(path):
        return ""
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        return f.read()


def check(
    project_root: str,
    name: str,
    ok: bool,
    detail: str = "",
) -> None:
    status = "PASS" if ok else "FAIL"
    symbol = "✓" if ok else "✗"
    print(f"  [{status}] {symbol} {name}")
    if detail and not ok:
        print(f"        {detail}")


def validate_frontend(project_root: str) -> int:
    """Validate frontend login (Next.js/React). Returns number of failures."""
    failures = 0
    frontend = os.path.join(project_root, "frontend")
    # Support Next.js app router: app/login/page.tsx or pages/login.tsx
    login_page = os.path.join(frontend, "src", "app", "login", "page.tsx")
    if not os.path.isfile(login_page):
        login_page = os.path.join(frontend, "src", "app", "login", "page.jsx")
    if not os.path.isfile(login_page):
        login_page = os.path.join(frontend, "src", "pages", "login.tsx")
    if not os.path.isfile(login_page):
        login_page = os.path.join(frontend, "src", "pages", "login.jsx")
    content = read_file(login_page)

    # Login route / page exists
    ok = bool(content)
    if not ok:
        check(project_root, "Login page exists (e.g. frontend/src/app/login/page.tsx)", False, "File not found")
        return 1
    check(project_root, "Login page exists", True)
    failures += 0 if ok else 1

    # Email/username field (identifier, email, or username)
    has_identifier = (
        "identifier" in content
        or "email" in content.lower()
        or "username" in content.lower()
        or 'name="email"' in content
        or 'name="identifier"' in content
    )
    check(project_root, "Form has email/username or identifier field", has_identifier)
    if not has_identifier:
        failures += 1

    # Password field
    has_password = "password" in content.lower() and ("type=\"password\"" in content or "type='password'" in content)
    check(project_root, "Form has password field", has_password)
    if not has_password:
        failures += 1

    # Error message for invalid credentials
    has_error = (
        "error" in content.lower()
        and ("setError" in content or "errorMessage" in content or "invalid" in content.lower())
    )
    check(project_root, "Error message for invalid credentials", has_error)
    if not has_error:
        failures += 1

    # Redirect to dashboard on success
    has_redirect = "dashboard" in content.lower() and ("push" in content or "redirect" in content or "navigate" in content)
    check(project_root, "Redirect to dashboard on success", has_redirect)
    if not has_redirect:
        failures += 1

    # Remember me / remember device (30-day)
    has_remember = (
        "remember" in content.lower()
        or "rememberMe" in content
        or "remember-me" in content
    )
    check(project_root, "Remember device / Remember me option", has_remember)
    if not has_remember:
        failures += 1

    # Responsive / mobile mention (optional)
    has_responsive = "responsive" in content.lower() or "mobile" in content.lower() or "sm:" in content or "md:" in content
    check(project_root, "Responsive/mobile consideration", has_responsive)

    return failures


def validate_backend(project_root: str) -> int:
    """Validate backend auth endpoint. Returns number of failures."""
    failures = 0
    backend = os.path.join(project_root, "backend")

    # Find AuthController or equivalent (Java Spring, or Node/Express route)
    auth_controller = os.path.join(
        backend,
        "src", "main", "java", "com", "saccos", "controller", "AuthController.java"
    )
    content = read_file(auth_controller)
    if not content:
        check(project_root, "Backend auth controller or login route exists", False, "AuthController or auth route not found")
        return 1

    check(project_root, "Backend auth controller or login route exists", True)

    # POST login endpoint (e.g. /api/auth/login or /auth/login)
    has_login_endpoint = (
        "login" in content.lower()
        and ("PostMapping" in content or "post" in content.lower() or "@post" in content.lower())
    )
    check(project_root, "POST login endpoint", has_login_endpoint)
    if not has_login_endpoint:
        failures += 1

    # Validate credentials / database (service or repository)
    has_validate = (
        "validat" in content.lower()
        or "credential" in content.lower()
        or "authenticate" in content.lower()
        or "AuthService" in content
    )
    check(project_root, "Credential validation (service/DB)", has_validate)
    if not has_validate:
        failures += 1

    # Login attempt logging (optional)
    attempt_log = read_file(os.path.join(backend, "src", "main", "java", "com", "saccos", "service", "LoginAttemptService.java"))
    has_logging = "LoginAttempt" in content or "loginAttempt" in content or (attempt_log and "log" in attempt_log.lower())
    check(project_root, "Login attempt logging (optional)", has_logging)

    # Account lockout (optional)
    has_lockout = "lock" in content.lower() or "lockout" in content.lower() or "failedAttempt" in content
    check(project_root, "Account lockout mechanism (optional)", has_lockout)

    return failures


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate STORY-001 (User Login) acceptance criteria")
    parser.add_argument(
        "--project",
        default=os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        help="Project root (default: parent of zima/)",
    )
    args = parser.parse_args()
    project_root = os.path.abspath(args.project)
    # If run from zima/scripts, project is zima's parent; if run from project root, project is cwd
    if not os.path.isdir(project_root):
        print(f"Error: Project root not found: {project_root}")
        return 1

    print("STORY-001 (User Login) validation")
    print("=" * 50)
    print(f"Project root: {project_root}\n")

    print("Frontend (login page, form, redirect, remember me)")
    print("-" * 50)
    frontend_failures = validate_frontend(project_root)

    print("\nBackend (auth endpoint, validation, logging, lockout)")
    print("-" * 50)
    backend_failures = validate_backend(project_root)

    total = frontend_failures + backend_failures
    print("\n" + "=" * 50)
    if total == 0:
        print("All required checks passed.")
        return 0
    print(f"Total failures: {total}")
    return 1


if __name__ == "__main__":
    sys.exit(main())
