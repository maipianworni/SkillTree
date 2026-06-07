# ROOT.md Template

This template defines the root-level routing protocol for a skill-tree.

---

## Template

```markdown
# {Skill Name} Routing Protocol [MANDATORY]
在处理任何用户任务之前，必须执行以下路由流程：

## Step 1: L1 路由
基于用户的 **完整对话历史 + 当前prompt**，判断任务类别。

| 任务类别 | 路由目标 |
|---------|---------|
| {category1} | Read `{skills-dir}/{skill-tree}/{module1}/ROUTER.md` |
| {category2} | Read `{skills-dir}/{skill-tree}/{module2}/ROUTER.md` |
| {category3} | Read `{skills-dir}/{skill-tree}/{module3}/SKILL.md` |
| 其他/未明确 | Read `{skills-dir}/{skill-tree}/{default}/ROUTER.md` |

## Step 2: 递归路由
按照读到的 ROUTER.md 中的指令继续判断，直到遇到包含
`[LEAF NODE]` 标记的文件，即为最终 skill。

## Step 3: 执行
完整读取叶节点 SKILL.md，按其规范执行任务，并打印该目录下skill已经加载的日志。

## 路由追踪 [可选]

当用户 prompt 包含 **"路由调试"** / **"debug routing"** / **"路由追踪"** 时，激活路由追踪模式：

1. 在 Step 1 决策后输出：`[Route] ROOT → <module> (<匹配信号>)`
2. 每个 ROUTER.md 决策后追加：`[Route]   → <capability> [LEAF]`
3. 到达叶节点后开始执行，不再输出路由信息

**正常模式**（默认）：不输出任何路由信息，直接执行。

## 重要约束
- 路由判断必须考虑对话中已建立的所有上下文约束
- 如果任务跨越多个类别，并行读取多个叶节点
- 当用户明确指定模块时，直接路由到对应子树
```

---

## Placeholders

| Placeholder | Description | Example |
|-------------|-------------|---------|
| `{Skill Name}` | Name of the skill-tree | `Web Development` |
| `{skills-dir}` | Agent-specific skills directory | `.claude/skills` (Claude Code) / `.agent/skills` (Codex CLI) |
| `{categoryN}` | L1 category matching criteria | `前端/UI相关` |
| `{skill-tree}` | Directory name of the skill-tree | `web-dev-tree` |
| `{moduleN}` | Module directory name | `frontend` |
| `{default}` | Default fallback module | `general` |

---

## Multi-Skill ROOT.md

用于包含多个 skill 的跨领域路由树（Phase 1 选一个或多个 Skill, Phase 2 选能力）。

