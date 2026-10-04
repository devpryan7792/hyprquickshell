#!/usr/bin/env python3
import os
import time
import json
import subprocess

def get_top_ram():
    procs = []
    try:
        res = subprocess.check_output(['ps', '-eo', 'pid,%mem,rss,comm', '--sort=-rss'], timeout=1).decode()
        lines = res.strip().split('\n')[1:11]
        for l in lines:
            parts = l.strip().split(None, 3)
            if len(parts) == 4:
                pid = parts[0]
                pct = parts[1]
                try:
                    rss_kb = int(parts[2])
                except ValueError:
                    continue
                raw_name = parts[3]
                # Friendlier names
                clean_name = raw_name
                if "Isolated Web" in raw_name or "WebExtensions" in raw_name or "Privileged Cont" in raw_name:
                    clean_name = "Firefox (Tab)"

                if rss_kb > 1024*1024:
                    mem_str = f"{rss_kb / (1024*1024):.1f} GB"
                else:
                    mem_str = f"{rss_kb / 1024:.0f} MB"

                procs.append({
                    "pid": pid,
                    "name": clean_name,
                    "pct": pct + "%",
                    "mem": mem_str
                })
    except Exception:
        pass
    return procs

def get_stats():
    # 1. CPU
    cpu_pct = 0
    try:
        with open('/proc/stat') as f:
            fields = [float(c) for c in f.readline().strip().split()[1:]]
        idle1, total1 = fields[3], sum(fields)
        time.sleep(0.06)
        with open('/proc/stat') as f:
            fields = [float(c) for c in f.readline().strip().split()[1:]]
        idle2, total2 = fields[3], sum(fields)
        idle_delta, total_delta = idle2 - idle1, total2 - total1
        if total_delta > 0:
            cpu_pct = max(0, min(100, int(100.0 * (1.0 - idle_delta / total_delta))))
    except Exception:
        pass

    # 2. RAM
    ram_pct = 0
    ram_used_str = "0G / 0G"
    try:
        with open('/proc/meminfo') as f:
            lines = f.readlines()
        mem = {l.split(':')[0].strip(): int(l.split(':')[1].split()[0]) for l in lines if ':' in l}
        total_ram = mem.get('MemTotal', 1)
        avail_ram = mem.get('MemAvailable', 0)
        used_ram = total_ram - avail_ram
        ram_pct = max(0, min(100, int((used_ram / total_ram) * 100)))
        ram_used_str = f"{used_ram / (1024*1024):.1f}G / {total_ram / (1024*1024):.1f}G"
    except Exception:
        pass

    # 3. Disk
    disk_pct = 0
    disk_used_str = "0G / 0G"
    try:
        st = os.statvfs('/')
        disk_total = (st.f_blocks * st.f_frsize) / (1024**3)
        disk_avail = (st.f_bavail * st.f_frsize) / (1024**3)
        disk_used = disk_total - disk_avail
        disk_pct = max(0, min(100, int((disk_used / disk_total) * 100)))
        disk_used_str = f"{disk_used:.1f}G / {disk_total:.0f}G"
    except Exception:
        pass

    top_procs = get_top_ram()

    return {
        "cpu_pct": cpu_pct,
        "ram_pct": ram_pct,
        "ram_str": ram_used_str,
        "disk_pct": disk_pct,
        "disk_str": disk_used_str,
        "top_procs": top_procs
    }

if __name__ == "__main__":
    print(json.dumps(get_stats()))
