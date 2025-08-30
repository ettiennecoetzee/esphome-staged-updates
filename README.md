# ESPHome Staged Updates for Home Assistant

[![Import this Blueprint into Home Assistant](https://my.home-assistant.io/badges/blueprint_import.svg)](https://my.home-assistant.io/redirect/blueprint_import/?blueprint_url=https://github.com/<your-username>/esphome-staged-updates/blob/main/blueprints/automation/esphome/esphome_staged_updates.yaml)

---

## 🎯 Purpose

This project provides a **two-phase ESPHome firmware update system** for Home Assistant:

1. **Stage (Compile):** Build firmware binaries for your ESPHome devices ahead of time.  
   - Compiles all device YAMLs on your Home Assistant server.  
   - Saves binaries to `/config/www/esphome_bins/`.  
   - Generates JSON and Markdown reports to show which devices compiled successfully.

2. **Push (Install):** At your chosen maintenance time, update devices in bulk.  
   - Each device downloads its precompiled binary from your Home Assistant server (`/local/esphome_bins/<node>.bin`).  
   - Installs are faster because the compile step is already done.  
   - Optional mobile notifications tell you when staging starts and when push completes.

✅ Result: Less downtime, predictable updates, and clear reporting.

---

## 🔧 Installation Instructions (Beginner-Friendly)

### 1. Download this project
1. Click the green **Code** button on this repository page.  
2. Choose **Download ZIP**.  
3. Unzip the file on your computer.  
4. Copy the whole folder `esphome-staged-updates` into your Home Assistant `/config/` directory.  

You should now have:  
```
/config/esphome-staged-updates/
```

---

### 2. Create the folder for staged binaries
Inside your `/config/www/` directory, create a folder called `esphome_bins`.  
So you’ll have:  
```
/config/www/esphome_bins/
```

(Home Assistant automatically makes files in `/config/www/` available at `http://<HA>/local/...`.)

---

### 3. Add the shell command
Open your **configuration.yaml** file and paste this at the bottom:

```yaml
shell_command:
  esphome_stage_bins: 'bash /config/esphome-staged-updates/scripts/stage_esphome_bins.sh "{{ binaries_path }}" "{{ nodes_csv }}"'
```

💡 Tip: If you already have a `shell_command:` section, just add the `esphome_stage_bins:` line under it.  

Then restart Home Assistant to apply the change.

---

### 4. Import the Blueprint
1. Copy this link:  
   ```
   https://github.com/<your-username>/esphome-staged-updates/blob/main/blueprints/automation/esphome/esphome_staged_updates.yaml
   ```
2. In Home Assistant, go to: **Settings → Automations & Scenes → Blueprints → Import Blueprint**.  
3. Paste the link and click **Preview → Import**.  
4. You will now see **ESPHome Staged Updates (Compile or Compile+Push)** in your Blueprint list.

---

### 5. Update each ESPHome device (one time only)
Each ESPHome device needs a small snippet added so it can fetch staged binaries later.

1. Open the device’s YAML file in ESPHome.  
2. Add this block (adjust `devicename` to match your node’s name/YAML filename):  

```yaml
substitutions:
  node_name: ${devicename}
  friendly_name: ${devicename}

http_request:

ota:
  - platform: esphome
  - platform: http_request

update:
  - platform: http_request
    name: "${friendly_name} staged firmware"
    source: "http://homeassistant.local:8123/local/esphome_bins/manifest.json"
```

3. Re-flash the device once (USB or OTA).  
   After this, the device will have a new “staged firmware” update entity in Home Assistant.

---

### 6. Create your automation from the Blueprint
1. Go to **Settings → Automations & Scenes → + Create Automation → From Blueprint**.  
2. Choose **ESPHome Staged Updates (Compile or Compile+Push)**.  
3. Fill in the options:
   - How often to check (daily/weekly/monthly).  
   - What time of day to check.  
   - Which ESPHome devices to include (all, or select individually).  
   - Whether to **Compile only** or **Compile and Push**.  
   - If you choose **Compile and Push**, also pick the “maintenance window” time when updates should actually be installed.  
   - Optional: enter a `notify.mobile_app_xxx` service if you want mobile notifications.

---

### 7. Done!
- When an ESPHome update is detected, the automation will **compile** the binaries in advance.  
- At your chosen maintenance time, it will **push** the updates to the devices you selected.  
- Reports are saved as:  
  - JSON: `http://<HA>/local/esphome_bins/last_run.json`  
  - Markdown (easy to read): `http://<HA>/local/esphome_bins/last_run.md`

💡 **Tip for beginners**:  
If something goes wrong, check **Settings → System → Logs** in Home Assistant. Errors from the staging script or blueprint will show there.

---

## 📊 Reports

- **JSON report** — structured data about compile results (for scripts or advanced users).  
- **Markdown report** — human-readable summary with a table of device names, YAMLs, status, and binary locations.

Both are saved in `/config/www/esphome_bins/` and available via:  
- `http://<HA>/local/esphome_bins/last_run.json`  
- `http://<HA>/local/esphome_bins/last_run.md`

---

## 🚀 Features at a glance
- Detects ESPHome releases automatically.  
- Lets you choose which devices to update.  
- Two modes: **Compile only** or **Compile and Push**.  
- Scheduled, predictable updates.  
- Clear notifications + optional mobile push.  
- Reports every compile/push result.

---
