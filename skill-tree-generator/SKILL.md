---
name: skill-tree-generator
description: Generates, aggregates, and extends modular skill-trees with hierarchical routing. Supports three modes — (1) convert a monolithic skill into a tree with ROOT.md/ROUTER.md/SKILL.md, (2) aggregate multiple skills into a unified cross-domain tree with shared leaves and disambiguation, (3) incrementally update an existing tree by adding new skills. Use when users need to restructure, merge, or extend skills into context-aware, load-on-demand hierarchies.
---

# Skill Tree Generator

## Usage

```
/skill-tree-generator <skill-name-or-skill-path-or-description>
/skill-tree-generator --aggregate skill1,skill2,... [--domain domain-name]
/skill-tree-generator --update <tree-path> --add <skill>
```

| 输入特征 | Mode | 描述 |
|---------|------|------|
| 单个 skill 路径/描述，无特殊 flag | **Mode 1** | 将单体 skill 转为路由树 |
| `--aggregate skill1,skill2,...` | **Mode 2** | 聚合多个 skill 为统一跨域树 |
| `--update <tree-path> --add <skill>` | **Mode 3** | 增量更新已有 tree |

## Overview

This skill transforms a monolithic skill or multiple skills into a modular, hierarchical skill-tree structure that enables dynamic routing based on user prompts. The generated skill-tree mimics a file system with:

- **ROOT.md** - Root-level routing protocol; 
- **ROUTER.md** - Navigation logic at each non-leaf level
- **SKILL.md** - Leaf nodes containing actual skill instructions

## When to Use This Skill

Use this skill when:
- A skill has grown too complex and needs modularization into sub-skills with routing
- Multiple distinct workflows exist within a single skill and context-aware routing is needed
- Multiple related skills need to be unified under one routing tree with shared capabilities
- Cross-domain workflows span multiple skills and need coordinated execution
- Overlapping capabilities across skills need deduplication or disambiguation
- An existing skill-tree needs new skills or capabilities added incrementally

---

## Mode 1: Single Skill Tree Generation

Generate a routing tree for a single skill.

**Input**: Skill path or description
**Output**: Complete tree structure in `{skill-name}-tree/`

Example:
```
/skill-tree-generator web-development
```

### Mode 1 Step 1: Analyze Input Skill

First, analyze the input skill to identify:

1. **Core domains** - What major functional areas does the skill cover?
2. **Sub-domains** - Within each core domain, what sub-categories exist?
3. **Leaf capabilities** - What specific tasks/endpoints are at the lowest level?
4. **Routing criteria** - What signals distinguish one path from another?

Read the skill content:
```
$ARGUMENTS
```

If `$ARGUMENTS` is a file path, read that file. If it's a description, use it directly.

### Mode 1 Step 2: Design Tree Structure

Based on analysis, design the hierarchy following these principles:

```
skill-tree/
├── ROOT.md                    # L1 routing protocol
├── {module1}/
│   ├── ROUTER.md              # L2 routing logic
│   ├── {submodule}/
│   │   ├── ROUTER.md          # L3 routing logic
│   │   └── {feature}/SKILL.md # Leaf node
└── {module2}/
    └── ...
```

**Design Guidelines:**
- **L1 modules**: Major functional domains (2-5 modules typical)
- **L2 submodules**: Sub-categories within each domain
- **Leaf nodes**: Specific, atomic tasks/capabilities
- **Depth limit**: 3-4 levels maximum for efficiency

### Mode 1 Step 3: Generate ROOT.md

Read `references/root_template.md` and generate `ROOT.md` following the Single-Skill section template.

### Mode 1 Step 4: Generate ROUTER.md Files

For each non-leaf level, read `references/router_template.md` and generate `ROUTER.md` following that template.

**Routing Table Guidelines (supplement to template):**
- Conditions should be mutually exclusive when possible
- Use keyword matching, domain terminology, task patterns
- Include "Other/Default" row for fallback
- Reference context from conversation history

