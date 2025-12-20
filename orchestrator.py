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
        for category in ['backend', 'frontend', 'server']:
            module_path = self.modules_path / category / module_name / "main.sh"
            if module_path.exists():
                return module_path
        return None
    
    def execute_module(self, module_name: str) -> Dict:
        """Execute a single module and return results"""
        module_path = self.get_module_path(module_name)
        
        if not module_path:
            return {
                "module": module_name,
                "status": "error",
                "progress": 0,
                "message": "Module not found",
                "logs": f"Could not find module script for {module_name}"
            }
        
        try:
            # Execute the module script
            result = subprocess.run(
                [str(module_path)],
                capture_output=True,
                text=True,
                timeout=600  # 10 minute timeout
            )
            
            # Try to parse JSON output
            try:
                output = json.loads(result.stdout.strip().split('\n')[-1])
                output["module"] = module_name
                return output
            except json.JSONDecodeError:
                # If JSON parsing fails, return raw output
                return {
                    "module": module_name,
                    "status": "error" if result.returncode != 0 else "success",
                    "progress": 100 if result.returncode == 0 else 0,
                    "message": "Execution completed" if result.returncode == 0 else "Execution failed",
                    "logs": result.stdout + "\n" + result.stderr
                }
                
        except subprocess.TimeoutExpired:
            return {
                "module": module_name,
                "status": "error",
                "progress": 0,
                "message": "Module execution timed out",
                "logs": "Execution exceeded 10 minute timeout"
            }
        except Exception as e:
            return {
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
