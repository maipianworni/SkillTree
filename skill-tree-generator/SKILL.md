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

Transform monolithic skills into modular, hierarchical skill-trees (ROOT.md → ROUTER.md → SKILL.md) with dynamic routing. Use when:
- A skill has grown too complex and needs modularization
- Multiple distinct workflows exist within a single skill
- Multiple related skills need to be unified under one routing tree
- Cross-domain workflows span multiple skills
- Overlapping capabilities across skills need deduplication
- An existing skill-tree needs new skills or capabilities added

## Strict Conformance

Before creating or modifying tree output, read and follow `references/strict_conformance.md`. Do not use substitute workflows, fast versions, heuristic-only splitting, or partial validation. If full conformance is impractical, stop and report the blocker before continuing.

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

**前置检查**: 执行 `references/error_handling.md` 中的 **Error Severity & Handling Strategy** — 源技能不可用（Fatal）则报错终止，局部缺失（Degraded）则生成回退内容。

For each leaf node, read `references/leaf_template.md` for the structure template. Extract the complete content from the original skill and fill it into the template. Do NOT replace any content with a file path reference or external link. Every instruction, code example, API reference, and constraint from the original skill must be inlined directly.

**引用处理**: 执行 `references/error_handling.md` 中的 **Reference File Processing Flow** Step R1-R4（盘点 → 决策 → 清理 → 即时验证）。

**自包含**: 遵循 `references/error_handling.md` 中的 **Self-Containment Rule**，生成结果必须作为 skill tree 整体自包含；短引用内联到叶节点，大文件集可拷贝到 tree 内并通过 tree 内部相对路径引用。

### Mode 1 Step 6: Create Output Structure

Create all files in the target directory. **Small files (≤10KB) use Write tool; large file sets (>5 files or >50KB) use staging + platform-native copy (`cp -a` on Unix/macOS, `robocopy` on Windows; `xcopy /E /I` only as last fallback) — never copy large directories file-by-file with Write. Treat `robocopy` return codes `< 8` as success.**

```
.claude/skills/{skill-name}-tree/     # Claude Code
# or
.agent/skills/{skill-name}-tree/      # Codex CLI / other AGENTS.md-aware agents
├── ROOT.md
├── SKILL-TREE.md              # Directory structure overview
├── GENERATION-REPORT.md       # Required evidence (see Strict Conformance)
├── {module1}/
│   ├── ROUTER.md
│   └── {submodule}/
│       └── SKILL.md
└── ...
```

### Mode 1 Step 7: Validation + Report

1. **Validate**: Read `references/validation_template.md` and execute its **执行架构** exactly. For Mode 1, run the Single-Skill checks only: main agent handles source-dependent checks and all fixes; sub agent handles only tree-only checks.
2. **Routing Refinement Stage**: After base validation passes, read and execute `references/routing_refinement.md`. Start a clean tree-only sub agent to scan every routing layer (`ROOT.md` plus all `ROUTER.md` files), compare every sibling group, identify ambiguous/high-frequency and dynamically repeated shared signals, and return structured failures plus a regression prompt matrix. The main agent fixes routing tables and overview/report evidence, then starts a new sub agent to revalidate until all refinement checks pass.
3. **Report**: Ensure `GENERATION-REPORT.md` in the tree root directory contains both independently written evidence sections, following the Required Evidence section in `references/strict_conformance.md`: validation results from both the main agent and sub agent, plus Routing Refinement Stage results.

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

Multi-skill trees require a two-phase routing: **Phase 1 selects one or more skills, Phase 2 selects one or more capabilities within each matched skill.** Multi-intent prompts must preserve all matched route paths.

### Mode 2 Step A: Cross-Skill Capability Collection

For each skill in the `--aggregate` list, independently analyze and extract capabilities.

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
├── ROOT.md                        # Phase 1: 选一个或多个 skill
├── SKILL-TREE.md                  # Overview with mapping table
├── GENERATION-REPORT.md           # Required evidence (see Strict Conformance)
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

### Mode 2 Step C2: Generate Leaf SKILL.md Files