### Mode 1 Step 5: Generate Leaf SKILL.md Files

**前置检查**: 对每个叶节点，在生成前先确认源技能内容可获取。

1. 如果源技能文件不存在 → **报错终止**，列出所有缺失的技能路径
2. 如果源技能文件存在但内容为空 → **报错终止**
3. 只有源内容完整可用时，才继续生成

For each leaf node, read `references/leaf_template.md` for the structure template. Extract the complete content from the original skill and fill it into the template. Do NOT replace any content with a file path reference or external link. Every instruction, code example, API reference, and constraint from the original skill must be inlined directly.

### 容错机制

源技能文件不存在时的处理策略详见 **L10（存根问题）** 预防项 #4：要么报错终止，要么生成有意义的回退内容而非存根。

**Self-Containment Rule [MANDATORY]**: Every leaf node must be fully self-contained, whether it contains executable instructions or reference data. Never create stub files that only contain a summary and a pointer to an external file. An agent loading only the tree must have everything needed to execute. This includes:
- Feature dictionaries with Min/Max ranges and conversion factors
- API endpoint specifications, including endpoints, parameters, and response formats
- Enumerations, lookup tables, classification codes
- Executable workflow steps, code examples, and usage patterns
- Any data that the original skill contained or referenced

If the original skill references an external file, read that file and inline its content into the appropriate leaf node. Do NOT leave a "see file X" reference.

### 引用文件处理流程

在生成每个叶节点时，必须执行以下引用处理流程：

**Step 5a: 盘点外部引用**
对源技能中每个被引用的文件/目录，使用 Glob 确认其是否存在：
- 存在于源技能包中 → 继续 Step 5b
- 不存在于源技能包中 → 标记为"不可用"

**Step 5b: 决策处理方式**

| 引用类型 | 处理方式 |
|---------|---------|
| 短文件（几屏以内） | 内联完整内容到叶节点的工作流/约束中 |
| 大量文件或长内容（如文档库 90+ .md） | 拷贝整个目录到 tree 内（如 `{skill}/docs/`），叶节点中使用 tree 内部相对路径（`../docs/`） |
| 不存在于源技能包中（如 `scripts/`、`references/*.json`） | 删除引用，替换为可直接执行的自包含指令（如用 Grep/Read 替代脚本调用） |

**Step 5c: 生成后清理**
所有叶节点生成完毕后：
1. Grep 扫描所有叶节点中是否包含 "参考文档索引"/"Reference"/"References" 等段落
2. 对每个引用条目三步处理：
   - 文件已拷贝到 tree 内 → 路径替换为 tree 内部相对路径
   - 内容已内联到叶节点 → 删除该引用条目（内容已在叶节点中）
   - 文件在源技能包中不存在 → 删除整个"参考文档索引"段落
3. Grep 扫描所有叶节点中是否存在指向 tree 外部的绝对路径（如 `.claude/skills/<source-skill>/`），全部替换为 tree 内部相对路径或删除

### Mode 1 Step 6: Create Output Structure

Create all files in the target directory:

```
.claude/skills/{skill-name}-tree/     # Claude Code
# or
.agent/skills/{skill-name}-tree/      # Codex CLI / other AGENTS.md-aware agents
├── ROOT.md
├── SKILL-TREE.md              # Directory structure overview
├── {module1}/
│   ├── ROUTER.md
│   └── {submodule}/
│       └── SKILL.md
└── ...
```

### Mode 1 Final Step: Validation
After generating all files, you **MUST** execute every check in `references/validation_template.md`.

**How to run**: Read `references/validation_template.md` and execute each check sequentially. Do not treat this section as informational — it is an executable checklist. For each check:
1. Perform the specified operations
2. Record pass/fail status
3. If any check fails, fix the generated files and re-run that check

---

## Mode 2: Multi-Skill Aggregate Tree

