# Validation Template

生成完成后必须逐项执行以下检查。**不可跳过任何一项。**

## Validation Checklist

### Check 1: Agent 记忆文件存在性

确认项目根目录有对应 agent 的记忆文件，且包含 skill-tree 路由协议。

**重要权限规则**：如果当前 skill-tree 生成/验证是在子 agent、隔离环境、受限 worktree 或任何无法修改项目根记忆文件的执行环境中运行，**不要尝试绕过权限修改记忆文件**。此时 Check 1 改为：
1. 检查目标记忆文件当前状态；
2. 如果缺少路由协议，在验证报告中输出“主 agent 需要追加的精确内容”和目标文件路径；
3. 将 Check 1 标记为 `PENDING_PARENT_APPLY`，而不是验证失败；
4. 由主 agent / 调用方在有权限的环境中追加内容后，重新执行 Check 1 确认通过。

换言之：**子 agent 负责生成和报告，主 agent 负责安装到记忆文件**。

**目标文件**（按当前 agent 选择）：

| Agent       | 记忆文件     | Skill 目录                              |
|-------------|-------------|-----------------------------------------|
| Bitfun      | `AGENTS.md` | `.bitfun/skills/`                       |
| Claude Code | `CLAUDE.md` | `.claude/skills/`                       |
| Codex CLI   | `AGENTS.md` | `.agent/skills/`（或用户自定义目录）      |
| Hermes      | `AGENTS.md` | `.hermes/skills/`                       |
| OpenClaw    | `AGENTS.md` | `.openclaw/skills/`                     |
| OpenCode    | `AGENTS.md` | `.opencode/skills/`                     |
| ZCode       | `AGENTS.md`  | `.zcode/skills/`                       |
| 其他支持 AGENTS.md 的 agent（Cursor / Aider / Jules 等） | `AGENTS.md` | 同上 |

操作：检查目标记忆文件是否已包含 `# CRITICAL — DO NOT SKIP` 和 `## Routing Protocol` 路由协议内容。
如果不存在，追加以下内容（注意把 `{SKILLS_DIR}` 替换为实际 Skill 目录）：

