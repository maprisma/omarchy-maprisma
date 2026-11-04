# Marketplace description draft

Maprisma puts AI agents, local LLMs, models, MCP servers and skills on one map. Install the Omarchy plugin, click its bar icon, and choose **Install AppImage** if the app is not yet present. A terminal shows the download with a progress bar and compares it with the release's SHA-256 file before the app is installed for your user account and opened. Later clicks show or hide Maprisma.

On the map, draw connections with a preview and Undo, inspect agent limits and usage, and get help with local model performance. The plugin itself is a small launcher; Maprisma is the separate AppImage.

Capability for the later marketplace submission: `installer` — after an explicit panel confirmation, `install-appimage` downloads the latest Maprisma AppImage and its checksum from the Maprisma GitHub release, compares them, writes `~/.local/bin/maprisma`, and opens it in its own session (`setsid`). One install runs at a time (`flock`). No package manager, administrator privilege, shell service or background download is used. The user can cancel before or during the download. Once installation finishes, the app remains available from the bar icon.

This is draft listing text. No marketplace submission is part of this change.
