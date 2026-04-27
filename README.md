# Claude Local Shell

Local zsh helpers for switching Claude Code compatible third-party providers.

中文文档：[README.CN-ZH.md](README.CN-ZH.md)

## Features

- Load provider configs automatically from `providers/*.zsh`.
- Use the provider config file name as the provider name.
- Persist the selected provider across new shell sessions.
- Keep `ANTHROPIC_API_KEY` unset to avoid auth conflicts with `ANTHROPIC_AUTH_TOKEN`.
- Keep real tokens out of the main script.
- Work from any local clone path.

## Installation

Clone this project first:

```zsh
git clone <repo-url> claude-local-sh
cd claude-local-sh
```

Create your first provider config from an example. This flow uses DeepSeek as
the example provider:

```zsh
cp examples/deepseek.zsh providers/deepseek.zsh
vim providers/deepseek.zsh
```

Set `ANTHROPIC_AUTH_TOKEN` to your own API key:

```zsh
ANTHROPIC_AUTH_TOKEN="your-api-key"
```

Check the project path:

```zsh
pwd
```

Copy the absolute path printed by `pwd`, then source `main.sh` from `~/.zshrc`.
For example, if `pwd` prints `/Users/you/projects/claude-local-sh`, add:

```zsh
# Claude Code Environment Variables
if [[ -f "/Users/you/projects/claude-local-sh/main.sh" ]]; then
  source "/Users/you/projects/claude-local-sh/main.sh"
fi
# End Claude Code Environment Variables
```

Reload your shell:

```zsh
source ~/.zshrc
```

Then switch to DeepSeek. The provider name comes from the file name, so
`providers/deepseek.zsh` becomes `deepseek`.

```zsh
cc-list
cc-use deepseek
cc-current
```

## Custom Providers

If you use a custom provider, copy the generic template:

```zsh
cp examples/provider.example.zsh providers/my-provider.zsh
vim providers/my-provider.zsh
```

Fill in your provider base URL and API key. Put the API key in
`ANTHROPIC_AUTH_TOKEN`; this project intentionally keeps `ANTHROPIC_API_KEY`
unset to avoid Claude Code auth conflicts.

```zsh
ANTHROPIC_BASE_URL="https://your-provider.example.com/anthropic"
ANTHROPIC_AUTH_TOKEN="your-api-key"
```

After reloading your shell, switch to it with:

```zsh
cc-use my-provider
```

## Structure

```text
claude-local-sh/
  main.sh
  providers/
    my-provider.zsh
  state/
    current-provider
  examples/
    deepseek.zsh
    provider.example.zsh
```

- `main.sh`: entrypoint sourced by `~/.zshrc`.
- `providers/*.zsh`: private provider config files loaded automatically.
- `state/current-provider`: persisted selected provider.
- `examples/*.zsh`: provider examples and templates, not loaded automatically.

## Commands

```zsh
cc-list              # List available providers
cc-current           # Show current provider and exported environment
cc-use <provider>    # Switch provider permanently
cc-reload            # Reload provider config files
```

## Add A Provider

Copy the example file, edit real values, then reload. The provider name comes
from the file name, so `my-provider.zsh` becomes `my-provider`.

```zsh
cp examples/provider.example.zsh providers/my-provider.zsh
vim providers/my-provider.zsh
cc-reload
cc-use my-provider
```

If a ready-made example matches your provider, copy it directly and fill in
your own API key:

```zsh
cp examples/deepseek.zsh providers/deepseek.zsh
vim providers/deepseek.zsh
cc-reload
cc-use deepseek
```

Provider files only need environment variable assignments:

```zsh
ANTHROPIC_BASE_URL="https://example.com/anthropic"
ANTHROPIC_AUTH_TOKEN="your-token"
ANTHROPIC_MODEL="example-model"
ANTHROPIC_DEFAULT_OPUS_MODEL="example-opus-model"
ANTHROPIC_DEFAULT_SONNET_MODEL="example-sonnet-model"
ANTHROPIC_DEFAULT_HAIKU_MODEL="example-haiku-model"
CLAUDE_CODE_SUBAGENT_MODEL="example-subagent-model"
CLAUDE_CODE_EFFORT_LEVEL="max"
```

At minimum, set `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`.

## Git Safety

`providers/` and `state/` are regular project directories. This repository
keeps them with placeholder files so the runtime structure is visible.

Do not commit real provider files that contain tokens to a public repository.
Public examples under `examples/` must use placeholder tokens such as
`your-apikey`.

## License

MIT License. See [LICENSE](LICENSE).
