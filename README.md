# Skill Tree Generator

一个把庞杂 skill 聚合为分层路由树的工具，让 AI agent 按需加载子能力，避免一次性把所有指令塞进上下文。

## 支持的 Agent
- **Bitfun**（skill 目录 `.bitfun/skills/`，记忆文件 `AGENTS.md`）
- **Claude Code**（原生支持，skill 目录 `.claude/skills/`，记忆文件 `CLAUDE.md`）
- **Codex CLI**（通过 `AGENTS.md` 注入路由协议，skill 目录可自定义，推荐 `.agent/skills/`）
- 其他读取 `AGENTS.md` 的 agent（Cursor、Aider、Jules 等）同理

---

## 脚本用法

**用法 A：Bitfun**
1. 将 `skill-tree-generator/` 放到工程 `.bitfun/skills/` 下
2. 打开 Bitfun
3. 运行：
   
   ```
   ./scripts/aggregate-skills.sh .bitfun/skills --agent bitfun
   ```
4. 把输出的命令贴回 Claude Code（形如 `/skill-tree-generator --aggregate ...`）
5. 生成结果：
   - skill-tree 写入 `.bitfun/skills/{name}-tree/`
   - 项目根 `AGENTS.md` 追加路由协议（若不存在则创建）


**用法 B：Claude Code**

1. 将 `skill-tree-generator/` 放到工程 `.claude/skills/` 下
2. 打开 Claude Code
3. 运行：
   
   ```
   ./scripts/aggregate-skills.sh .claude/skills
   ```
4. 把输出的命令贴回 Claude Code（形如 `/skill-tree-generator --aggregate ...`）
5. 生成结果：
   - skill-tree 写入 `.claude/skills/{name}-tree/`
   - 项目根 `CLAUDE.md` 追加路由协议（若不存在则创建）

**用法 C：Codex CLI**

1. 将 `skill-tree-generator/` 放到工程 `.agent/skills/` 下（或自定义目录）
2. **一次性** 安装 custom prompt，让 Codex CLI 认识 `/skill-tree-generator`：
   
   ```
   ./scripts/install-codex-prompt.sh
   ```
   
   该脚本会把 `SKILL.md` 拷到 `~/.codex/prompts/skill-tree-generator.md`
3. 运行：
   
   ```
   ./scripts/aggregate-skills.sh .agent/skills --agent codex
   ```
4. 把输出的命令贴回 Codex CLI
5. 生成结果：
   - skill-tree 写入 `.agent/skills/{name}-tree/`
   - 项目根 `AGENTS.md` 追加路由协议（若不存在则创建）

> 如果你不想安装 custom prompt，也可以直接在 Codex 里让它读 `SKILL.md` 并执行聚合命令，脚本输出里会提示具体写法。

**用法 D：OpenCode**

1. 将 `skill-tree-generator/` 放到工程 `.opencode/skills/` 下（或自定义目录）
2. 运行：
   
   ```
   ./scripts/aggregate-skills.sh .opencode/skills --agent opencode
   ```
3. 按提示将输出的指令贴回 OpenCode（形如 `Read .../SKILL.md and execute: /skill-tree-generator --aggregate ...`）
4. 生成结果：
   - skill-tree 写入 `.opencode/skills/{name}-tree/`
   - 项目根 `AGENTS.md` 追加路由协议（若不存在则创建）

---

## 直接使用Skill

**1. Single Skill to Skill Tree**

/skill-tree-generator <skill-name-or-skill-path-or-description>

**2. Multiple Skill to Skill Tree**

/skill-tree-generator --aggregate skill1,skill2,... [--domain domain-name]

**3. Update Skill Tree**

/skill-tree-generator --update <tree-path> --add <skill>

## 路径约定

| Agent       | Skill 目录            | 记忆文件        |
| ----------- | ------------------- | ----------- |
| Bitfun      | `.bitfun/skills/`   | `AGENTS.md` |
| Claude Code | `.claude/skills/`   | `CLAUDE.md` |
| Codex CLI   | `.agent/skills/`    | `AGENTS.md` |
| OpenCode    | `.opencode/skills/` | `AGENTS.md` |

### 同一仓库想让两种 Agent 都用？

推荐做法（只维护一份）：

```
# skill 目录用 Codex 风格，软链让 Claude Code 也能发现
ln -s .agent/skills .claude/skills

# 记忆文件共用一份
ln -s AGENTS.md CLAUDE.md
```

---

## 引用

路由协议模板见 `skill-tree-generator/references/validation_template.md` 的 **Check 1**。

## Skill Tree推荐用法

1. 记忆文件（例如CLAUDE.md）放在根目录，查看是否包含上述“引用”中路由协议模版的内容。
2. skills目录（例如.claude/skills）下生成Skill Tree以后，将其他skill清空，可以更好的测试Skill Tree的效果。
3. 运行任务或者输入prompt，测试能否通过Skill Tree的路由功能“触发”相关的Skill。

## 路由追踪 [可选]

- 当用户 prompt 包含 **"路由调试"** / **"debug routing"** / **"路由追踪"** 时，激活路由追踪模式，该模式可输出路由追踪日志，可查看skill-tree是否实际触发到了用户需要的skill节点。
- **正常模式**（默认）：不输出任何路由信息，直接执行。