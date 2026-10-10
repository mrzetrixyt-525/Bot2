'use strict';
const path = require('node:path');
const appDir = process.env.RGNODES_APP_DIR || '/root/Bot2';
const python = process.env.RGNODES_PYTHON || path.join(appDir, '.venv', 'bin', 'python');
module.exports = {
  apps: [{
    name: 'RGNODES-VPS-BOT',
    cwd: appDir,
    script: 'bot.py',
    interpreter: python,
    interpreter_args: '-u',
    exec_mode: 'fork',
    instances: 1,
    autorestart: true,
    restart_delay: 5000,
    max_memory_restart: '768M',
    kill_timeout: 15000,
    merge_logs: true,
    time: false,
    env: { PYTHONUNBUFFERED: '1' }
  }]
};