对每个叶节点，按照 `references/error_handling.md` 的完整规则生成：

1. **前置检查**: Step A 已确认源技能存在 → 直接提取完整内容。如局部内容缺失 → 按 Degraded 级别生成 `[AUTO-GENERATED FALLBACK]` 回退
2. **引用文件处理**: 执行 Step R1-R4。Multi-Skill 场景下多个源技能的引用文件需统一处理。大文件集（>5 files / >50KB）使用 staging + 平台原生命令拷贝，禁止 Write 逐文件写入
3. **自包含**: 遵循 Self-Containment Rule，生成后的 skill tree 完全独立于源技能；短引用内联，大文件集可使用 tree 内部相对路径引用

### Mode 2 Step D: Multi-Skill ROOT.md Generation

ROOT.md must implement two-phase routing. Read `references/root_template.md` Multi-Skill section and generate ROOT.md following that template.

**Multi-intent requirement**: Generated Multi-Skill ROOT.md must support one prompt matching multiple route paths. When a prompt contains multiple independent intents, multiple skill names, multiple unique domain terms, or multiple separable subtasks, the router must split the prompt into subtasks and preserve every matched Skill/leaf route. Use `cross-cutting/SKILL.md` only when the matched paths need workflow coordination, sequencing, or data handoff; otherwise route into all matched skill subtrees directly.

### Mode 2 Step E: Multi-Skill SKILL-TREE.md Overview

Read `references/overview_template.md` Multi-Skill section and generate `SKILL-TREE.md`. The overview must include a skill dimension with the 能力→叶节点映射表 and Skill 覆盖统计.

### Mode 2 Step F: Cross-Cutting Workflows

Generate `cross-cutting/SKILL.md` following `references/cross_cutting_template.md`. This is a **workflow combiner** that:
1. Provides predefined cross-skill workflow definitions
2. Includes a custom workflow fallback mechanism (mandatory, see L7)

### Mode 2 Step G: Validation + Report

1. **Validate**: Read `references/validation_template.md` and execute its **执行架构** exactly. For Mode 2, run all base checks plus Multi-Skill checks M1-M5: main agent handles source-dependent checks and all fixes; sub agent handles only tree-only checks.
2. **Routing Refinement Stage**: After base validation passes, read and execute `references/routing_refinement.md` in Multi-Skill mode. Start a clean tree-only sub agent to scan `ROOT.md`, every skill `ROUTER.md`, `shared/`, and `cross-cutting/`; compare only explicit routing tables as sibling groups, while using shared/cross-cutting leaves for multi-intent path preservation and target validity checks. Verify sibling distinguishability, high-frequency and dynamically repeated shared keyword handling, and return a regression prompt matrix. The main agent fixes routing tables, `SKILL-TREE.md`, and report evidence, then starts a new sub agent to revalidate until all refinement checks pass.
3. **Report**: Ensure `GENERATION-REPORT.md` in the tree root directory contains both independently written evidence sections, following the Required Evidence section in `references/strict_conformance.md`: validation results from both the main agent and sub agent, plus Routing Refinement Stage results.

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
| 路由表标题 | "Step 1: L1 路由" | "Phase 1: 选 Skill" 或 "Phase 1: 选一个或多个 Skill" |
| 路由目标 | `./{module}/ROUTER.md` | `./{skill-name}/ROUTER.md` |
| 消歧规则 | 无 | 有消歧规则 section |

### Mode 3 Step B: For Single-Skill Tree — Same Skill or New Skill?

**This is the critical branch point.** When the existing tree is Single-Skill, determine whether `--add` is adding capabilities to the **same skill** or adding a **different skill**:

1. Read the tree's `SKILL-TREE.md` to identify the existing skill name(s)
2. Compare with the `--add` skill name/domain:
   - **Same skill** (e.g., tree is `web-dev-tree`, adding more `web-dev` capabilities) → **Step C** (add capability to existing skill)
   - **Different skill** (e.g., tree is `web-dev-tree`, adding `react`) → **Step D** (transform to Multi-Skill), then **Step E** (add new skill)