Generate a routing tree that covers multiple skills. Skills can be from the same domain or from different domains.

**Input**: `--aggregate skill1,skill2,skill3 [--domain domain-name]`
**Output**: Unified tree with shared ROOT.md, each skill as a sub-tree

`--domain` is optional. When omitted, the tree covers cross-domain skills and ROOT.md routes by domain intent. When provided, the tree covers same-domain skills and ROOT.md routes by capability differences within that domain.

Examples:
```
# Cross-domain: coding + writing + security
/skill-tree-generator --aggregate web-dev,technical-writing,security-review

# Same-domain: frontend frameworks
/skill-tree-generator --aggregate react,vue,svelte --domain frontend
```

Multi-skill trees require a two-phase routing: **Phase 1 selects the skill, Phase 2 selects the capability within that skill.**

### Mode 2 Step A: Cross-Skill Capability Collection

For each skill in the `--aggregate` list, independently analyze and extract capabilities.

**前置检查（同 Mode 1 Step 5）**:
1. 逐个确认每个源技能文件存在且内容非空
2. 如果有技能不存在 → **报错终止**，列出缺失的技能列表
3. 只有在全部存在时才继续

Then build a comparison matrix:

```
| 能力组 | Skill_A | Skill_B | Skill_C |
|--------|---------|---------|---------|
| project | ✓ create,open,save | ✓ create,save | ✗ |
| editing | ✓ add,remove,set | ✗ | ✓ add,remove |
| export  | ✓ render | ✓ export-pdf | ✓ render |
| session | ✓ undo,redo | ✗ | ✓ undo,redo |
```

### Mode 2 Step B: Shared vs Unique Classification

Classify every capability group:

| 类别 | 定义 | 处理方式 |
|------|------|---------|
| **Unique** | 仅一个 skill 有此功能 | 直接放入该 skill 的子树 |
| **Shared-similar** | 多个 skill 有相似功能 | 各自独立叶节点，ROOT.md 消歧 |
| **Shared-identical** | 功能/指令完全相同 | 合并为共享叶节点，标注适用 skill |

### Mode 2 Step C: Two-Phase Hierarchy Design

```
{domain}-tree/
├── ROOT.md                        # Phase 1: 选 skill
├── SKILL-TREE.md                  # Overview with mapping table
├── {skill_a}/                     # Skill A 的完整子树
│   ├── ROUTER.md                  # Phase 2: 选能力
│   └── {capability}/SKILL.md
├── {skill_b}/                     # Skill B 的完整子树
│   ├── ROUTER.md
│   └── {capability}/SKILL.md
├── shared/                        # Shared-identical 能力
│   └── {capability}/SKILL.md      # 标注: 适用于 skill_a, skill_b
└── cross-cutting/
    └── SKILL.md                   # 跨 skill 工作流
```

### Mode 2 Step C2: Generate Leaf SKILL.md Files [同 Mode 1 Step 5]

对每个叶节点，按照 Mode 1 Step 5 的完整规则生成（含前置检查、禁止存根、引用文件处理流程、生成后清理）：

1. **前置检查**: 从 Step A 已确认源技能存在，直接提取完整内容
2. **禁止存根**: 每个叶节点必须完全自包含，绝对禁止指向外部文件的引用
3. **引用文件处理**: 执行 Mode 1 Step 5 中的 Step 5a（盘点）、Step 5b（决策：内联/拷贝/删除）、Step 5c（生成后清理）——此步骤在 Multi-Skill 场景下尤为重要，因为多个源技能的引用文件需要统一处理
4. **容错**: 虽然 Step A 已前置检查，但如果某技能的子能力内容不可用时，使用 `[AUTO-GENERATED FALLBACK]` 回退
5. **Self-Containment Rule**: 同 Mode 1 Step 5，所有叶节点必须自包含，tree 完全独立于源技能

### Mode 2 Step D: Multi-Skill ROOT.md Generation

