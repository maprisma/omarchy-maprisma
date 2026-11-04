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

This plugin is only the bar icon. Install the **Maprisma** app first: the AppImage from the
[GitHub release](https://github.com/maprisma/maprisma/releases), checked against its SHA-256 and placed on
your `PATH` as `maprisma`:

```sh
v=0.12.0; f=Maprisma-$v-x86_64.AppImage
cd "$(mktemp -d)"
curl -fLO "https://github.com/maprisma/maprisma/releases/download/v$v/$f"
curl -fLO "https://github.com/maprisma/maprisma/releases/download/v$v/$f.sha256"
sha256sum -c "$f.sha256"
install -Dm755 "$f" ~/.local/bin/maprisma
```

(AppImages need `fuse2`, which Omarchy ships. To remove the app: `rm ~/.local/bin/maprisma`.)

Then add the bar plugin:

```sh
omarchy plugin add https://github.com/maprisma/omarchy-maprisma
```

Remove the plugin anytime with:

```sh
omarchy plugin remove ubruckhaus.maprisma
```

(Removing the plugin leaves the `maprisma` app and your settings intact.)

---

## What the plugin does

`BarWidget.qml` runs `maprisma-toggle` when the icon is clicked. The script runs `maprisma --toggle`: the
app keeps a single window and shows it, or hides it when it is shown and focused. If the app is not
installed, the script shows a plain-text desktop notification with the install instruction above.

The plugin itself installs nothing, starts nothing when the shell starts, runs no background service, opens
no network connection and takes no input. Everything Maprisma does happens in the app, which shows a preview
before it changes any file. All settings belong to the app (`~/.config/maprisma`).

## Tests

`sh tests/test-toggle.sh` tests the toggle script with a stand-in app and notifier.

## License

MIT, see [LICENSE](LICENSE).