**How to judge "same" vs "different":**
- If the `--add` skill's domain overlaps significantly with the existing tree's domain AND the skill name matches the tree's original skill → same skill
- If the `--add` skill is a distinct technology/tool/domain with its own capability set → different skill
- When uncertain, treat as **different skill** (safer to restructure early than to force capabilities into wrong module)

**分支汇总：**
- **Single-Skill Tree + Same skill** → 执行 **Step C**（添加能力到已有 skill）
- **Single-Skill Tree + Different skill** → 执行 **Step D**（转型为 Multi-Skill tree）→ **Step E**（添加新 skill）
- **Multi-Skill Tree** → 执行 **Step E**（添加新 skill 到 Multi-Skill tree）

### Mode 3 Step C: Adding a new capability to the SAME skill (Single-Skill tree)

**前提**: Step B 已确认 `--add` 的技能与现有 Single-Skill tree 是同一个 skill。

1. Identify which module/leaf the new capability belongs to
2. Add to the leaf's workflow and examples
3. Update SKILL-TREE.md mapping table
4. Enrich keyword signals if the capability introduces new intent patterns

### Mode 3 Step D: Transform Single-Skill Tree to Multi-Skill Tree

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
├── ROOT.md              # Phase 1: 选一个或多个 Skill, Phase 2: 选能力
├── SKILL-TREE.md
├── {existing-skill}/    # 原 Single-Skill 的模块移入此处
│   ├── ROUTER.md        # 新建：原 L1 路由表移入此处
│   ├── {module1}/
│   │   ├── ROUTER.md    # 保持不变
│   │   └── {leaf}/SKILL.md
│   └── {module2}/...
├── {new-skill}/         # 新 skill 的子树（按 Step E 生成）
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
   - Phase 1: 选一个或多个 Skill — includes both existing skill and new skill, and preserves multi-intent matches
   - Phase 2: 选能力 — delegates to every matched skill sub-tree ROUTER.md
   - Add 多意图路由规则 section
   - Add 消歧规则 section
   - Add 信号优先级 table
5. **Create `shared/` directory** — initially empty, populated if Step E finds shared capabilities
6. **Create `cross-cutting/SKILL.md`** — follow Mode 2 Step F template, include workflows combining existing + new skill
7. **Update `SKILL-TREE.md`** — rewrite to Multi-Skill format with skill→capability mapping table and coverage stats
8. **Delete original top-level module directories** — after moving modules into `{existing-skill}/`, the original `{module1}/`, `{module2}/`, etc. directories at the tree root must be physically deleted. These are now orphan duplicates that must not remain alongside the new Multi-Skill structure.
9. **Then proceed to add the new skill** — execute Step E (add new skill to Multi-Skill tree) for the `--add` skill

**Important constraints during transformation:**
- **Preserve all existing leaf content** — no SKILL.md files are modified, only moved
- **Preserve all routing logic** — the old ROOT.md's routing conditions must be accurately transferred to `{existing-skill}/ROUTER.md`
- **Do NOT create stubs** — shared/ may be empty initially; only populate if shared capabilities are detected
- After transformation + adding new skill, run Mode 3 Step F validation with Multi-Skill checks

### Mode 3 Step E: Adding a new skill to existing Multi-Skill tree

1. **Analyze new skill** — extract full capability set。执行 `references/error_handling.md` 中的**Error Severity & Handling Strategy**：源技能不存在 → Fatal 报错终止
2. **Build comparison matrix** against existing skills (same as Mode 2 Step A)
3. **Identify new shared keywords** — any capability overlapping with existing skills
4. **Update ROOT.md** — add new skill route + update 多意图路由规则 and 消歧规则 for ALL new shared keywords. Ensure prompts mentioning the new skill plus existing skills can preserve multiple matched route paths.
5. **Create new skill sub-tree** — `{new-skill}/ROUTER.md` + leaf SKILL.md files。执行 `references/error_handling.md` 中的**Reference File Processing Flow** Step R1-R4，遵循 **Self-Containment Rule**。大文件集使用 staging + 平台原生命令拷贝，禁止 Write 逐文件写入
6. **Re-check shared leaves** — if new skill has identical capabilities, update shared leaf
7. **Update cross-cutting/SKILL.md** — add cross-skill workflow definitions + update dependencies (L7: most commonly missed step)
8. **Update SKILL-TREE.md** — add rows to mapping table + update coverage stats