ROOT.md must implement two-phase routing. Read `references/root_template.md` Multi-Skill section and generate ROOT.md following that template.

### Mode 2 Step E: Multi-Skill SKILL-TREE.md Overview

Read `references/overview_template.md` Multi-Skill section and generate `SKILL-TREE.md`. The overview must include a skill dimension with the 能力→叶节点映射表 and Skill 覆盖统计.

### Mode 2 Step F: Cross-Cutting Workflows

Generate `cross-cutting/SKILL.md` following `references/cross_cutting_template.md`. This is a **workflow combiner** that:
1. Provides predefined cross-skill workflow definitions
2. Includes a custom workflow fallback mechanism (mandatory, see L7)

### Mode 2 Final Step: Validation
After generating all files, you **MUST** execute every check in `references/validation_template.md`.

**How to run**: Read `references/validation_template.md` and execute each check sequentially. Do not treat this section as informational — it is an executable checklist. For each check:
1. Perform the specified operations
2. Record pass/fail status
3. If any check fails, fix the generated files and re-run that check

---

## Mode 3: Update Existing Tree

Add new skills or capabilities to an existing tree.

**Input**: `--update <tree-path> --add <skill-name>`
**Output**: Updated tree files

Example:
```
/skill-tree-generator --update {skills-dir}/coding-tree --add angular
# e.g. Claude Code:  /skill-tree-generator --update .claude/skills/coding-tree --add angular
# e.g. Codex CLI:    /skill-tree-generator --update .agent/skills/coding-tree --add angular
```

### Mode 3 Step A: Detect Single-Skill or Multi-Skill

Read `<tree-path>/ROOT.md` and check:

| 特征 | Single-Skill Tree | Multi-Skill Tree |
|------|-------------------|------------------|
| 路由表标题 | "Step 1: L1 路由" | "Phase 1: 选 Skill" |
| 路由目标 | `./{module}/ROUTER.md` | `./{skill-name}/ROUTER.md` |
| 消歧规则 | 无 | 有消歧规则 section |

### Mode 3 Step A2: For Single-Skill Tree — Same Skill or New Skill?

**This is the critical branch point.** When the existing tree is Single-Skill, determine whether `--add` is adding capabilities to the **same skill** or adding a **different skill**:

1. Read the tree's `SKILL-TREE.md` to identify the existing skill name(s)
2. Compare with the `--add` skill name/domain:
   - **Same skill** (e.g., tree is `web-dev-tree`, adding more `web-dev` capabilities) → **Step B** (add capability to existing skill)
   - **Different skill** (e.g., tree is `web-dev-tree`, adding `react`) → **Step B2** (transform to Multi-Skill, then add new skill)

**How to judge "same" vs "different":**
- If the `--add` skill's domain overlaps significantly with the existing tree's domain AND the skill name matches the tree's original skill → same skill
- If the `--add` skill is a distinct technology/tool/domain with its own capability set → different skill
- When uncertain, treat as **different skill** (safer to restructure early than to force capabilities into wrong module)

**分支汇总：**
- **Single-Skill Tree + Same skill** → 执行 **Step B**（添加能力到已有 skill）
- **Single-Skill Tree + Different skill** → 执行 **Step B2**（转型为 Multi-Skill tree，然后添加新 skill）
- **Multi-Skill Tree** → 执行 **Step C**（添加新 skill 到 Multi-Skill tree）

### Mode 3 Step B2: Transform Single-Skill Tree to Multi-Skill Tree

When adding a different skill to a Single-Skill tree, the tree must be restructured from Mode 1 format to Mode 2 format before adding the new skill.

**Current structure (Single-Skill):**
```
{tree}/
├── ROOT.md              # Step 1: L1 路由 → ./{module}/ROUTER.md
├── SKILL-TREE.md
├── {module1}/
│   ├── ROUTER.md
│   └── {leaf}/SKILL.md
└── {module2}/
    └── ...
```

