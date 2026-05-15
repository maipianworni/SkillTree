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

## Multi-Skill ROOT.md（Domain-First）

用于包含多个 skill 的路由树。采用 **domain-first** 组织：Phase 1 选能力域，Phase 2 在该域内选 skill。

```markdown
# {Domain} Routing Protocol [MANDATORY]
在处理任何用户任务之前，必须执行以下路由流程：

## Phase 1: 选能力域
基于用户的 **完整对话历史 + 当前 prompt**，判断用户意图属于哪个能力域。

| 用户意图 | 关键词信号 | 路由目标 |
|---------|-----------|---------|
| {Domain_A 描述} | {Domain_A 关键词} | Read `./{domain_a}/ROUTER.md` |
| {Domain_B 描述} | {Domain_B 关键词} | Read `./{domain_b}/ROUTER.md` |
| {Domain_C 描述} | {Domain_C 关键词} | Read `./{domain_c}/{skill_x}/SKILL.md` |
| 共享功能 | {shared signals} | Read `./shared/{capability}/SKILL.md` |
| 跨 Skill 工作流 | workflow, pipeline, 批量 | Read `./cross-cutting/SKILL.md` |
| 其他/未明确 | — | 列出所有能力域让用户选择 |

> **注意**: 单 skill 的能力域（Unique）直接路由到叶节点 `./{domain}/{skill}/SKILL.md`，无需经过 ROUTER.md。

## Phase 2: 选 Skill
按照能力域的 ROUTER.md 继续路由到具体 skill 的 SKILL.md，直到找到包含 `[LEAF NODE]` 标记的文件。

## Skill 快速索引
当用户仅提及 skill 名称（P1）而未指定能力域时，使用此表确定涉及的能力域。

| Skill | 涉及能力域 |
|-------|-----------|
| {Skill_A} | {domain_a}, {domain_b}, {domain_c} |
| {Skill_B} | {domain_a}, {domain_d} |
| {Skill_C} | {domain_b}, {domain_c}, {domain_d} |

**Skill 名称路由规则（P1 无 P2 时）**:
- 若 skill 仅涉及 1 个能力域 → 直接路由到该域
- 若 skill 涉及多个能力域 → 列出该 skill 的能力域让用户选择

## 消歧规则
- 提到 **{Domain_A 唯一词}** 或 **{能力域特有术语}** → `{domain_a}/ROUTER.md`
- 提到 **{Domain_B 唯一词}** → `{domain_b}/ROUTER.md`
- 提到 **{Skill名A}** + 能力域关键词 → 路由到对应能力域，在 ROUTER.md 中选择 {Skill_A}
- 仅提到 **"{共享关键词}"** 无能力域上下文 → 询问用户选择能力域
- 对话中已建立 Skill 上下文 → 在各能力域的 ROUTER.md 中优先路由到该 skill

### 信号优先级 [L8 预防]

当用户 prompt 中同时包含多个信号时，按以下优先级处理：

| 优先级 | 信号类型 | 路由行为 | 示例 |
|--------|---------|---------|------|
| **P1 最高** | Skill 名称 | 查 Skill 快速索引确定能力域范围 | "用 React" → 列出 React 涉及的能力域 |
| **P2** | 唯一领域词（能力域） | 直接路由到对应能力域 | "状态管理" → state-management/ROUTER.md |
| **P3 最低** | 跨领域通用词 | 仅在无 P1/P2 时才询问 | 仅"新建"无上下文 → 询问 |

**优先级规则**: P1 > P2 > P3。当 P1 和 P2 同时出现时（如 "用 React 做状态管理"），P2 确定能力域，P1 在域内确定 skill，直接路由不询问。

## 路由追踪 [可选]

当用户 prompt 包含 **"路由调试"** / **"debug routing"** / **"路由追踪"** 时，激活路由追踪模式：

1. 在 Phase 1 决策后输出：`[Route] ROOT → {domain} (P2: {匹配信号})`
2. 单 skill 域直接到叶节点：`[Route]   → {skill}/SKILL.md [LEAF]`
3. 多 skill 域经 ROUTER.md：`[Route]   → {skill}/SKILL.md [LEAF]`
4. 跨 Skill 时每个 Skill 输出一行
5. 到达叶节点后开始执行，不再输出路由信息
6. P1 无 P2 时：`[Route] ROOT → 列出 {skill} 的能力域 (P1: {skill名})`

**正常模式**（默认）：不输出任何路由信息，直接执行。

## 重要约束
- **必须**先路由再执行，不要跳过路由直接猜测 Skill
- **上下文优先**：对话中已明确提到某个 Skill 名称时，在各域 ROUTER.md 中优先路由到该 skill
- **上下文累积**：路由判断必须考虑对话中已建立的所有上下文约束
- **P1+P2 直接路由**：当用户同时指定 skill 和能力域时（如"用 X 做 Y"），直接路由到 `{domain}/{skill}/SKILL.md`
```

---

## 常见共享关键词检查清单

生成后逐一检查以下高频共享词，确保每条都有消歧规则：
- `create` / `新建` — 可能为多个 skill 都有创建功能
- `export` / `导出` — 可能为多个 skill 都有导出功能
- `list` / `info` — 几乎每个 skill 都有查询能力
- `config` / `配置` — 可能涉及不同 skill 的不同配置
- `test` / `测试` — 前端测试 vs 后端测试 vs 集成测试
