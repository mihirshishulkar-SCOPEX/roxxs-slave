#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  ROXX'S SLAVE — DASHBOARD LAUNCHER v14.1                            ║
# ║  Starts the live hunting dashboard at http://localhost:1337          ║
# ╚══════════════════════════════════════════════════════════════════════╝

DASHBOARD_DIR="/home/roxx/dashboard"
PID_FILE="/home/roxx/dashboard/.dashboard.pid"
LOG_FILE="/home/roxx/dashboard/dashboard.log"

R=$'\e[1;31m'; G=$'\e[1;32m'; Y=$'\e[1;33m'; C=$'\e[1;36m'; NC=$'\e[0m'

start() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
    echo -e "${Y}Dashboard already running (PID $(cat $PID_FILE))${NC}"
    echo -e "${G}Open: http://localhost:1337${NC}"
    return
  fi

  # Install deps silently if missing
  python3 -c "import flask_socketio" 2>/dev/null || \
    pip3 install flask flask-socketio eventlet -q

  bash /usr/local/bin/roxx-banner 2>/dev/null || true

  echo -e "\n${R}  ROXX'S SLAVE — LAUNCHING DASHBOARD${NC}"
  echo -e "  ${G}→ http://localhost:1337${NC}\n"

  nohup python3 "${DASHBOARD_DIR}/server.py" >> "$LOG_FILE" 2>&1 &
  DPID=$!
  echo "$DPID" > "$PID_FILE"

  sleep 2
  if kill -0 "$DPID" 2>/dev/null; then
    echo -e "  ${G}✔ Dashboard started (PID ${DPID})${NC}"
    echo -e "  ${G}✔ http://localhost:1337${NC}"
    echo -e "  ${C}  Log: ${LOG_FILE}${NC}"
    # Try to open browser
    command -v xdg-open &>/dev/null && xdg-open "http://localhost:1337" &>/dev/null &
    command -v open      &>/dev/null && open      "http://localhost:1337" &>/dev/null &
  else
    echo -e "  ${R}✘ Dashboard failed to start — check: ${LOG_FILE}${NC}"
    rm -f "$PID_FILE"
  fi
}

stop() {
  if [[ -f "$PID_FILE" ]]; then
    kill "$(cat $PID_FILE)" 2>/dev/null
    rm -f "$PID_FILE"
    echo -e "${G}Dashboard stopped.${NC}"
  else
    echo -e "${Y}Dashboard not running.${NC}"
  fi
}

status() {
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat $PID_FILE)" 2>/dev/null; then
    echo -e "${G}✔ Dashboard RUNNING — PID $(cat $PID_FILE) — http://localhost:1337${NC}"
  else
    echo -e "${R}✘ Dashboard NOT running${NC}"
  fi
}

logs() { tail -f "$LOG_FILE"; }

case "${1:-start}" in
  start)  start  ;;
  stop)   stop   ;;
  restart) stop; sleep 1; start ;;
  status) status ;;
  logs)   logs   ;;
  *)      echo "Usage: $0 {start|stop|restart|status|logs}" ;;
esac