**Target structure (Multi-Skill):**
```
{tree}/
├── ROOT.md              # Phase 1: 选 Skill, Phase 2: 选能力
├── SKILL-TREE.md
├── {existing-skill}/    # 原 Single-Skill 的模块移入此处
│   ├── ROUTER.md        # 新建：原 L1 路由表移入此处
│   ├── {module1}/
│   │   ├── ROUTER.md    # 保持不变
│   │   └── {leaf}/SKILL.md
│   └── {module2}/...
├── {new-skill}/         # 新 skill 的子树（按 Step C 生成）
│   ├── ROUTER.md
│   └── ...
├── shared/              # 共享能力目录
├── cross-cutting/       # 跨 skill 工作流
│   └── SKILL.md
```

**Transformation steps:**

1. **Identify existing skill name** from SKILL-TREE.md and the tree directory name
2. **Create `{existing-skill}/` subdirectory** and move all existing module directories into it
3. **Create `{existing-skill}/ROUTER.md`** — convert the old ROOT.md's L1 routing table into a skill-level ROUTER.md:
   - The old ROOT.md's `| {category} | Read ./{module}/ROUTER.md |` table becomes the new ROUTER.md's routing table
   - Add `[L2]` level marker
   - Preserve all routing conditions and context hints
4. **Rewrite ROOT.md** to Multi-Skill format (follow Mode 2 Step D template):
   - Phase 1: 选 Skill — includes both existing skill and new skill
   - Phase 2: 选能力 — delegates to skill sub-tree ROUTER.md
   - Add 消歧规则 section
   - Add 信号优先级 table (L8)
5. **Create `shared/` directory** — initially empty, populated if Step C finds shared capabilities
6. **Create `cross-cutting/SKILL.md`** — follow Mode 2 Step F template, include workflows combining existing + new skill
7. **Update `SKILL-TREE.md`** — rewrite to Multi-Skill format with skill→capability mapping table and coverage stats
8. **Delete original top-level module directories** — after moving modules into `{existing-skill}/`, the original `{module1}/`, `{module2}/`, etc. directories at the tree root must be physically deleted. These are now orphan duplicates that must not remain alongside the new Multi-Skill structure.
9. **Then proceed to add the new skill** — execute Step C (add new skill to Multi-Skill tree) for the `--add` skill

**Important constraints during transformation:**
- **Preserve all existing leaf content** — no SKILL.md files are modified, only moved
- **Preserve all routing logic** — the old ROOT.md's routing conditions must be accurately transferred to `{existing-skill}/ROUTER.md`
- **Do NOT create stubs** — shared/ may be empty initially; only populate if shared capabilities are detected
- After transformation + adding new skill, run full Mode 2 validation

### Mode 3 Step B: Adding a new capability to the SAME skill (Single-Skill tree)

**前提**: Step A2 已确认 `--add` 的技能与现有 Single-Skill tree 是同一个 skill。

1. Identify which module/leaf the new capability belongs to
2. Add to the leaf's workflow and examples
3. Update SKILL-TREE.md mapping table
4. Enrich keyword signals if the capability introduces new intent patterns

### Mode 3 Step C: Adding a new skill to existing Multi-Skill tree

1. **Analyze new skill** — extract full capability set (先确认源技能存在，不存在则报错)
2. **Build comparison matrix** against existing skills (same as Mode 2 Step A)
3. **Identify new shared keywords** — any capability overlapping with existing skills
4. **Update ROOT.md** — add new skill route + update 消歧规则 for ALL new shared keywords
5. **Create new skill sub-tree** — `{new-skill}/ROUTER.md` + leaf SKILL.md files
   - **禁止存根**: 新叶节点必须自包含，不得引用外部文件
   - **引用文件处理**: 执行 Mode 1 Step 5 中的引用文件处理流程（Step 5a/5b/5c）——盘点新技能的外部引用，按短文件内联/多文件拷贝/不存在删除的策略处理
   - **Self-Containment Rule**: 同 Mode 1 Step 5，所有新叶节点必须内联完整内容，tree 完全独立于源技能
