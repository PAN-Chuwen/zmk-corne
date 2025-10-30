---
description: "Launch development servers (uvicorn + vite) with auto or manual ports"
argument-hint: "[backend-port] [frontend-port]"
allowed-tools: ["Bash"]
---

Launch development servers: ${1:-auto} ${2:-auto}

🚀 **Auto-Server Launch**: Starts both backend and frontend with conflict-free ports.

**Usage Options:**
- `/launch-server` - Auto-assign ports based on branch name
- `/launch-server 8200` - Manual backend port, auto frontend port
- `/launch-server 8200 9300` - Manual both ports

**What this command does:**
1. **Port Detection**: Check if specified ports are available
2. **Port Assignment**: Auto-assign if not specified, using branch name hash
3. **Backend Launch**: Start uvicorn with Python environment
4. **Frontend Launch**: Start vite dev server
5. **Background Processes**: Both servers run in background
6. **Display Info**: Show URLs and how to stop servers

**Port Assignment Logic (when auto):**
- **Sequential assignment**: 1st worktree uses 8200/9200, 2nd uses 8201/9201, 3rd uses 8202/9202
- **Detection**: Scans existing processes to find next available ports in sequence
- **Predictable**: Easy to pre-forward ports 8200-8202 and 9200-9202 in SSH config
- **Max 3 parallel servers**: Supports up to 3 concurrent development environments

**Commands executed:**
1. `pwd` - Show current directory and branch
2. Parse arguments: backend_port=$1, frontend_port=$2
3. **Auto port detection** (if not specified):
   - Check ports 8200, 8201, 8202 for backend (use first available)
   - Check ports 9200, 9201, 9202 for frontend (use corresponding slot)
4. **Port conflict check**: `lsof -i :$port` for each final port
5. If conflict detected: Show error and exit
6. `source ~/.zshrc && conda activate llm-web` - Setup Python env
7. `cd proxy-server && uvicorn main:app --port <backend_port> --host 0.0.0.0 --forwarded-allow-ips '*' --reload --env-file .env.development &`
8. `cd web && npm run dev -- --port <frontend_port> --host 0.0.0.0 &`
9. Display server URLs and PIDs
10. Show stop commands for the specific ports used

**Example outputs:**
```bash
# Auto mode - 1st worktree
✅ Servers launched for branch: feat/user-auth
🔗 Backend:  http://localhost:8200 (auto - slot 1)
🔗 Frontend: http://localhost:9200 (auto - slot 1)

# Auto mode - 2nd worktree
✅ Servers launched for branch: docs/api-guide
🔗 Backend:  http://localhost:8201 (auto - slot 2)
🔗 Frontend: http://localhost:9201 (auto - slot 2)

# Manual mode (classic dev ports)
✅ Servers launched with custom ports
🔗 Backend:  http://localhost:8154 (manual)
🔗 Frontend: http://localhost:8155 (manual)

# All slots used
❌ All development slots (8200-8202) are in use
   Stop existing servers or use manual ports: /launch-server 8154 8155
```

**SSH Port Forwarding Setup:**
```bash
# Add to ~/.ssh/config or use in command line
ssh -L 8200:localhost:8200 -L 8201:localhost:8201 -L 8202:localhost:8202 \
    -L 9200:localhost:9200 -L 9201:localhost:9201 -L 9202:localhost:9202 \
    -L 8154:localhost:8154 -L 8155:localhost:8155 server
```

**🛑 STOP CONDITIONS:**
- If specified ports are already in use
- If not in a valid git worktree
- If Python environment or npm packages missing

**To stop servers**: `pkill -f "port <backend_port>" && pkill -f "port <frontend_port>"`