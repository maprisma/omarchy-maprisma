# Maprisma for Omarchy

A bar icon for **Maprisma**: your AI agents, local LLMs, models, MCP servers and skills on one map.

---

## What Maprisma does

- **One map of your AI setup.** Coding agents (Claude Code, Codex, Copilot, Cursor CLI, Gemini, OpenCode,
  Pi, Hermes, …), local LLMs (llama.cpp, Ollama, LM Studio, vLLM, Jan, KoboldCpp) with their models, and
  MCP servers and skills, as cards and lines.
- **Connect by drawing.** Draw a line from an agent to a model, an MCP server or a skill folder. Every change
  is shown as a preview first, written with a backup, and can be undone.
- **Agents at a glance.** Each agent's plan, limits and usage, what it still needs (with the command that
  fixes it), and a Security check of what it may do without asking you, each choice explained with its risk.
- **Local LLMs that fit your card.** Install llama.cpp, Ollama and others with every download checked
  against its release's SHA-256, download models, and let Maprisma measure each llama.cpp model on your
  graphics card for its best context and batch size.
- **MCP servers and skills** found on your computer or on the web, with who published each server and how
  it runs.
- **Ask AI** from the header: an agent or a local LLM proposes changes from a fixed list of actions;
  nothing runs without your click.
- **Omarchy look:** follows your Omarchy theme and window corners, 8 interface languages, `F12` window
  screenshots with a note.

---

## Install

Add the plugin first, then click its bar icon:

```sh
omarchy plugin add https://github.com/maprisma/omarchy-maprisma
```

If the app is missing, the bar icon opens an **Install Maprisma?** panel. Choose
**Install AppImage** to watch the download, with a progress bar, in a terminal. The installer compares
the AppImage with the release's SHA-256 file before it puts `maprisma` in `~/.local/bin/`, then opens the
app. Later clicks show or hide its window. **Not now** leaves your PC unchanged. Ctrl+C or closing the
terminal cancels the download; once installation has finished, the app remains available from the bar icon.
No administrator password is needed.

The checksum catches a broken or incomplete download; it comes from the same GitHub release as the
AppImage, so it is not a signature.

This setup needs the Omarchy-provided `xdg-terminal-exec`, plus `curl`, `jq`, `sha256sum` and
util-linux (`flock`, `setsid`). If `fuse2` is absent, the AppImage uses its extract-and-run mode. If the
latest release or its checksum is unavailable, the terminal explains that nothing was installed and shows
the [release page](https://github.com/maprisma/maprisma/releases). Only one install runs at a time.
To remove the app later: `rm ~/.local/bin/maprisma`.

Without a terminal launcher, the bar icon says so in a notification. Install by hand instead:

```sh
v=0.12.0; f=Maprisma-$v-x86_64.AppImage
cd "$(mktemp -d)"
curl -fLO "https://github.com/maprisma/maprisma/releases/download/v$v/$f"
curl -fLO "https://github.com/maprisma/maprisma/releases/download/v$v/$f.sha256"
sha256sum -c "$f.sha256"
install -Dm755 "$f" ~/.local/bin/maprisma
```

Remove the plugin anytime with:

```sh
omarchy plugin remove ubruckhaus.maprisma
```

(Removing the plugin leaves the `maprisma` app and your settings intact.)

---

## What the plugin does

`BarWidget.qml` runs `maprisma-toggle` when the icon is clicked. The script runs `maprisma --toggle` when
the app is present. When it is missing, the bar widget opens its install panel. After consent, `install-appimage`
runs in a visible terminal, fetches only the latest release from Maprisma's GitHub repository, checks
the matching SHA-256, installs for this user and opens Maprisma in a session of its own (`setsid`), so
closing the terminal leaves it running. The installer refuses an unexpected asset name, download host,
missing or mismatched checksum, an existing target file and a second install while one runs.

The plugin starts nothing when the shell starts and runs no background service. Its `installer`
capability is used only after the user's click and confirmation; it downloads the AppImage and checksum
from GitHub, writes the checked app in `~/.local/bin/`, and launches it. Maprisma's own settings belong
to the app (`~/.config/maprisma`).

## Tests

`sh tests/test-toggle.sh` tests installed and first-install flows, release and checksum failures, a second
install while one runs and a missing terminal launcher, using stand-in commands.

## License

MIT, see [LICENSE](LICENSE).