6. **Re-check shared leaves** — if new skill has identical capabilities, update shared leaf
7. **Update cross-cutting/SKILL.md** — add cross-skill workflow definitions + update dependencies (L7: most commonly missed step)
8. **Update SKILL-TREE.md** — add rows to mapping table + update coverage stats

### Mode 3 Final Step: Validation
After generating all files, you **MUST** execute every check in `references/validation_template.md`.

**How to run**: Read `references/validation_template.md` and execute each check sequentially. Do not treat this section as informational — it is an executable checklist. For each check:
1. Perform the specified operations
2. Record pass/fail status
3. If any check fails, fix the generated files and re-run that check

---

## Templates

Reference templates are available in `references/`:
- `root_template.md` - ROOT.md generation template (Single-Skill + Multi-Skill)
- `router_template.md` - ROUTER.md generation template
- `leaf_template.md` - Leaf SKILL.md generation template
- `cross_cutting_template.md` - Cross-cutting workflows template (Multi-Skill)
- `overview_template.md` - SKILL-TREE.md overview template
- `validation_template.md` - Executable validation checklist (MUST run after generation)

## Example

**Input**: A monolithic "web-development" skill covering frontend, backend, and DevOps.

**Output Structure**:
```
web-development-tree/
├── ROOT.md
├── SKILL-TREE.md
├── frontend/
│   ├── ROUTER.md
│   ├── react/SKILL.md
│   ├── vue/SKILL.md
│   └── css/SKILL.md
├── backend/
│   ├── ROUTER.md
│   ├── api/SKILL.md
│   └── database/SKILL.md
└── devops/
    ├── ROUTER.md
    ├── ci-cd/SKILL.md
    └── docker/SKILL.md
```

---

## Lessons Learned

### L1: 路由表分类不互斥
**问题**: L1 路由表中的分类有重叠，导致同一个 prompt 匹配多个路由目标。
**预防**: 路由条件应尽量互斥，使用消歧规则处理边界情况。

### L2: 叶节点内容太宽泛
**问题**: 叶节点包含太多不相关的工作流，失去模块化的意义。
**预防**: 每个叶节点只处理一类连贯的任务，保持单一职责。

### L3: 路由可观测性不足
**问题**: Agent 默认向用户汇报路由中间步骤（"我正在判断你属于哪个模块..."）吵闹，或完全不输出路由信息导致调试困难。
**预防**: 默认静默执行路由。提供按需开关：用户 prompt 含 "路由调试"/"debug routing"/"路由追踪" 时输出紧凑路由路径 `[Route] ROOT → ... → [LEAF]`，其他时候不输出。

### L4: 上下文忽略
**问题**: 路由判断只看当前 prompt，忽略对话中已建立的技术栈上下文。
**预防**: 每个路由节点必须显式要求考虑完整对话历史。

### L5: 跨领域工作流遗漏
**问题**: 用户任务跨越多个模块时，没有机制将多个叶节点组合执行。
**预防**: ROOT.md 必须包含"如果任务跨越多个类别，并行读取多个叶节点"的指令。

### L6: SKILL-TREE.md 映射表不准
**问题**: 手动估算叶节点数，SKILL-TREE.md 统计表与实际不一致。
**预防**: 生成映射表后逐条计数，禁止目测估算。

### L7: Mode 3 添加新 skill 时遗漏 cross-cutting 更新
**问题**: 添加新 skill 时只更新了子树和 ROOT.md，没有更新 cross-cutting/SKILL.md 的跨 skill 工作流定义。
**预防**: Mode 3 步骤 7 现在显式要求更新 cross-cutting/SKILL.md。

