#!/usr/bin/env python3
"""
Simple Flask Application - Learning Platform

A minimal Flask app to learn cloud-native concepts step by step.
Features will be added progressively through each learning phase.
"""

from flask import Flask, jsonify, request

app = Flask(__name__)

# ============================================================================
# Basic Health Check Endpoints
# ============================================================================

@app.route("/health/live", methods=["GET"])
def liveness():
    """Liveness probe - is the app running?"""
    return jsonify({"status": "alive"}), 200

@app.route("/health/ready", methods=["GET"])
def readiness():
    """Readiness probe - is the app ready to serve?"""
    return jsonify({"status": "ready"}), 200

# ============================================================================
# Core API Endpoints
# ============================================================================

@app.route("/", methods=["GET"])
def index():
    """Root endpoint"""
    return jsonify({
        "application": "flask-app",
        "message": "Cloud-Native Learning Platform"
    }), 200

@app.route("/api/v1/process", methods=["POST"])
def process_data():
    """Simple data processing endpoint"""
    try:
        if not request.is_json:
            return jsonify({"error": "Content-Type must be application/json"}), 400
        
        data = request.get_json()
        
        if "data" not in data:
            return jsonify({"error": "Missing required field: data"}), 422
        
        # Simple processing: convert to uppercase
        processed = str(data["data"]).upper()
        
        return jsonify({
            "input": data["data"],
            "output": processed,
            "status": "success"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/v1/status", methods=["GET"])
def status():
    """Application status"""
    return jsonify({
        "status": "operational",
        "message": "App is running"
    }), 200

# ============================================================================
# Error Handlers
# ============================================================================

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    return jsonify({"error": "Not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    return jsonify({"error": "Internal server error"}), 500

# ============================================================================
# Run Application
# ============================================================================

if __name__ == "__main__":
    print("Starting simple Flask app...")
    app.run(host="0.0.0.0", port=5000, debug=True)
