"""Flask web application entrypoint.

Uses the application-factory pattern so the app can be imported and tested
without binding to a network socket. Exposes a health endpoint for
Kubernetes liveness/readiness probes.
"""
import os

from flask import Flask, jsonify, render_template


def create_app() -> Flask:
    """Build and configure the Flask application instance."""
    app = Flask(__name__)

    @app.route("/")
    def index():
        return render_template(
            "index.html",
            app_name=os.getenv("APP_NAME", "Flask CI/CD GitOps Platform"),
            environment=os.getenv("APP_ENV", "local"),
        )

    @app.route("/health")
    def health():
        """Lightweight endpoint used by container/orchestrator probes."""
        return jsonify(status="healthy"), 200

    return app


# WSGI servers (gunicorn) import this module-level object: `app:app`
app = create_app()


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)
