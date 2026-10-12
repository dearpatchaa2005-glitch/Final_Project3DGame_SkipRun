#!/bin/bash
# ใช้: tools/run_scene.sh res://tools/playtest.tscn mode=shots   (เรนเดอร์จริงผ่าน Xvfb สำหรับตรวจภาพตอนพัฒนา)
G=${GODOT:-/tmp/claude-0/-home-claude/eb5cd129-ae76-52da-b984-f0e3ad224657/scratchpad/godot_bin/Godot_v4.6-stable_linux.x86_64}
cd "$(dirname "$0")/.."
SCENE="$1"; shift
timeout ${TMO:-280} xvfb-run -a -s "-screen 0 1280x720x24" $G --path . --rendering-driver opengl3 --resolution ${RES:-1280x720} "$SCENE" -- "$@" 2>&1 | grep -v -E "ALSA|V-Sync|vsync|audio driver|^\s*$|ERR_CANT_OPEN|init_output_device|audio_server"