### L8: 关键词信号缺少分层和深度
**问题**: ROOT.md 信号表只有高层描述词，缺少领域专有术语；多信号冲突时无优先级。
**预防**: 信号分 T1（唯一确定词）、T2（领域偏好词）、T3（跨领域通用词）三层。路由时高 Tier 覆盖低 Tier。root_template.md 消歧规则包含信号优先级模板。

### L9: 共享叶节点指令不完全相同
**问题**: 将两个 skill 的相似能力合并为 Shared-identical 叶节点，但实际指令细节不同。
**预防**: 只有指令完全一致才能合并为 Shared-identical。有任何差异则分为 Shared-similar 各自独立叶节点。

### L10: 存根问题

**问题**: 生成 skill-tree 时，叶节点只生成 stub（标题+分类摘要+指向外部文件的链接），而非内联完整数据或指令。单个 stub 导致该能力不可用；多个叶节点同时被 stub 化则导致整条路径断裂、能力域完全不可用。尤其危险的场景是：技能本身不存在于环境中，tree 完全依赖自身内容来指导 agent，此时 stub = 功能缺失。

**根源**: (1) 生成时没有检查源技能是否存在；(2) "自包含"要求未覆盖所有叶节点；(3) 验证阶段未检测存根模式；(4) 原始 skill 中的参考数据（特征字典、换算表、API 规格等）被拆出为独立叶节点时只做了摘要而非完整迁移。

**预防**:
1. **前置检查**：生成前确认每个源技能都存在，不存在则报错而不是创造存根
2. **禁止存根**：所有叶节点必须自包含，绝对禁止指向外部文件的引用。原始 skill 中引用的外部文件必须在生成时读取并嵌入到叶节点中
3. **验证检测**：验证阶段必须扫描所有叶节点，检测存根模式（"Read the skill at"、"Full Instructions": Read 等）
4. **容错机制**：源技能缺失时，要么报错终止，要么生成有意义的回退内容而非存根

### L11: 叶节点指令弱化（边界处理丢失）

**问题**: 拆分原始 skill 时，叶节点中保留了算法骨架，但弱化了原始 skill 中的关键执行细节（如 boundary clamp 的具体实现、5% tolerance 的 clamp 行为变成了"可选建议"）。原始 skill 说 "acceptable to use a 5% tolerance and clamp values"，拆分后变成 "do NOT clamp unless very slightly outside" —— 语义反转导致边界值未被修复。
**预防**: 叶节点必须保留原始 skill 中的所有**执行级指令**（具体代码、阈值、clamp 行为），不能只保留"高层指导"。特别是数值处理逻辑，弱化措辞会导致行为改变。生成时应比对原始 skill 中的每个具体指令是否完整迁移。

### L12: Mode 3 添加不同 skill 时未转型 Single-Skill Tree

**问题**: 初始用 Mode 1 将单个 skill 转为 skill-tree（Single-Skill 结构，ROOT.md 使用 "Step 1: L1 路由"），之后通过 Mode 3 `--update --add` 添加一个**不同的新 skill** 时，Step A 仅检测到 Single-Skill Tree 就直接进入 Step B（添加能力到已有 skill），导致新 skill 被错误地当作已有 skill 的能力增量处理，而非作为独立 skill 子树加入。

**根源**: Mode 3 Step A 的分支逻辑缺失了 "Single-Skill + 不同 skill" 这种情况。Step B 的设计前提是添加能力到**同一个 skill**，不适用于添加全新 skill。

**预防**:
1. **Step A2 显式判断**: Single-Skill Tree 下必须进一步判断 `--add` 是同一 skill 还是不同 skill
2. **Step B2 转型**: 不同 skill 时，必须先将 Single-Skill tree 转型为 Multi-Skill tree（Mode 2 结构），再添加新 skill
3. **转型保留完整性**: 转型过程保持所有现有叶节点内容和路由逻辑不变，仅调整目录结构和 ROOT.md 格式

### L13: Step B2 转型后未删除原 Single-Skill 顶级模块目录