```markdown
# CRITICAL — DO NOT SKIP
You MUST follow this routing protocol BEFORE responding to any user request, no exceptions. This includes the very first message in a conversation.
Failure to read ROOT.md first is a critical error. Do not proceed with any task, tool call, or response until routing is complete.

## Routing Protocol
1. Glob `{SKILLS_DIR}/*-tree/ROOT.md` to discover all skill trees. If glob fails, list `{SKILLS_DIR}` and check each `*-tree` subdirectory for `ROOT.md`.
2. Read every ROOT.md file found
3. Follow the routing logic in ROOT.md to select the correct skill
4. Only after routing is complete, proceed with the user's task

This applies to ALL tasks: research, code, editing, questions — everything.
```

**通过标准**：目标记忆文件已存在且包含 `# CRITICAL — DO NOT SKIP` 路由协议，或已成功追加。

**受限环境通过标准**：如果当前执行环境无权修改目标记忆文件，验证报告必须包含：
- 目标文件路径；
- 缺失原因；
- 需要追加的完整 markdown 内容；
- 状态 `PENDING_PARENT_APPLY`。

该状态表示生成物本身可继续验证，但最终交付前必须由主 agent 应用并复查。

**同仓库同时服务多种 agent 的推荐做法**：
- skill 统一放到 `.agent/skills/`
- 用软链让 Claude Code 也能发现：`ln -s .agent/skills .claude/skills`
- 用软链共用同一份协议：`ln -s AGENTS.md CLAUDE.md`

---

### Check 2: Coverage (能力覆盖率)

- 统计源 skill 中的每个能力
- 确认每个能力恰好出现在一个叶节点中
- 确认 SKILL-TREE.md 映射表中的总数与实际一致

**操作步骤**:
1. 列出源 skill 的所有功能点
2. 逐个检查是否在每个叶节点中出现
3. 核对 SKILL-TREE.md 中的统计数字

**通过标准**: 每个源能力恰好对应一个叶节点，映射表计数准确。

---

### Check 3: Reachability (可达性)

- 从 ROOT.md 出发追踪每条路由到叶节点
- 确认所有叶文件均可达
- 标记任何孤儿文件

**操作步骤**:
1. 列出 ROOT.md 中所有路由目标
2. 对每个 ROUTER.md，列出所有下一跳
3. 列出所有实际存在的 .md 文件
4. 确认每个文件都被某条路由覆盖

**通过标准**: 所有文件均可从 ROOT.md 通过路由到达，无孤儿文件。

---

### Check 4: Disambiguation (消歧完整性)

- 识别出现在多个兄弟节点中的关键词
- 对于 Multi-Skill 树：确认 ROOT.md 对每个共享关键词有消歧规则

**操作步骤**:
1. 收集所有叶节点的触发关键词
2. 找出在 2+ 个节点中出现的词
3. 检查 ROOT.md 的消歧规则是否覆盖每个共享词

**通过标准**: 每个共享关键词在消歧规则中有明确处理。

---

### Check 5: Depth (深度)

- 从 ROOT.md 到任何叶节点的路径不得超过 4 级

**操作步骤**:
1. 对每个叶节点，计算 ROOT → ... → LEAF 的层级数
2. 确认最大深度 ≤ 4

**通过标准**: 所有叶节点深度 ≤ 4。

---

### Check 6: Keyword Quality (关键词质量)

- 每个叶节点必须有清晰、互斥的触发条件
- 适用时包含双语关键词

**操作步骤**:
1. 检查每个叶节点是否有中英文关键词
2. 检查同层节点的触发条件是否互斥
3. 确认有"其他/默认"兜底路由

**通过标准**: 每个叶节点有明确触发条件，同层条件互斥，有兜底路由。

---

### Check 7: Cross-reference Integrity (交叉引用完整性)

- 每个 "Related Skills" 路径必须解析到实际存在的文件
- 兄弟引用使用 `../{sibling}/SKILL.md`，而非 `./{sibling}/SKILL.md`

**操作步骤**:
1. 收集所有叶节点的 `Related Skills` 部分
2. 逐个验证路径是否指向真实存在的文件
3. 检查相对路径格式

**通过标准**: 所有 Related Skills 引用均有效且路径格式正确。

---

### Check 8: Functional Routing Tests (功能路由测试)

构造 ≥ 5 个测试用例（3 简单 + 2 复杂），模拟用户 prompt：

| # | 类型 | 要求 |
|---|------|------|
| 1 | 简单 | 使用唯一关键词，直接路由到单个叶节点 |
| 2 | 简单 | 使用另一个领域的关键词 |
| 3 | 简单 | 使用第三个领域的关键词 |
| 4 | 复杂 | 使用领域专用术语，验证路由精度 |
| 5 | 复杂 | 包含冲突信号，验证信号优先级 |

**操作步骤**:
对每个测试用例，手动追踪 ROOT → ROUTER → LEAF 的路径。

**通过标准**: 所有测试用例都能正确路由到预期叶节点。

---

### Check 8A: Semantic Signal Coverage (语义信号覆盖)

- ROOT.md 和每个 ROUTER.md 的非 fallback 路由必须包含用户自然会说的信号，而不只是技术术语、产品/API 名称、目录名或 skill 名称。
- 关键词/信号列必须被表述为代表性示例或语义召回种子，而不是穷举匹配清单。
- 隐含能力路由必须有来源依据：源 skill 描述、工作流示例、用户目标、对话上下文或领域高频用法。

**操作步骤**:
1. 读取 ROOT.md，检查 Step 1 / Phase 1 是否包含“语义理解/语义匹配/代表性关键词信号”之类的明确指令。
2. 对 ROOT.md 每条非 fallback 路由，标注至少一个用户会说的自然语言信号。
3. 对每个 ROUTER.md 的非 fallback 路由重复第 2 步。
4. 找出只有技术词、产品名、API 名、目录名或 skill 名的路由行，并补充用户视角信号。
5. 对任何多读/隐含能力路由，记录其依据；若依据不足，改为更窄的单路由或询问用户。

**通过标准**: ROOT.md 声明语义匹配；每条非 fallback 路由至少包含一个用户视角信号；所有隐含能力多路由都有可审计依据。

---

### Check 8B: Meta-query vs Execution Disambiguation (元查询/执行消歧)

仅当 tree 中包含 skill discovery / find-skills / install-skill 类能力时执行本检查；否则记录为 `NOT_APPLICABLE`。

**操作步骤**:
1. 确认 ROOT.md 存在 Skill 查找/发现/安装类意图行。
2. 确认该意图行或消歧规则明确区分：
   - “找/推荐/安装一个能做 XX 的技能” → discovery skill，`XX` 是查询参数。
   - “现在帮我处理/转换/执行这个具体文件、对象或任务” → 对应执行 skill。
   - 同时包含找技能和具体执行对象 → 保留 discovery + execution 多路由。
3. 构造至少 3 个测试 prompt：纯找技能、纯执行、找技能+具体执行对象，并手动追踪预期路径。

**通过标准**: 纯元查询不会被能力词误路由到执行 skill；包含具体执行对象和执行动词时能保留并行执行路径。

---

### Check 9: Content Preservation (内容保留)

- 确认源 skill 中的所有内容在叶节点中都有保留
- 源 skill 中的指令在拆分过程中没有丢失
- 为每个叶节点记录可审计的内容保留证据，避免仅凭印象判断

**操作步骤**:
1. 读取每个源 skill 的完整内容，并记录总行数、YAML frontmatter 行数、正文行数
2. 为每个叶节点标注类型：
   - `independent`：1 个源 skill → 1 个叶节点
   - `split`：1 个源 skill → 多个子叶节点
3. 对 `independent` 叶节点：
   - 重新读取源 skill 后再读取目标叶节点
   - 除 YAML frontmatter 外，源 skill 正文必须完整出现在目标叶节点中
   - 比较源正文行数与目标叶节点行数；若因 `[LEAF NODE]` 标题、tree 内部路径替换、引用文件拷贝等自包含处理导致行数不同，逐项记录差异原因
   - 任意未解释的内容缺失均为失败
4. 对 `split` 叶节点：
   - 先建立 source section → leaf mapping table，列出源 skill 每个章节分配到哪个叶节点
   - 确认每个源章节都映射到至少一个叶节点
   - 确认每个叶节点包含映射给它的章节/能力的完整内容，不得概括或只保留框架
   - 若某叶节点正文行数比映射到它的源段落短 >30%，逐段排查；除非有明确、可审计的非内容损失原因，否则标记失败
5. 特别注意数值、阈值、具体实现细节、代码块、表格、检查清单、格式化规则
6. 将 per-leaf content preservation table 写入 `GENERATION-REPORT.md`：

```markdown
| Leaf | Source skill | Type | Source body lines / mapped lines | Target lines | Difference explanation | Status |
|------|--------------|------|----------------------------------|--------------|------------------------|--------|
```

**通过标准**: 源 skill 的所有执行级指令和章节内容完整迁移到叶节点；每个叶节点都有行数/映射证据；任何行数差异都有明确解释且不代表内容丢失。

---

### Check 10: Source Content Capture (源内容采集与迁移)

- 确认生成 tree 时使用的每个源 skill 在**生成时**已读取且内容非空
- 确认源 skill 的执行级内容已经迁移到 tree 内，而不是让 tree 在**运行时**依赖源 skill 路径
- 防止把"源文件存在"误当成"tree 可独立执行"的通过证据

**操作步骤**:
1. 在 `GENERATION-REPORT.md` 中列出每个叶节点对应的源 skill 路径、读取时间/生成轮次、源正文行数、目标叶节点行数
2. 对每个叶节点，确认源正文（除 YAML frontmatter 外）已按 Check 9 完整迁移：独立叶节点逐字保留，拆分叶节点按 section mapping 完整覆盖
3. 确认叶节点中不包含要求 agent 再去读取源 skill 的运行时步骤，例如 `读取 ~/.openclaw/workspace/skills/.../SKILL.md 获取完整指令`
4. 允许 `GENERATION-REPORT.md` 保留源路径作为审计记录；不允许叶节点用源路径作为执行依赖
5. 生成后模拟删除或不可访问源 skill：只读取 tree 内文件，确认仍能执行每个叶节点的核心工作流

**通过标准**: 所有源 skill 在生成时已成功读取且内容非空；所有执行级内容已保存在 tree 内；删除源 skill 后 tree 不失效。

---

### Check 11: No Stub Files (禁止存根)

- 检查每个叶节点是否包含指向外部文件的存根模式
- agent 仅加载 tree 就必须能执行任务

**操作步骤**:
1. 读取每个叶节点的 SKILL.md
2. 检查以下存根模式，**任意一条命中则标记为失败**:
   - `Read and execute the skill at` + 文件路径
   - `**Full Instructions**: Read` + 文件路径
   - `See {file_path}` 或 `See {url}` 作为唯一内容
   - `Refer to {file_path}` 或 `For details, see {path}`
   - 只包含标题+一行摘要+外部链接，无实质可执行内容
3. 对命中存根的叶节点：必须将目标文件内容内联进来
4. 如果目标文件不存在：**标记为验证失败**，需要手动补充内容
5. 检查是否存在指向 tree 外部的路径引用（如 `.claude/skills/<source-skill>/`、`.agent/skills/<source-skill>/`、`.openclaw/skills/<source-skill>/`、`~/.openclaw/workspace/skills/<source-skill>/`、`~/core_skills/<source-skill>/`、绝对路径指向源技能目录）→ Grep pattern: `(\.claude|\.agent|\.openclaw)/skills/(?!.*-tree/)|~/.openclaw/workspace/skills/|~/core_skills/|~/openclaw/node_modules/openclaw/skills/` 或类似的 tree 外部路径模式
6. 检查是否存在未清理的"参考文档索引"/"Reference"/"References"段落，其中的文件路径指向 tree 外部或不存在的位置
7. 对被引用的大文件目录（如 `docs/`），确认已拷贝到 tree 内且路径已替换为 tree 内部相对路径（如 `../docs/`）

**通过标准**: 所有叶节点自包含完整内容，无任何存根模式。

---

### Check 12: Reference File Handling (引用文件处理)

确认所有源技能的外部引用已正确处理：

**操作步骤**:
1. 列出源技能中所有被引用的外部文件/目录
2. 对每个引用，确认其处理方式正确：
   - 短文件 → 已内联到叶节点中
   - 大量文件/长内容 → 已拷贝到 tree 内，叶节点中路径已替换
   - 不存在 → 已删除引用，替换为自包含指令
3. 确认所有叶节点中无指向源技能目录的残留路径

**通过标准**: 所有外部引用已正确处理，tree 完全自包含。

---

## Multi-Skill 额外检查 (仅 Multi-Skill 树)

### Check M0: Skill Subtree Router Presence

- 对每个非 shared、非 cross-cutting 的 skill 子树，确认存在 `{skill}/ROUTER.md`
- 确认每个 `{skill}/ROUTER.md` 使用 Phase 2 能力路由，且至少覆盖该 skill 的所有 skill-specific / Shared-similar 叶节点
- 如果该 skill 的 Shared-identical 能力存放在 `shared/`，确认它可通过 ROOT.md 共享行或 `{skill}/ROUTER.md` 显式行追踪到 `shared/{capability}/SKILL.md`
- 手动追踪每个 `{skill}/ROUTER.md` 的 fallback 行，确认 fallback 最后且指向存在的 leaf

**通过标准**: 每个 skill 子树都有可执行的 Phase 2 ROUTER.md；ROOT.md 命中任何 skill 后，都能继续追踪到一个或多个 leaf/shared leaf。

### Check M1: Shared Keyword Coverage

- 列出 2+ 个 skill 共有的所有能力
- 确认 ROOT.md 的消歧规则覆盖每个共享词

### Check M2: Cross-Skill Path Non-interference

- 追踪 3+ 条来自不同 skill 的路由
- 确认没有错误路由到其他 skill 子树

### Check M3: Shared Leaf Accuracy
- 对于 Shared-identical 叶节点：确认指令完全相同
- 如果指令有任何差异，拆分为独立叶节点

### Check M4: Cross-Cutting Workflow Coverage

- 对每个 skill，确认 cross-cutting/SKILL.md 至少有一个涉及它的工作流
- 确认 cross-cutting 列出了所有 skill 的依赖关系

### Check M5: Multi-Intent Multi-Path Routing
- 构造 ≥ 3 个多意图 prompt，确认一个 prompt 可以命中多个 route paths
- 测试用例必须覆盖：
  1. 多个明确 skill 名称 → 命中多个 skill 子树
  2. 多个唯一领域词但未显式写 skill 名称 → 命中多个 skill 子树
  3. 共享能力 + 专属能力并存 → 同时命中 shared leaf 和专属 skill leaf，或进入 cross-cutting 编排

**操作步骤**:
1. 对每个多意图 prompt，先拆分出独立子任务
2. 手动追踪 ROOT.md Phase 1，列出所有命中的 Skill/ROUTER/shared/cross-cutting 路径
3. 对每个命中的 Skill 路径继续追踪 Phase 2，直到 leaf SKILL.md
4. 确认信号优先级只在单个子任务内部用于消歧，没有覆盖或丢弃其他子任务的命中路径
5. 若子任务之间存在数据依赖，确认路由进入 `cross-cutting/SKILL.md` 并由其继续逐个 skill 路由；若无依赖，确认可直接保留多个并行 leaf 路径

**通过标准**: 每个多意图测试用例都保留所有预期命中路径；不得只返回单个最高优先级路径，除非 prompt 本身只有一个可执行意图。

---

## Validation Failure Protocol

如果任何检查失败：
1. 直接在生成的文件中修复问题
2. 重新运行失败的检查以确认修复
3. 记录问题类型用于未来改进
