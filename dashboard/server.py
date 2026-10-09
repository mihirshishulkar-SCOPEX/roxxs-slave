#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════════╗
║  ROXX'S SLAVE — LIVE HUNTING DASHBOARD v14.1                        ║
║  http://localhost:1337                                               ║
║  Real-time target tracking, stage monitoring, findings feed         ║
╚══════════════════════════════════════════════════════════════════════╝
"""
import os, json, time, glob, subprocess, threading, hashlib, signal, sys
from datetime import datetime
from pathlib import Path
from flask import Flask, render_template, request, jsonify
from flask_socketio import SocketIO, emit

# ── Config ─────────────────────────────────────────────────────────────
BASE        = Path("/home/roxx/findings")
DATA_DIR    = Path("/home/roxx/dashboard/data")
TARGETS_F   = DATA_DIR / "targets.json"
SESSIONS_F  = DATA_DIR / "sessions.json"
FINDINGS_F  = DATA_DIR / "findings.json"
STAGES_F    = DATA_DIR / "stages.json"

for d in [DATA_DIR, BASE/"targets", BASE/"iot", BASE/"wireless",
          BASE/"recon", BASE/"chains", BASE/"pocs", BASE/"reports", BASE/"secrets"]:
    d.mkdir(parents=True, exist_ok=True)

# ── Flask app ──────────────────────────────────────────────────────────
app = Flask(__name__, template_folder="/home/roxx/dashboard/templates",
            static_folder="/home/roxx/dashboard/static")
app.config["SECRET_KEY"] = "roxx-slave-dashboard-secret"
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="threading")

# ── Hunt stages definition ─────────────────────────────────────────────
HUNT_STAGES = [
    {"id": "recon",    "label": "01 RECON",        "icon": "🔍", "tools": ["subfinder","amass","httpx","dnsx","naabu"]},
    {"id": "enum",     "label": "02 ENUM",          "icon": "📡", "tools": ["katana","feroxbuster","ffuf","gobuster","waybackurls"]},
    {"id": "scan",     "label": "03 VULN SCAN",     "icon": "⚡", "tools": ["nuclei","nikto","dalfox","sqlmap","testssl"]},
    {"id": "iot",      "label": "04 IoT/WIRELESS",  "icon": "📶", "tools": ["nmap-iot","shodan","masscan","bettercap","aircrack-ng"]},
    {"id": "exploit",  "label": "05 EXPLOIT",       "icon": "💥", "tools": ["sqlmap","jwt-tool","ghauri","mcp-scan","custom"]},
    {"id": "chain",    "label": "06 CHAIN",         "icon": "🔗", "tools": ["manual","burpsuite","interactsh"]},
    {"id": "report",   "label": "07 REPORT",        "icon": "📋", "tools": ["h1","bugcrowd","intigriti"]},
]

# ── Data helpers ───────────────────────────────────────────────────────
def _load(path, default):
    try:
        if path.exists(): return json.loads(path.read_text())
    except: pass
    return default

def _save(path, data):
    path.write_text(json.dumps(data, indent=2, default=str))

def now_str():
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

# ── Scan findings dir for activity ────────────────────────────────────
def scan_findings():
    findings = []
    for cat in ["pocs","reports","secrets","chains","recon","iot","wireless"]:
        cat_dir = BASE / cat
        if not cat_dir.exists(): continue
        for f in sorted(cat_dir.glob("*"), key=lambda x: x.stat().st_mtime, reverse=True)[:20]:
            if f.is_file():
                stat = f.stat()
                findings.append({
                    "id":       hashlib.md5(str(f).encode()).hexdigest()[:8],
                    "category": cat.upper(),
                    "name":     f.name,
                    "size":     stat.st_size,
                    "mtime":    datetime.fromtimestamp(stat.st_mtime).strftime("%Y-%m-%d %H:%M:%S"),
                    "path":     str(f),
                    "preview":  _preview(f),
                })
    return sorted(findings, key=lambda x: x["mtime"], reverse=True)[:100]

def _preview(path):
    try:
        txt = Path(path).read_text(errors="ignore")[:300]
        return txt.replace("\n"," ").strip()
    except: return ""

def get_stats():
    stats = {}
    for cat in ["pocs","reports","secrets","chains","recon","iot","wireless","targets"]:
        d = BASE / cat
        stats[cat] = len(list(d.glob("*"))) if d.exists() else 0
    return stats

# ── Background watcher — pushes updates every 3s ──────────────────────
_last_hash = ""
def watcher():
    global _last_hash
    while True:
        try:
            targets  = _load(TARGETS_F, [])
            stages   = _load(STAGES_F, {})
            findings = scan_findings()
            stats    = get_stats()
            payload  = {"targets": targets, "stages": stages,
                        "findings": findings, "stats": stats, "ts": now_str()}
            h = hashlib.md5(json.dumps(payload, default=str).encode()).hexdigest()
            if h != _last_hash:
                _last_hash = h
                socketio.emit("update", payload)
        except Exception as e:
            pass
        time.sleep(3)

# ── REST API ──────────────────────────────────────────────────────────

@app.route("/")
def index():
    return render_template("dashboard.html", stages=HUNT_STAGES)

@app.route("/api/targets", methods=["GET"])
def get_targets():
    return jsonify(_load(TARGETS_F, []))

@app.route("/api/targets", methods=["POST"])
def add_target():
    data = request.json
    targets = _load(TARGETS_F, [])
    target = {
        "id":         hashlib.md5(f"{data.get('domain','')}{time.time()}".encode()).hexdigest()[:8],
        "domain":     data.get("domain","").strip(),
        "program":    data.get("program","HackerOne"),
        "scope":      data.get("scope",""),
        "platform":   data.get("platform","web"),   # web | iot | wireless | mobile | api
        "severity":   data.get("severity","HIGH"),
        "status":     "ACCEPTED",
        "stage":      "recon",
        "progress":   0,
        "bounty_est": data.get("bounty_est","$0"),
        "notes":      data.get("notes",""),
        "created":    now_str(),
        "updated":    now_str(),
        "findings":   [],
        "tags":       data.get("tags","").split(",") if data.get("tags") else [],
    }
    targets.insert(0, target)
    _save(TARGETS_F, targets)
    # Create target dir
    (BASE / "targets" / target["id"]).mkdir(exist_ok=True)
    socketio.emit("target_added", target)
    return jsonify({"ok": True, "target": target})

@app.route("/api/targets/<tid>", methods=["PATCH"])
def update_target(tid):
    targets  = _load(TARGETS_F, [])
    data     = request.json
    for t in targets:
        if t["id"] == tid:
            t.update({k: v for k, v in data.items() if k != "id"})
            t["updated"] = now_str()
    _save(TARGETS_F, targets)
    socketio.emit("target_updated", {"id": tid, **data})
    return jsonify({"ok": True})

@app.route("/api/targets/<tid>", methods=["DELETE"])
def delete_target(tid):
    targets = [t for t in _load(TARGETS_F, []) if t["id"] != tid]
    _save(TARGETS_F, targets)
    return jsonify({"ok": True})

@app.route("/api/stage", methods=["POST"])
def set_stage():
    data   = request.json
    stages = _load(STAGES_F, {})
    tid    = data.get("target_id")
    stage  = data.get("stage")
    prog   = data.get("progress", 0)
    log    = data.get("log", "")
    if tid not in stages:
        stages[tid] = {}
    stages[tid][stage] = {"progress": prog, "log": log, "ts": now_str(), "status": data.get("status","running")}
    _save(STAGES_F, stages)
    # Also update target's current stage
    targets = _load(TARGETS_F, [])
    for t in targets:
        if t["id"] == tid:
            t["stage"]    = stage
            t["progress"] = prog
            t["updated"]  = now_str()
    _save(TARGETS_F, targets)
    socketio.emit("stage_update", {"target_id": tid, "stage": stage, "progress": prog, "log": log})
    return jsonify({"ok": True})

@app.route("/api/finding", methods=["POST"])
def add_finding():
    data = request.json
    tid  = data.get("target_id","global")
    finding = {
        "id":       hashlib.md5(f"{tid}{time.time()}".encode()).hexdigest()[:8],
        "target":   tid,
        "title":    data.get("title",""),
        "type":     data.get("type",""),           # SQLI|XSS|SSRF|IDOR|RCE|CHAIN|IoT|WIRELESS|...
        "severity": data.get("severity","HIGH"),   # CRITICAL|HIGH|MEDIUM
        "status":   data.get("status","FOUND"),    # FOUND|CONFIRMED|REPORTED|BOUNTY_PAID
        "impact":   data.get("impact",""),
        "url":      data.get("url",""),
        "payload":  data.get("payload",""),
        "bounty":   data.get("bounty",""),
        "ts":       now_str(),
    }
    # Save to findings dir
    cat = "iot" if "iot" in data.get("type","").lower() else \
          "wireless" if "wireless" in data.get("type","").lower() else "pocs"
    fpath = BASE / cat / f"{finding['id']}_{finding['type']}.json"
    fpath.write_text(json.dumps(finding, indent=2))
    socketio.emit("new_finding", finding)
    return jsonify({"ok": True, "finding": finding})

@app.route("/api/findings", methods=["GET"])
def get_findings():
    return jsonify(scan_findings())

@app.route("/api/stats", methods=["GET"])
def api_stats():
    return jsonify(get_stats())

@app.route("/api/run", methods=["POST"])
def run_tool():
    """Run a recon tool against a target — non-blocking, streams output via SocketIO"""
    data   = request.json
    cmd    = data.get("cmd","")
    tid    = data.get("target_id","")
    label  = data.get("label", cmd[:40])
    if not cmd:
        return jsonify({"ok": False, "error": "no cmd"})
    def _run():
        out_lines = []
        socketio.emit("tool_start", {"target_id": tid, "label": label, "cmd": cmd})
        try:
            proc = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True,
                                    cwd=str(BASE / "recon"))
            for line in proc.stdout:
                line = line.rstrip()
                out_lines.append(line)
                socketio.emit("tool_output", {"target_id": tid, "label": label, "line": line})
            proc.wait()
        except Exception as e:
            socketio.emit("tool_output", {"target_id": tid, "label": label, "line": f"[ERR] {e}"})
        socketio.emit("tool_done", {"target_id": tid, "label": label,
                                    "lines": len(out_lines), "ts": now_str()})
    threading.Thread(target=_run, daemon=True).start()
    return jsonify({"ok": True})

@socketio.on("connect")
def on_connect():
    targets  = _load(TARGETS_F, [])
    stages   = _load(STAGES_F, {})
    findings = scan_findings()
    stats    = get_stats()
    emit("init", {"targets": targets, "stages": stages,
                  "findings": findings, "stats": stats,
                  "hunt_stages": HUNT_STAGES, "ts": now_str()})

# ── Startup ────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("\033[1;31m")
    print("  ██████╗  ██████╗  ██╗  ██╗ ██╗  ██╗")
    print("  ██╔══██╗██╔═══██╗ ╚██╗██╔╝ ╚██╗██╔╝")
    print("  ██████╔╝██║   ██║  ╚███╔╝   ╚███╔╝ ")
    print("  ██╔══██╗██║   ██║  ██╔██╗   ██╔██╗ ")
    print("  ██║  ██║╚██████╔╝ ██╔╝ ██╗ ██╔╝ ██╗")
    print("  ╚═╝  ╚═╝ ╚═════╝  ╚═╝  ╚═╝ ╚═╝  ╚═╝\033[0m")
    print("\n  \033[1;31mROXX'S SLAVE — LIVE HUNTING DASHBOARD v14.1\033[0m")
    print("  \033[1;32m🔥 http://localhost:1337\033[0m")
    print("  \033[2mCtrl+C to stop\033[0m\n")
    threading.Thread(target=watcher, daemon=True).start()
    socketio.run(app, host="0.0.0.0", port=1337, debug=False, allow_unsafe_werkzeug=True)
