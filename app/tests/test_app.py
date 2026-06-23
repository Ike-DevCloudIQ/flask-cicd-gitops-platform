"""Unit tests for the Flask application.

Run from the `app/` directory:  pytest
"""
import os
import sys

# Make app.py importable when pytest is invoked from the app/ directory.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from app import create_app  # noqa: E402


def _client():
    return create_app().test_client()


def test_index_returns_200():
    resp = _client().get("/")
    assert resp.status_code == 200


def test_health_returns_healthy():
    resp = _client().get("/health")
    assert resp.status_code == 200
    assert resp.get_json()["status"] == "healthy"