```markdown
# {Domain} Routing Protocol [MANDATORY]
在处理任何用户任务之前，必须执行以下路由流程：

## Phase 1: 选一个或多个 Skill
基于用户的 **完整对话历史 + 当前 prompt**，判断需要使用哪个或哪些 Skill。一个 prompt 可以包含多个独立意图；当多个意图分别命中不同 skill 或 capability 时，必须保留所有命中的路由路径，不要只选择单一路径。

| 用户意图 | 关键词信号 | 路由目标 |
|---------|-----------|---------|
| {Skill_A 能力描述} | {Skill_A 特有词}, {Skill名A} | Read `./{skill_a}/ROUTER.md` |
| {Skill_B 能力描述} | {Skill_B 特有词}, {Skill名B} | Read `./{skill_b}/ROUTER.md` |
| 共享功能 | {shared signals} | Read `./shared/{capability}/SKILL.md` |
| 多意图 / 多 Skill 组合 | 同时出现多个 skill 名称、多个唯一领域词、或多个可分解子任务 | Read all matched `./{skill}/ROUTER.md` paths, or Read `./cross-cutting/SKILL.md` when execution requires workflow coordination |
| 跨 Skill 工作流 | workflow, pipeline, 批量, 串联, 组合 | Read `./cross-cutting/SKILL.md` |
| 其他/未明确 | — | 列出所有 Skill 让用户选择 |

## Phase 2: 选能力
按照每个已命中 Skill 子树的 ROUTER.md 继续路由，直到找到包含 `[LEAF NODE]` 标记的文件。若 Phase 1 命中多个 Skill，则分别进入每个 Skill 的 ROUTER.md；若同一 Skill 内命中多个能力，也必须保留多个 leaf 路径。

### 多意图路由规则

- **多命中优先保留**：当 prompt 中存在多个可独立执行的意图时，分别提取子任务并保留所有匹配的 Skill/leaf 路径。
- **并行 vs 串行**：子任务之间无数据依赖时，可并行读取并执行多个 leaf；存在输入输出依赖或明确顺序时，路由到 `./cross-cutting/SKILL.md` 编排执行。
- **共享能力 + 专属能力并存**：共享关键词命中 shared leaf，同时存在明确 Skill 名称或唯一领域词时，shared 路径和专属 Skill 路径都应保留。
- **不要用优先级丢弃其他明确意图**：信号优先级只用于消歧单个子任务，不用于覆盖或删除其他已明确命中的子任务。

## 消歧规则
- 提到 **{Skill名A}** 或 **{Skill_A 唯一领域词}** → `{skill_a}/`
- 提到 **{Skill名B}** 或 **{Skill_B 唯一领域词}** → `{skill_b}/`
- 仅提到 **"{共享关键词}"** 无上下文 → 询问用户选择
- 对话中已建立 Skill 上下文 → 不再重新选 Skill，直接进入其子树

### 信号优先级

当用户 prompt 中同时包含多个信号时，按以下优先级处理：

| 优先级 | 信号类型 | 路由行为 | 示例 |
|--------|---------|---------|------|
| **P1 最高** | Skill 名称 | 直接路由，不询问 | "用 React 开发" → react |
| **P2** | 唯一领域词 | 直接路由，不询问 | "undo/撤销" → 唯一确定某 skill |
| **P3 最低** | 跨领域通用词 | 仅在无 P1/P2 时才询问 | 仅"新建"无上下文 → 询问 |

**优先级规则**: P1 > P2 > P3。当 P2 和 P3 同时出现在同一个子任务中时，P2 覆盖 P3，不询问。若 prompt 包含多个子任务，先拆分子任务，再在每个子任务内部应用优先级；不得因为某个子任务有 P1/P2 信号而丢弃其他子任务的路由命中。

## 路由追踪 [可选]

当用户 prompt 包含 **"路由调试"** / **"debug routing"** / **"路由追踪"** 时，激活路由追踪模式：

1. 在 Phase 1 决策后输出：`[Route] ROOT → <skill-name> (P<level>: <匹配信号>)`
2. 每个 ROUTER.md 决策后追加：`[Route]   → <capability-name> [LEAF]`
3. 跨 Skill 时每个 Skill 输出一行
4. 到达叶节点后开始执行，不再输出路由信息

**正常模式**（默认）：不输出任何路由信息，直接执行。

## 重要约束
- **必须**先路由再执行，不要跳过路由直接猜测 Skill
- **多意图保留**：当前 prompt 明确包含多个意图时，必须拆分子任务并保留所有命中的 Skill/leaf 路径
- **上下文优先但不吞并多意图**：对话中已明确提到某个 Skill 名称时，直接路由到对应子树；若当前 prompt 又明确提到其他 Skill/能力，也必须同时保留新增命中路径
- **上下文累积**：路由判断必须考虑对话中已建立的所有上下文约束
```

---

## 常见共享关键词检查清单

生成后逐一检查以下高频共享词，确保每条都有消歧规则：
- `create` / `新建` — 可能为多个 skill 都有创建功能
- `export` / `导出` — 可能为多个 skill 都有导出功能
- `list` / `info` — 几乎每个 skill 都有查询能力
- `config` / `配置` — 可能涉及不同 skill 的不同配置
- `test` / `测试` — 前端测试 vs 后端测试 vs 集成测试
