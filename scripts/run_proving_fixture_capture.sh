#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 4 ]]; then
  echo "usage: $0 <fixture.yaml> <video.mp4> [output-dir] [capture-delay-ms]" >&2
  exit 2
fi

fixture_path="$1"
video_path="$2"
output_root="${3:-.testbed/test-results/fixtures}"
capture_delay_ms="${4:-5000}"

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

if [[ ! -f "$fixture_path" ]]; then
  echo "fixture not found: $fixture_path" >&2
  exit 3
fi
if [[ ! -f "$video_path" ]]; then
  echo "video not found: $video_path" >&2
  exit 4
fi

fixture_id="$(grep -E '^fixture_id:' "$fixture_path" | head -n1 | cut -d: -f2- | xargs)"
family="$(grep -E '^family:' "$fixture_path" | head -n1 | cut -d: -f2- | xargs)"
if [[ -z "$fixture_id" ]]; then
  fixture_id="$(basename "$fixture_path" .fixture.yaml)"
fi

scene_path="res://scenes/boxing_proving.tscn"
case "$family" in
  flow)
    scene_path="res://scenes/flow_proving.tscn"
    ;;
  boxing|"")
    scene_path="res://scenes/boxing_proving.tscn"
    ;;
  *)
    echo "unsupported fixture family in $fixture_path: $family" >&2
    exit 5
    ;;
esac

run_id="$(date +%Y%m%d-%H%M%S)__${fixture_id}"
out_dir="$output_root/$run_id"
mkdir -p "$out_dir"
log_path="$out_dir/godot.log"

export AEROBEAT_MEDIAPIPE_CAMERA_SOURCE="$video_path"
export AEROBEAT_MEDIAPIPE_SHOW_WINDOW=0

echo "[run_proving_fixture_capture] fixture=$fixture_path"
echo "[run_proving_fixture_capture] video=$video_path"
echo "[run_proving_fixture_capture] scene=$scene_path"
echo "[run_proving_fixture_capture] out_dir=$out_dir"

godot --path .testbed -s res://scripts/capture_fixture_proving.gd -- \
  "$scene_path" \
  "$fixture_path" \
  "$video_path" \
  "$out_dir" \
  "$capture_delay_ms" \
  >"$log_path" 2>&1

echo "log=$log_path"
echo "report=$out_dir/report.json"
echo "report_md=$out_dir/report.md"
echo "screenshot=$out_dir/proving.png"
