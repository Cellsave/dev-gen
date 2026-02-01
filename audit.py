import platform
import shutil
import subprocess
import sys

# Resource requirements (MB RAM, MB Disk)
MODULE_REQUIREMENTS = {
    # Backend
    "docker": {"ram": 512, "disk": 1000},
    "node22": {"ram": 256, "disk": 500},
    "sqlite": {"ram": 64, "disk": 100},
    # Frontend
    "react18": {"ram": 512, "disk": 500},
    # Server
    "linux-tools": {"ram": 64, "disk": 200},
    # Monitoring
    "filebeat": {"ram": 128, "disk": 200},
    "logstash": {"ram": 1024, "disk": 500},
    "elasticsearch": {"ram": 2048, "disk": 2000},
    "kibana": {"ram": 1024, "disk": 1000},
    "prometheus": {"ram": 512, "disk": 500},
    "grafana": {"ram": 256, "disk": 300},
}

def get_system_resources():
    """Get current system resources"""
    resources = {
        "os": platform.system() + " " + platform.release(),
        "ram_total_mb": 0,
        "disk_free_mb": 0,
        "cpu_cores": 0
    }
    
    try:
        # Memory
        if platform.system() == "Linux":
            with open('/proc/meminfo', 'r') as f:
                for line in f:
                    if "MemTotal" in line:
                        kb = int(line.split()[1])
                        resources["ram_total_mb"] = kb // 1024
                        break
        else:
            # Fallback for dev on Windows/Mac (Not accurate but prevents crash)
            resources["ram_total_mb"] = 16384 

        # Disk
        total, used, free = shutil.disk_usage("/")
        resources["disk_free_mb"] = free // (1024 * 1024)
        
        # CPU
        resources["cpu_cores"] = subprocess.check_output(["nproc"]).decode().strip()
    except:
        pass
        
    return resources

def audit_requirements(selected_modules):
    """Check if system meets requirements for selected modules"""
    system = get_system_resources()
    total_ram_needed = 1024 # Base OS overhead
    total_disk_needed = 2000 # Base OS overhead
    
    details = []
    
    for module in selected_modules:
        req = MODULE_REQUIREMENTS.get(module, {"ram": 0, "disk": 0})
        total_ram_needed += req["ram"]
        total_disk_needed += req["disk"]
        details.append({
            "module": module,
            "ram": req["ram"],
            "disk": req["disk"]
        })
        
    checks = {
        "ram": {
            "needed": total_ram_needed,
            "available": system["ram_total_mb"],
            "pass": system["ram_total_mb"] >= total_ram_needed
        },
        "disk": {
            "needed": total_disk_needed,
            "available": system["disk_free_mb"],
            "pass": system["disk_free_mb"] >= total_disk_needed
        },
        "os": {
            "value": system["os"],
            "pass": "Linux" in system["os"] or "Windows" in system["os"] # Allow Windows for dev
        }
    }
    
    overall_pass = checks["ram"]["pass"] and checks["disk"]["pass"]
    
    return {
        "passed": overall_pass,
        "checks": checks,
        "details": details
    }
