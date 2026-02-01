from flask import Flask, jsonify, request, Response, stream_with_context
from flask_cors import CORS
import subprocess
import json
import os
import sys
from orchestrator import ModuleOrchestrator

app = Flask(__name__)
# Enable CORS to allow the frontend to communicate with the backend
# In production content security policies should be tighter, but this is an internal tool
CORS(app)

@app.route('/health', methods=['GET'])
def health_check():
    """Simple health check endpoint"""
    return jsonify({"status": "ok", "service": "pdeploy-backend"})

@app.route('/api/modules', methods=['GET'])
def list_modules():
    """List available modules from filesystem"""
    try:
        # Use orchestrator to find modules
        orchestrator = ModuleOrchestrator()
        modules = {}
        for category in ['backend', 'frontend', 'server']:
            cat_path = orchestrator.modules_path / category
            if cat_path.exists():
                modules[category] = [
                    d.name for d in cat_path.iterdir() 
                    if d.is_dir() and (d / "main.sh").exists()
                ]
        return jsonify({"success": True, "modules": modules})
    except Exception as e:
        return jsonify({"success": False, "error": str(e)}), 500

@app.route('/api/install', methods=['POST'])
def install_modules():
    """Execute installation of selected modules and stream results"""
    data = request.json
    if not data:
        return jsonify({"error": "No data provided"}), 400
        
    modules = data.get('modules', [])
    if not modules:
        return jsonify({"error": "No modules selected"}), 400
    
    def generate():
        orchestrator = ModuleOrchestrator()
        
        # Stream start event
        yield json.dumps({"type": "start", "count": len(modules)}) + "\n"
        
        for module in modules:
            yield json.dumps({"type": "module_start", "module": module}) + "\n"
            
            # Execute module and stream output
            # We need to update orchestrator.py to support streaming or yielding first
            # Ideally execute_module_stream would be used here
            if hasattr(orchestrator, 'execute_module_stream'):
                for update in orchestrator.execute_module_stream(module):
                    yield json.dumps({
                        "type": "progress", 
                        "module": module, 
                        "data": update
                    }) + "\n"
            else:
                # Fallback if streaming not implemented yet
                result = orchestrator.execute_module(module)
                yield json.dumps({
                    "type": "result", 
                    "module": module, 
                    "data": result
                }) + "\n"
                
            yield json.dumps({"type": "module_end", "module": module}) + "\n"
            
        yield json.dumps({"type": "complete"}) + "\n"
            
    return Response(stream_with_context(generate()), mimetype='application/x-ndjson')

if __name__ == '__main__':
    print("Starting PDeploy Backend on 0.0.0.0:8000")
    app.run(host='0.0.0.0', port=8000, debug=True)
