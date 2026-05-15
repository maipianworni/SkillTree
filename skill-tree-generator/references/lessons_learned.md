# Lessons Learned

## L1: 路由表分类不互斥
**问题**: L1 路由表中的分类有重叠，导致同一个 prompt 匹配多个路由目标。
**预防**: 路由条件应尽量互斥，使用消歧规则处理边界情况。

## L2: 叶节点内容太宽泛
**问题**: 叶节点包含太多不相关的工作流，失去模块化的意义。
**预防**: 每个叶节点只处理一类连贯的任务，保持单一职责。

## L3: 路由可观测性不足
**问题**: Agent 默认向用户汇报路由中间步骤（"我正在判断你属于哪个模块..."）吵闹，或完全不输出路由信息导致调试困难。
**预防**: 默认静默执行路由。提供按需开关：用户 prompt 含 "路由调试"/"debug routing"/"路由追踪" 时输出紧凑路由路径 `[Route] ROOT → ... → [LEAF]`，其他时候不输出。

## L4: 上下文忽略
**问题**: 路由判断只看当前 prompt，忽略对话中已建立的技术栈上下文。
**预防**: 每个路由节点必须显式要求考虑完整对话历史。

## L5: 跨领域工作流遗漏
**问题**: 用户任务跨越多个模块时，没有机制将多个叶节点组合执行。
**预防**: ROOT.md 必须包含"如果任务跨越多个类别，并行读取多个叶节点"的指令。

## L6: SKILL-TREE.md 映射表不准
**问题**: 手动估算叶节点数，SKILL-TREE.md 统计表与实际不一致。
**预防**: 生成映射表后逐条计数，禁止目测估算。

## L7: Mode 3 添加新 skill 时遗漏 cross-cutting 更新
**问题**: 添加新 skill 时只更新了子树和 ROOT.md，没有更新 cross-cutting/SKILL.md 的跨 skill 工作流定义。
**预防**: Mode 3 步骤 7 现在显式要求更新 cross-cutting/SKILL.md。

## L8: 关键词信号缺少分层和深度
**问题**: ROOT.md 信号表只有高层描述词，缺少领域专有术语；多信号冲突时无优先级。
**预防**: 信号分 T1（唯一确定词）、T2（领域偏好词）、T3（跨领域通用词）三层。路由时高 Tier 覆盖低 Tier。root_template.md 消歧规则包含信号优先级模板。

## L9: 共享叶节点指令不完全相同
**问题**: 将两个 skill 的相似能力合并为 Shared-identical 叶节点，但实际指令细节不同。
**预防**: 只有指令完全一致才能合并为 Shared-identical。有任何差异则分为 Shared-similar 各自独立叶节点。

## L10: 存根问题

**问题**: 生成 skill-tree 时，叶节点只生成 stub（标题+分类摘要+指向外部文件的链接），而非内联完整数据或指令。单个 stub 导致该能力不可用；多个叶节点同时被 stub 化则导致整条路径断裂、能力域完全不可用。尤其危险的场景是：技能本身不存在于环境中，tree 完全依赖自身内容来指导 agent，此时 stub = 功能缺失。

**根源**: (1) 生成时没有检查源技能是否存在；(2) "自包含"要求未覆盖所有叶节点；(3) 验证阶段未检测存根模式；(4) 原始 skill 中的参考数据（特征字典、换算表、API 规格等）被拆出为独立叶节点时只做了摘要而非完整迁移。

> **已制度化**: 本问题的预防措施已纳入 `references/error_handling.md`。错误分级表定义了 Fatal/Degraded/Warning 三级处理策略，自包含规则 禁止存根，Step R4 即时验证在最终验证之前拦截存根模式。

## L11: 叶节点指令弱化（边界处理丢失）

**问题**: 拆分原始 skill 时，叶节点中保留了算法骨架，但弱化了原始 skill 中的关键执行细节（如 boundary clamp 的具体实现、5% tolerance 的 clamp 行为变成了"可选建议"）。原始 skill 说 "acceptable to use a 5% tolerance and clamp values"，拆分后变成 "do NOT clamp unless very slightly outside" —— 语义反转导致边界值未被修复。
**预防**: 叶节点必须保留原始 skill 中的所有**执行级指令**（具体代码、阈值、clamp 行为），不能只保留"高层指导"。特别是数值处理逻辑，弱化措辞会导致行为改变。生成时应比对原始 skill 中的每个具体指令是否完整迁移。

## L12: Mode 3 添加不同 skill 时未转型 Single-Skill Tree

**问题**: 初始用 Mode 1 将单个 skill 转为 skill-tree（Single-Skill 结构，ROOT.md 使用 "Step 1: L1 路由"），之后通过 Mode 3 `--update --add` 添加一个**不同的新 skill** 时，Step A 仅检测到 Single-Skill Tree 就直接进入 Step B（添加能力到已有 skill），导致新 skill 被错误地当作已有 skill 的能力增量处理，而非作为独立 skill 子树加入。

