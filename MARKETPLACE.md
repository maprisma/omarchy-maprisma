# Marketplace listing text

**Maprisma** puts your AI agents, local LLMs, models, MCP servers and skills on one map. Draw a line to
connect an agent to a provider, a model, an MCP server or a skill folder: a small dialog asks first, a note
confirms it with Undo, and a line that cannot work says why. Ask AI shows example questions and can make
the same changes for you, through the same preview.

**Easy start, even if you are new to AI tools:** add the plugin and click its robot icon in the bar. If the
app isn't on your PC yet, a panel asks **Install Maprisma?**. Choose **Install AppImage** and a terminal
downloads Maprisma 0.14.7 from GitHub with a progress bar, checks it against the SHA-256 pinned in this
plugin, installs it for your user (`~/.local/bin/maprisma`, no administrator password) and opens it.
**Not now** changes nothing. Later clicks show or hide Maprisma.

The plugin itself is a small launcher; Maprisma is the separate AppImage from
[maprisma/maprisma](https://github.com/maprisma/maprisma/releases).

Capability: `installer`. Only after the panel's explicit confirmation, `install-appimage` downloads one
pinned build — the version and its SHA-256 are written in the plugin (`version=0.14.7`, `sha256=…`), nothing
is looked up — from its exact GitHub release address, installs it only when the SHA-256 matches, writes
`~/.local/bin/maprisma` and opens it in its own session (`setsid`). One install runs at a time (`flock`).
No package manager, administrator privilege, shell service or background download is used. The user can
cancel before or during the download; once installation finishes, the app stays available from the bar
icon.