**问题**: Single-Skill tree 转型为 Multi-Skill tree 时，将原顶级模块目录（`charts/`、`interactivity/` 等）移入 `{existing-skill}/` 子目录后，未显式删除树根目录下的原模块目录。结果树中存在两套并行的模块文件——一套在 `{existing-skill}/` 下（Multi-Skill 路由目标），一套在树根目录下（孤儿文件，不被任何路由引用）。不仅造成混乱，还可能导致 agent 误读孤儿文件而绕过正确的 Phase 1 路由。

**根源**: Step B2 的 "move" 步骤在实践中可能被执行为 "copy"（尤其当目标子目录已存在时），缺少显式的删除原目录步骤。

**预防**:
1. **Step B2 步骤 8 显式删除**: 转换完成后，必须删除树根目录下的原模块目录（`{module1}/`、`{module2}/` 等）
2. **验证检测**: Check 3 (Reachability) 会标记所有孤儿文件，转型后必须无孤儿文件
3. **删除前确认**: 在删除前确认 `{existing-skill}/` 子目录下的对应文件已完整迁移

### L14: 引用文件未内联/拷贝导致叶节点依赖外部源技能

**问题**: 源技能中引用了外部文件（如 `docs/`、`references/`、`scripts/`），生成器在叶节点中保留了指向源技能目录的外部路径（如 `.claude/skills/xxx/docs/...`），而不是将内容内联或拷贝到 tree 内。导致：
- 删除源技能后 tree 中的检索/参考路径全部失效
- tree 不是真正自包含的，违反了 Self-Containment Rule

**根源**: 生成器对所有引用一视同仁——没有区分"可内联的短内容"和"应拷贝的大文件集"。对于 `docs/` 这类大量文件，简单地保留了外部路径引用。

**预防**:
1. **生成前盘点**: 在生成叶节点之前，先 Glob 列出源技能中所有被引用的外部文件/目录
2. **短文件内联**: 单文件内容较短（几屏以内）→ 直接内联到叶节点的工作流/约束中
3. **多文件或长内容拷贝**: 文件数量多或单文件内容长（如文档库有 90+ 个 .md 文件）→ 将整个目录拷贝到 tree 内的对应位置（如 `{skill}/docs/`），叶节点中使用 tree 内部相对路径（`../docs/`）
4. **不存在的文件删除引用**: 源技能包中不存在的文件（如复制包中缺失的 `scripts/`、`references/*.json`）→ 删除引用，替换为可直接执行的自包含指令（如用 Grep/Read 替代脚本调用）
5. **验证检测**: Check 11 (No Stub Files) 应额外检查是否存在指向 tree 外部的路径引用

### L15: 叶节点中"参考文档索引"段落未做路径替换或删除

**问题**: 叶节点生成后，从源技能复制过来的"参考文档索引"/"Reference Documents"段落仍保留了指向源技能 `references/` 目录的原始路径。这些文件在复制包中往往不存在，删除源技能后这些路径完全失效。更严重的是，这些段落给 agent 造成"还有更多详细信息在外部"的错觉，实际内容已经在叶节点中内联完毕。

**根源**: 生成器在拆分源技能内容到叶节点时，将"参考文档索引"段落原样复制，没有执行路径替换（指向 tree 内部副本）或删除（引用文件不存在）的决策。

**预防**:
1. **生成后扫描**: 所有叶节点生成完毕后，Grep 扫描 `参考文档索引`/`Reference`/`References` 等段落
2. **三步处理每个引用**:
   - 文件已拷贝到 tree 内 → 将路径替换为 tree 内部相对路径
   - 文件内容已内联到叶节点 → 删除该引用条目（内容已在叶节点中）
   - 文件在复制包中不存在 → 删除整个"参考文档索引"段落
3. **纳入验证**: 此检查应作为 Check 11 (No Stub Files) 的一部分——外部文件路径引用等同于存根
