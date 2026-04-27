# Claude Local Shell

用于切换 Claude Code 兼容第三方服务的本地 zsh 小工具。

English documentation: [README.md](README.md)

## 功能

- 自动加载 `providers/*.zsh` 下的服务配置。
- 直接使用配置文件名作为服务名。
- `cc-use` 切换后会持久保存，新开的终端继续生效。
- 主动清理 `ANTHROPIC_API_KEY`，只使用 `ANTHROPIC_AUTH_TOKEN`，避免认证冲突。
- 主脚本不保存真实 token，方便开源。
- 支持从任意本地 clone 路径运行。

## 工作原理

本项目只是一组 zsh 脚本。它不会修改 Claude Code，不会 patch 二进制文件，
不会安装代理，也不会主动改变网络行为。

当 shell 加载 `main.sh` 时，脚本会读取 provider 配置文件，并导出 Claude Code
使用的环境变量，包括：

```zsh
ANTHROPIC_BASE_URL
ANTHROPIC_AUTH_TOKEN
ANTHROPIC_MODEL
ANTHROPIC_DEFAULT_OPUS_MODEL
ANTHROPIC_DEFAULT_SONNET_MODEL
ANTHROPIC_DEFAULT_HAIKU_MODEL
CLAUDE_CODE_SUBAGENT_MODEL
CLAUDE_CODE_EFFORT_LEVEL
```

`cc-use <provider>` 只负责切换当前导出的 provider 配置，并把 provider 名称
保存到 `state/current-provider`，让后续新开的 shell 继续使用同一配置。

## 安装

先 clone 项目：

```zsh
git clone <repo-url> claude-local-sh
cd claude-local-sh
```

从示例文件复制一份自己的服务配置。整体流程以 deepseek 为例：

```zsh
cp examples/deepseek.zsh providers/deepseek.zsh
vim providers/deepseek.zsh
```

把 `ANTHROPIC_AUTH_TOKEN` 改成你自己的 API key：

```zsh
ANTHROPIC_AUTH_TOKEN="your-api-key"
```

查看项目本地绝对路径：

```zsh
pwd
```

复制 `pwd` 输出的绝对路径，然后在 `~/.zshrc` 中引用这个路径下的
`main.sh`。例如 `pwd` 输出 `/Users/you/projects/claude-local-sh`，则添加：

```zsh
# Claude Code Environment Variables
if [[ -f "/Users/you/projects/claude-local-sh/main.sh" ]]; then
  source "/Users/you/projects/claude-local-sh/main.sh"
fi
# End Claude Code Environment Variables
```

重新加载 shell：

```zsh
source ~/.zshrc
```

然后切换到 deepseek。服务名来自文件名，所以
`providers/deepseek.zsh` 对应 `deepseek`。

```zsh
cc-list
cc-use deepseek
cc-current
```

## 自定义服务

如果是自定义服务，则复制通用模板：

```zsh
cp examples/provider.example.zsh providers/my-provider.zsh
vim providers/my-provider.zsh
```

填写你的服务 base URL 和 API key。API key 写到
`ANTHROPIC_AUTH_TOKEN`；本项目会刻意保持 `ANTHROPIC_API_KEY` 未设置，
避免 Claude Code 出现认证冲突。

```zsh
ANTHROPIC_BASE_URL="https://your-provider.example.com/anthropic"
ANTHROPIC_AUTH_TOKEN="your-api-key"
```

重新加载 shell 后，通过文件名对应的服务名切换：

```zsh
cc-use my-provider
```

## 目录结构

```text
claude-local-sh/
  main.sh                         # 主入口，由 ~/.zshrc source
  providers/
    my-provider.zsh               # 私有服务配置，自动加载
  state/
    current-provider              # 当前选中的服务
  examples/
    deepseek.zsh                  # 可直接复制后补 API key 的服务示例
    provider.example.zsh          # 示例配置，不会自动加载
```

- `main.sh`：由 `~/.zshrc` 引用的主入口。
- `providers/*.zsh`：私有服务配置文件，会被自动加载。
- `state/current-provider`：持久保存当前选中的服务。
- `examples/*.zsh`：服务示例和模板，不会自动加载。

## 常用命令

```zsh
cc-list              # 查看可用服务
cc-current           # 查看当前服务和已导出的环境变量
cc-use <provider>    # 永久切换服务
cc-reload            # 重新加载服务配置
```

## 新增服务

复制示例文件，文件名就是服务名。例如 `my-provider.zsh` 对应
`cc-use my-provider`。

```zsh
cp examples/provider.example.zsh providers/my-provider.zsh
vim providers/my-provider.zsh
cc-reload
cc-use my-provider
```

如果已有示例正好对应你的服务，可以直接复制并补充自己的 API key：

```zsh
cp examples/deepseek.zsh providers/deepseek.zsh
vim providers/deepseek.zsh
cc-reload
cc-use deepseek
```

服务配置文件只需要写变量赋值：

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

至少需要填写 `ANTHROPIC_BASE_URL` 和 `ANTHROPIC_AUTH_TOKEN`。

## 卸载

从 `~/.zshrc` 中删除 Claude Local Shell 配置块：

```zsh
# Claude Code Environment Variables
if [[ -f "/Users/you/projects/claude-local-sh/main.sh" ]]; then
  source "/Users/you/projects/claude-local-sh/main.sh"
fi
# End Claude Code Environment Variables
```

然后重新加载 shell：

```zsh
source ~/.zshrc
```

如果不再需要本地项目目录，也可以删除：

```zsh
rm -rf /Users/you/projects/claude-local-sh
```

## 开源注意事项

`providers/` 和 `state/` 是普通项目目录。仓库里通过占位文件保留这两个
目录，让运行时结构保持可见。

不要把包含真实 token 的 provider 配置提交到公开仓库。`examples/` 下的
公开示例必须使用 `your-apikey` 这类占位 token。

## 开源协议

MIT License。详见 [LICENSE](LICENSE)。
