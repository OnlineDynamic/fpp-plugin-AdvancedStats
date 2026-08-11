# Advanced Stats Plugin for FPP

This is the home of the Advanced Stats FPP Plugin Repository

The purpose of this FPP plugin is to provide comprehensive analytics and statistics tracking for your Falcon Player (FPP) system.

## Requirements

- **FPP Version**: 9.0 or higher

## Features

- 📊 **Real-time Statistics** - Monitor system performance as it happens
- 📈 **Historical Analytics** - Track trends and patterns over time
- 📝 **Detailed Logging** - Comprehensive logging of playlist and sequence activity
- 🔌 **GPIO Integration** - Hardware button support for physical controls
- ⚙️ **REST API** - Full programmatic control via HTTP endpoints
- 🔄 **MQTT Event Capture** - Real-time event tracking via FPP's MQTT broker

## Event Tracking

The plugin automatically tracks:
- **GPIO Events**: All GPIO pin state changes
- **Sequence Plays**: Start/stop of sequences with duration tracking
- **Playlist Activity**: Playlist start/stop events

### MQTT Integration

The plugin uses FPP's built-in MQTT broker to capture events in real-time. 

**Prerequisites:**
1. Enable MQTT in FPP: **Content Setup** → **System Settings** → **MQTT** → Enable checkbox
2. The plugin's MQTT listener starts automatically when FPP starts
3. Events are captured and logged to the database instantly

**MQTT Topics Monitored:**
- `falcon/player/+/event/sequence/#` - Sequence events
- `falcon/player/+/event/playlist/#` - Playlist events
- `falcon/player/+/gpio/#` - GPIO state changes
- `falcon/player/+/status` - System status

**Manual Control (if needed):**
```bash
# Check if MQTT listener is running
pgrep -f mqtt_listener.py

# View MQTT listener logs
tail -f /home/fpp/media/logs/fpp-plugin-AdvancedStats.log

# Manually start listener (usually not needed)
cd /home/fpp/media/plugins/fpp-plugin-AdvancedStats
python3 mqtt_listener.py

# Stop listener
pkill -f mqtt_listener.py
```

## Technical Requirements

### Git-based Installation

The plugin supports automatic update checking when installed via git through FPP's Plugin Manager.

### Automatic Update Notifications

The plugin checks for updates automatically when internet is available:

- 🔍 Checks GitHub repository hourly for new versions
- 📢 Shows notification banner when updates are available
- 🌿 **Branch-aware**: Automatically checks the correct branch based on your FPP version (defined in pluginInfo.json)
- ⚙️ Uses FPP's native version management (git commits)
- 🌐 Only checks when system has internet connectivity
- ❌ Can be dismissed if you prefer to update later
- 🔄 Update via FPP's Plugin Manager

**How it works:**

- Reads `pluginInfo.json` to determine which branch to check based on FPP version
- Compares local git commit with remote repository
- Shows notification with commit count and latest changes
- Provides direct link to Plugin Manager for one-click updates

## Quick Start

### 1. Installation

Plugin automatically installs via FPP Plugin Manager:
1. Navigate to **Content Setup** → **Plugin Manager**
2. Search for "Advanced Stats"
3. Click **Install**

### 2. Configuration

1. Navigate to **Content Setup** → **Advanced Stats Settings**
2. Configure your preferences
3. Click **Save Settings**

### 3. Basic Usage

1. Access the dashboard at **Status/Control** → **Advanced Stats Dashboard**
2. View real-time statistics and analytics
3. Monitor system performance and activity

### 4. GPIO Setup (Optional)

GPIO integration allows physical buttons to trigger plugin functions (if implemented).

## API Endpoints

All endpoints available at: `/api/plugin/fpp-plugin-AdvancedStats/`

### Status

```bash
GET /api/plugin/fpp-plugin-AdvancedStats/status
```

Returns current plugin status, version, and configuration.

**Response:**
```json
{
  "success": true,
  "status": "active",
  "version": "Advanced Analytics Plugin",
  "isGitRepo": true,
  "pluginDir": "fpp-plugin-AdvancedStats"
}
```

### Git Commit History

```bash
GET /api/plugin/fpp-plugin-AdvancedStats/git-commits
```

Returns the last 20 git commits for the plugin (useful for changelog display).

**Response:**
```json
{
  "success": true,
  "commits": [
    {
      "hash": "abc123...",
      "author": "Developer Name",
      "date": 1762870563,
      "message": "Commit message"
    }
  ],
  "count": 20
}
```

## Support & Development

**Plugin Developer:** Stuart Ledingham of Dynamic Pixels

**Resources:**

- [GitHub Repository](https://github.com/OnlineDynamic/fpp-plugin-AdvancedStats)
- [Bug Reports & Feature Requests](https://github.com/OnlineDynamic/fpp-plugin-AdvancedStats/issues)

## License

This project is licensed under the terms specified in the LICENSE file.