### Mode 3 Step F: Validation + Report

1. **Validate**: Read `references/validation_template.md` and execute its **执行架构** exactly. For Mode 3, run base checks; if the resulting tree is Multi-Skill, also run M1-M5. Main agent handles source-dependent checks and all fixes; sub agent handles only tree-only checks.
2. **Routing Refinement Stage**: After base validation passes, read and execute `references/routing_refinement.md`. Use Single-Skill mode for Single-Skill results and Multi-Skill mode for transformed or existing Multi-Skill results. The sub agent remains tree-only/read-only, checks dynamically repeated shared signals, and returns structured failures plus a regression prompt matrix; the main agent fixes `ROOT.md`, all affected `ROUTER.md` files, `SKILL-TREE.md`, and report evidence, then starts a new sub agent for tree-only revalidation.
3. **Report**: Ensure `GENERATION-REPORT.md` in the tree root directory contains both independently written evidence sections, following the Required Evidence section in `references/strict_conformance.md`: validation results from both the main agent and sub agent, plus Routing Refinement Stage results.

---

## Templates

Reference templates are available in `references/`:
- `root_template.md` - ROOT.md generation template (Single-Skill + Multi-Skill)
- `router_template.md` - ROUTER.md generation template
- `leaf_template.md` - Leaf SKILL.md generation template
- `cross_cutting_template.md` - Cross-cutting workflows template (Multi-Skill)
- `overview_template.md` - SKILL-TREE.md overview template
- `validation_template.md` - Executable validation checklist (MUST run after generation)
- `routing_refinement.md` - Standalone second-stage routing table refinement workflow (MUST run after validation)
- `error_handling.md` - Error Handling, Reference File Processing, Self-Containment Rule (Unified Specification)
- `lessons_learned.md` - Lessons Learned（L1-L15）

## Example

**Input**: A monolithic "web-development" skill covering frontend, backend, and DevOps.

**Output Structure**:
```
web-development-tree/
├── ROOT.md
├── SKILL-TREE.md
├── GENERATION-REPORT.md
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

> **完整内容见** `references/lessons_learned.md`。以下为索引，具体的问题描述、根源分析和预防措施请阅读该文件。

| ID | 主题 | 一句话 |
|----|------|--------|
| L1 | 路由表分类不互斥 | 使用消歧规则处理边界重叠 |
| L2 | 叶节点内容太宽泛 | 每个叶节点保持单一职责 |
| L3 | 路由可观测性不足 | 默认静默，按需输出 `[Route]` 路径 |
| L4 | 上下文忽略 | 路由判断必须考虑完整对话历史 |
| L5 | 跨领域工作流遗漏 | ROOT.md 必须含并行读取多叶节点的指令 |
| L6 | 映射表不准 | 逐条计数，禁止目测估算 |
| L7 | Mode 3 遗漏 cross-cutting | 添加新 skill 时显式更新 cross-cutting/SKILL.md |
| L8 | 关键词信号无分层 | 单子任务内高 Tier 覆盖低 Tier；多意图先拆分子任务 |
| L9 | 共享叶节点指令不同 | 只有完全一致才能合并为 Shared-identical |
| L10 | 存根问题 | 已制度化 → `references/error_handling.md` |
| L11 | 叶节点指令弱化 | 保留所有执行级指令（代码、阈值、clamp 行为） |
| L12 | Mode 3 未转型 Single-Skill | Step B 显式判断 same/different skill |
| L13 | 转型后未删除顶级模块 | Step D 步骤 8 显式删除原模块目录 |
| L14 | 引用文件未内联/拷贝 | 已制度化 → `references/error_handling.md` |
| L15 | 参考文档索引未清理 | 已制度化 → `references/error_handling.md` |
| L16 | Multi-Skill 多意图被吞并 | Multi-Skill ROOT 必须保留多个命中路径 |
