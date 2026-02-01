#!/usr/bin/env python3
"""
PDeploy Orchestrator Script
Manages sequential execution of installation modules
"""

import json
import subprocess
import sys
import os
from pathlib import Path
from typing import Dict, List, Optional

class ModuleOrchestrator:
    """Orchestrates the execution of PDeploy installation modules"""
    
    def __init__(self, base_path: str = "."):
        self.base_path = Path(base_path)
        self.modules_path = self.base_path / "modules"
        self.results = []
        
    def get_module_path(self, module_name: str) -> Optional[Path]:
        """Find the module script path"""
        # Search in backend, frontend, and server directories
        for category in ['backend', 'frontend', 'server', 'monitoring']:
            module_path = self.modules_path / category / module_name / "main.sh"
            if module_path.exists():
                return module_path
        return None
    
    def execute_module(self, module_name: str) -> Dict:
        """Execute a single module and return results"""
        # For backward compatibility, collect all streamed output and return final result
        last_result = None
        for result in self.execute_module_stream(module_name):
            last_result = result
            
        if last_result:
            return last_result
            
        return {
            "module": module_name,
            "status": "error",
            "progress": 0,
            "message": "Module execution produced no output",
            "logs": ""
        }

    def execute_module_stream(self, module_name: str):
        """Execute module and yield output lines"""
        module_path = self.get_module_path(module_name)
        
        if not module_path:
            yield {
                "module": module_name,
                "status": "error",
                "progress": 0,
                "message": "Module not found",
                "logs": f"Could not find module script for {module_name}"
            }
            return
        
        try:
            # Execute the module script using Popen for streaming
            process = subprocess.Popen(
                [str(module_path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,  # Line buffered
                cwd=str(self.base_path)
            )
            
            # Read stdout line by line
            for line in process.stdout:
                line = line.strip()
                if not line:
                    continue
                    
                try:
                    # Try to parse JSON lines from the script
                    data = json.loads(line)
                    data["module"] = module_name
                    yield data
                except json.JSONDecodeError:
                    # Yield raw text as logs
                    yield {
                        "module": module_name,
                        "status": "running", 
                        "progress": 0,  # Unknown progress
                        "message": "Log output",
                        "logs": line
                    }
            
            process.wait()
            
            # Check stderr for any error output that wasn't captured
            stderr_output = process.stderr.read()
            if stderr_output:
                 yield {
                    "module": module_name,
                    "status": "warning", 
                    "progress": 0,
                    "message": "Stderr output",
                    "logs": stderr_output
                }

            if process.returncode != 0:
                 yield {
                    "module": module_name,
                    "status": "error",
                    "progress": 0,
                    "message": f"Process failed with code {process.returncode}",
                    "logs": ""
                }
                
        except Exception as e:
            yield {
                "module": module_name,
                "status": "error",
                "progress": 0,
                "message": f"Execution error: {str(e)}",
                "logs": str(e)
            }
    
    def execute_modules(self, module_list: List[str]) -> List[Dict]:
        """Execute multiple modules sequentially"""
        results = []
        
        for module_name in module_list:
            print(f"Executing module: {module_name}", file=sys.stderr)
            result = self.execute_module(module_name)
            results.append(result)
            
            # Output result as JSON for real-time monitoring
            print(json.dumps(result))
            sys.stdout.flush()
            
            # Stop on error if configured
            if result["status"] == "error":
                print(f"Module {module_name} failed, continuing to next module...", file=sys.stderr)
        
        return results
    
    def get_summary(self) -> Dict:
        """Generate execution summary"""
        total = len(self.results)
        successful = sum(1 for r in self.results if r["status"] == "success")
        failed = sum(1 for r in self.results if r["status"] == "error")
        
        return {
            "total": total,
            "successful": successful,
            "failed": failed,
            "results": self.results
        }

def main():
    """Main entry point"""
    if len(sys.argv) < 2:
        print("Usage: orchestrator.py <module1> <module2> ...", file=sys.stderr)
        print("Example: orchestrator.py docker node22 sqlite", file=sys.stderr)
        sys.exit(1)
    
    # Get module list from command line arguments
    modules = sys.argv[1:]
    
    # Create orchestrator
    orchestrator = ModuleOrchestrator()
    
    # Execute modules
    print(f"Starting execution of {len(modules)} modules", file=sys.stderr)
    orchestrator.results = orchestrator.execute_modules(modules)
    
    # Print summary
    summary = orchestrator.get_summary()
    print("\n=== Execution Summary ===", file=sys.stderr)
    print(f"Total: {summary['total']}", file=sys.stderr)
    print(f"Successful: {summary['successful']}", file=sys.stderr)
    print(f"Failed: {summary['failed']}", file=sys.stderr)
    
    # Exit with error code if any module failed
    sys.exit(0 if summary['failed'] == 0 else 1)

if __name__ == "__main__":
    main()
