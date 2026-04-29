# Validation Template

生成完成后必须逐项执行以下检查。**不可跳过任何一项。**

---

## Validation Checklist

### Check 1: Agent 记忆文件存在性

确认项目根目录有对应 agent 的记忆文件，且包含 skill-tree 路由协议。

**目标文件**（按当前 agent 选择）：

| Agent       | 记忆文件     | Skill 目录                              |
|-------------|-------------|-----------------------------------------|
| Claude Code | `CLAUDE.md` | `.claude/skills/`                       |
| Codex CLI   | `AGENTS.md` | `.agent/skills/`（或用户自定义目录）      |
| OpenCode    | `AGENTS.md` | `.opencode/skills/`                     |
| 其他支持 AGENTS.md 的 agent（Cursor / Aider / Jules 等） | `AGENTS.md` | 同上 |

操作：检查目标记忆文件是否已包含 `# CRITICAL — DO NOT SKIP` 和 `## Routing Protocol` 路由协议内容。
如果不存在，追加以下内容（注意把 `{SKILLS_DIR}` 替换为实际 Skill 目录）：

```markdown
# CRITICAL — DO NOT SKIP
You MUST follow this routing protocol BEFORE responding to any user request, no exceptions. This includes the very first message in a conversation.
Failure to read ROOT.md first is a critical error. Do not proceed with any task, tool call, or response until routing is complete.

## Routing Protocol
1. Glob `{SKILLS_DIR}/*-tree/ROOT.md` to discover all skill trees
2. Read every ROOT.md file found
3. Follow the routing logic in ROOT.md to select the correct skill
4. Only after routing is complete, proceed with the user's task

This applies to ALL tasks: research, code, editing, questions — everything.
```

**通过标准**：目标记忆文件已存在且包含 `# CRITICAL — DO NOT SKIP` 路由协议，或已成功追加。

**同仓库同时服务两种 agent 的推荐做法**：
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

### Check 9: Content Preservation (内容保留)

- 确认源 skill 中的所有内容在叶节点中都有保留
- 源 skill 中的指令在拆分过程中没有丢失

**操作步骤**:
1. 读取每个源 skill 的完整内容
2. 确认每段指令/公式/代码都出现在对应的叶节点中
3. 特别注意数值、阈值、具体实现细节

**通过标准**: 源 skill 的所有执行级指令完整迁移到叶节点。

---

### Check 10: Source Skill Existence (源技能存在性)

- 确认生成 tree 时引用的每个源 skill 都存在且内容非空
- 防止生成指向不存在文件的存根

**操作步骤**:
1. 列出 tree 中所有叶节点对应的源技能路径
2. 逐个确认源技能文件存在
3. 确认源技能文件内容非空（至少包含有效的 SKILL.md 内容）

**通过标准**: 所有源技能存在且内容非空。

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
5. 检查是否存在指向 tree 外部的路径引用（如 `.claude/skills/<source-skill>/`、绝对路径指向源技能目录）→ Grep pattern: `\.claude/skills/(?!.*-tree/)` 或类似的 tree 外部路径模式
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

---

## Validation Failure Protocol

如果任何检查失败：
1. 直接在生成的文件中修复问题
2. 重新运行失败的检查以确认修复
3. 记录问题类型用于未来改进