**根源**: Mode 3 Step A 的分支逻辑缺失了 "Single-Skill + 不同 skill" 这种情况。Step B 的设计前提是添加能力到**同一个 skill**，不适用于添加全新 skill。

**预防**:
1. **Step A2 显式判断**: Single-Skill Tree 下必须进一步判断 `--add` 是同一 skill 还是不同 skill
2. **Step B2 转型**: 不同 skill 时，必须先将 Single-Skill tree 转型为 Multi-Skill tree（Mode 2 结构），再添加新 skill
3. **转型保留完整性**: 转型过程保持所有现有叶节点内容和路由逻辑不变，仅调整目录结构和 ROOT.md 格式

## L13: Step B2 转型后未删除原 Single-Skill 顶级模块目录

**问题**: Single-Skill tree 转型为 Multi-Skill tree 时，将原顶级模块目录（`charts/`、`interactivity/` 等）移入 `{existing-skill}/` 子目录后，未显式删除树根目录下的原模块目录。结果树中存在两套并行的模块文件——一套在 `{existing-skill}/` 下（Multi-Skill 路由目标），一套在树根目录下（孤儿文件，不被任何路由引用）。不仅造成混乱，还可能导致 agent 误读孤儿文件而绕过正确的 Phase 1 路由。

**根源**: Step B2 的 "move" 步骤在实践中可能被执行为 "copy"（尤其当目标子目录已存在时），缺少显式的删除原目录步骤。

**预防**:
1. **Step B2 步骤 8 显式删除**: 转换完成后，必须删除树根目录下的原模块目录（`{module1}/`、`{module2}/` 等）
2. **验证检测**: Check 3 (Reachability) 会标记所有孤儿文件，转型后必须无孤儿文件
3. **删除前确认**: 在删除前确认 `{existing-skill}/` 子目录下的对应文件已完整迁移

## L14: 引用文件未内联/拷贝导致叶节点依赖外部源技能

**问题**: 源技能中引用了外部文件（如 `docs/`、`references/`、`scripts/`），生成器在叶节点中保留了指向源技能目录的外部路径（如 `.claude/skills/xxx/docs/...`），而不是将内容内联或拷贝到 tree 内。导致：
- 删除源技能后 tree 中的检索/参考路径全部失效
- tree 不是真正自包含的，违反了 自包含规则

**根源**: 生成器对所有引用一视同仁——没有区分"可内联的短内容"和"应拷贝的大文件集"。对于 `docs/` 这类大量文件，简单地保留了外部路径引用。

> **已制度化**: 本问题的预防措施已纳入 `references/error_handling.md` 的 Reference File Processing Flow。Step R1-R4 定义了量化标准（≤200行/≤10KB 内联，>5文件/>50KB 拷贝）和即时验证步骤。

## L15: 叶节点中"参考文档索引"段落未做路径替换或删除

**问题**: 叶节点生成后，从源技能复制过来的"参考文档索引"/"Reference Documents"段落仍保留了指向源技能 `references/` 目录的原始路径。这些文件在复制包中往往不存在，删除源技能后这些路径完全失效。更严重的是，这些段落给 agent 造成"还有更多详细信息在外部"的错觉，实际内容已经在叶节点中内联完毕。

**根源**: 生成器在拆分源技能内容到叶节点时，将"参考文档索引"段落原样复制，没有执行路径替换（指向 tree 内部副本）或删除（引用文件不存在）的决策。

> **已制度化**: 本问题的预防措施已纳入 `references/error_handling.md` 的 Step R3 (Post-Generation Cleanup)。R3.1 定义了完整的 Grep 模式库（中英文参考段落+外部指针短语+tree 外部路径），R3.2 定义了路径替换/删除/清理的三步处理逻辑。

## L16: Mode 2 skill-first 结构导致同领域下 skill 各自生成重复子节点

**问题**: Mode 2 聚合多个 skill 时，采用 skill-first 树结构（`{skill}/ROUTER.md → {capability}/SKILL.md`），以 skill 为第一级组织维度。当聚合同领域 skills（如 `--aggregate react,vue,svelte --domain frontend`）时，每个 skill 各自生成一套完整的子节点（state-management、component-creation、routing 等），导致：(1) 大量重复的同名子节点分散在不同 skill 目录下；(2) 用户按能力域查询时需要在多个 skill 子树间跳转；(3) `--domain` flag 只影响 ROOT.md 描述文本，未改变树结构。

**根源**: Mode 2 最初设计假设 skills 来自不同领域（如 web-dev + technical-writing + security-review），skill 作为第一级维度是合理的。但当 skills 来自同一领域时，能力域才应该是第一级维度。

**预防**:
1. **Domain-first 结构**: Mode 2 统一采用 `{domain}/ROUTER.md → {skill}/SKILL.md` 结构，能力域为第一级，skill 为第二级
2. **Skill 快速索引**: ROOT.md 包含 skill→能力域映射表，处理用户仅提 skill 名称（P1）无能力域（P2）的情况
3. **单 skill 域优化**: 仅一个 skill 具备的能力域无需 ROUTER.md，ROOT.md 直接路由到叶节点
