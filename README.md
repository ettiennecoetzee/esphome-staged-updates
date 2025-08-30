# ESPHome Staged Updates for Home Assistant

Two-phase firmware workflow:
1. **Stage**: compile node YAMLs and place binaries in `/config/www/esphome_bins/`  
2. **Push**: at a maintenance window, call `update.install` on each device’s “staged firmware” entity so it downloads and flashes `/local/esphome_bins/<node>.bin`

## Components

- **Blueprint**: `blueprints/automation/esphome/esphome_staged_updates.yaml`  
  Schedule checks (daily, weekly, monthly), select devices, choose **compile only** or **compile and push**, and post reports.

- **Staging script**: `scripts/stage_esphome_bins.sh`  
  Usage: `bash scripts/stage_esphome_bins.sh <binaries_path> <nodes_csv>`  
  Writes `last_run.json` and `last_run.md` to the binaries directory.

- **Device snippet**: `device_snippets/http_request_updater.yaml`  
  Add to each node one time so the device can pull staged firmware by URL.

- **HA config snippets**: `ha/configuration_snippet.yaml`, example automations, and optional “push now” script.

## Install

1. Copy this folder into your Home Assistant `/config` as `/config/esphome-staged-updates`.
2. Add the shell_command from `ha/configuration_snippet.yaml` to your configuration and reload.
3. Place the blueprint file under `/config/blueprints/automation/esphome/` then import it from HA UI.
4. Create `/config/www/esphome_bins` once, or let the script create it.
5. Include `device_snippets/http_request_updater.yaml` in each node and flash once so the new updater is on-device.

## Reports

- JSON: `http://<HA>/local/esphome_bins/last_run.json`  
- Markdown: `http://<HA>/local/esphome_bins/last_run.md`

These list node name, YAML, status, and the saved binary path. Use the Markdown link in notifications for a quick human-readable view.

## Filename rule

Keep **YAML filename stem == node_name == binary filename**. Example: `kitchen-sensor.yaml` becomes `kitchen-sensor.bin`.  
The blueprint derives node names from entities ending with `_staged_firmware` and uses those to compile and push.

## Notes

- First time after adding `ota: platform: http_request` and `update: platform: http_request`, flash once by your usual method.
- Deep sleep devices will update when awake and you trigger `update.install`. Consider a longer window or device-specific scheduling.
- For richer tables in Markdown reports, install `jq` inside your HA host or container.
