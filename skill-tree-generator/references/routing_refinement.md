# Routing Refinement Stage

第二阶段路由精修在基础 validation 全部通过后单独执行。它不是 coverage/content validation 的一部分，而是专门提高 `ROOT.md` / `ROUTER.md` 路由表准确性的后处理流程。

## 目标

逐层扫描 skill tree 中每一个 routing node，确保每个 sibling node 都有稳定、可解释、可复验的差异信号。检查必须遵循多路并行原则：由多个只读 subagent 分别执行独立检查、独立提出修改意见，最后由主 agent 通过汇审归并统一审定修复方案并修复路由表。当发现路由冲突、共享关键词误判、fallback 过宽或多意图吞并时，由主 agent 修复路由表并重新启动只读 subagent 复验。

## 执行边界

| 执行方 | 职责 | 禁止事项 |
|--------|------|----------|
| 主 agent | 启动多个并行 subagent、收集独立意见、执行汇审归并、修改 `ROOT.md` / `ROUTER.md` / `SKILL-TREE.md` / `GENERATION-REPORT.md`、调度复验 | 不得跳过失败项；不得让 subagent 修改文件；不得在汇审归并前直接套用单一路径意见 |
| subagent | tree-only/read-only 扫描 `ROOT.md`、所有 `ROUTER.md`、所有叶节点 `SKILL.md`、`SKILL-TREE.md` 和本文件；只执行分配给自己的检查路径并返回独立意见 | 不读源 skill、源 skill 引用文件、AGENTS.md、CLAUDE.md；不修改任何文件；不依赖其他 subagent 的结论 |

Multi-Skill 树中的 `shared/` 和 `cross-cutting/` 默认不是 sibling routing table。subagent 只在它们包含显式路由表时执行 R1-R4、R8 和 R9；否则只用于 R5 多意图路径保留、R6 目标路径有效性、R7 回归用例追踪和 R10 多意图依赖清晰度检查。

## 多路并行原则

Routing Refinement 必须拆成多个相互独立的只读检查路径。主 agent 可以按项目大小调整并行度，但默认至少启动以下 4 路：

| lane_id | 检查范围 | 关注重点 |
|---------|----------|----------|
| `lane-a-disambiguation` | R1、R2、R4、R9 | sibling 互斥性、共享关键词、唯一正向信号、冲突严重度 |
| `lane-b-fallback` | R3、R8 | fallback 边界、默认 leaf 是否过窄或过宽 |
| `lane-c-path-regression` | R6、R7 | route target 有效性、回归 prompt 矩阵、手动追踪路径 |
| `lane-d-multi-intent` | R5、R10 | 多意图路径保留、跨 domain/workflow 依赖边界 |

并行检查必须满足：

- 每个 lane 独立读取 tree 文件和本规则文件，独立返回 `pass/fail`、证据和 `recommended_fix`。
- lane 之间不得共享中间结论；主 agent 不得要求某个 lane 复述或服从另一个 lane 的意见。
- 同一文件、同一 sibling group 可以被多个 lane 检查；重复发现应保留到汇审归并阶段再去重。
- `recommended_fix` 只是修改意见，不是最终补丁。最终修改只能由主 agent 在汇审归并后执行。
- 如果环境无法真正并行启动 subagent，主 agent 可以顺序启动多个独立 subagent，但必须保持输入隔离、输出独立，并按汇审归并规则处理。

## 汇审归并规则

主 agent 在修改任何文件前必须执行汇审归并：

1. 收集所有 lane 输出，按 `file_path + sibling_group + check_id + ambiguous_signals` 建立 issue ledger。
2. 合并重复问题，保留所有 lane 的证据来源；若多个 lane 给出不同原因或修复建议，全部进入同一 issue 的 `evidence_sources`。
3. 按严重度排序：R6 路径无效、R1/R9 `fatal`、R5/R10 多意图吞并、R3/R8 fallback 吞并、R2/R4 信号不足、R7 回归用例失败。
4. 解决修复意见冲突：优先选择能同时满足更多 R1-R10 检查、最少改变 tree 结构、保留所有明确 route paths、不会扩大 fallback 的方案。
5. 形成统一修改计划，逐文件合并改动，避免同一 routing table 被不同建议反复覆盖。
6. 主 agent 执行修改后，必须重新启动独立只读 lane 复验。复验可只覆盖失败项及其相邻 sibling group；若修复影响 ROOT 或多意图规则，则必须同时复验 R5、R7 和 R10。

汇审归并不得把某一路的 `pass` 当成整体通过；只有所有 lane 的相关检查均为 pass，且归并后的 issue ledger 中没有未处理失败项，Routing Refinement 才能通过。

## 执行顺序

1. 主 agent 确认 tree 根目录和 tree 类型：`single` 或 `multi`。
2. 主 agent 根据“多路并行原则”启动多个新的 general-purpose subagent，分别传入本文件、tree 根目录、`lane_id` 和该 lane 的 `check_scope`。
3. 每个 subagent 扫描自己检查范围需要的 routing node：`ROOT.md` 和所有 `ROUTER.md`。如果 `shared/**/SKILL.md` 或 `cross-cutting/SKILL.md` 内包含显式 markdown routing table，也纳入 routing table inventory。
4. 每个 subagent 对相关 routing table 将同表 rows 视为 sibling group，比较判断条件、关键词信号、上下文规则和 fallback。
5. 每个 subagent 只执行自己 `check_scope` 内的 R 项，并返回结构化 pass/fail、证据和 recommended_fix；R7 lane 必须返回 regression prompt matrix。
6. 主 agent 等待所有 lane 返回，通过“汇审归并规则”建立 issue ledger、去重、解决冲突并形成统一修改计划。
7. 如果有失败项，主 agent 根据汇审归并后的统一计划修复相关路由表和报告证据。
8. 主 agent 启动新的只读 lane 复验失败项及其相邻 sibling group；复验仍必须独立返回意见，并再次经过汇审归并确认。
9. 所有 R1-R10 通过后，主 agent 将 refinement 结果写入或更新 `GENERATION-REPORT.md` 的 Routing Refinement section。该 section 独立于 validation section；最终完成声明必须同时具备 validation 和 refinement 两部分通过证据，并记录并行 lane 和汇审归并摘要。

## 完成声明约束

- 主 agent 必须等待所有 Routing Refinement lane 返回结果，并完成汇审归并、所有失败项修复和复验后，才可声明 Routing Refinement 通过。
- 在任何 refinement lane 仍在运行、汇审归并尚未完成、失败项尚未修复、或复验尚未通过时，不得输出 `The unified skill tree has been generated successfully`、`generated successfully` 或等价最终成功总结。
- 等待期间只能输出中间状态，例如：`Skill tree files have been generated; validation passed; waiting for Routing Refinement results.`
- 最终成功总结只能在 validation section 和 Routing Refinement section 都已写入 `GENERATION-REPORT.md` 且均为通过状态后输出；Routing Refinement section 必须包含 lane 结果摘要、归并 issue ledger 摘要和复验证据。

## Subagent Prompt

启动每个 general-purpose subagent 时，prompt 必须包含：

```text
你只执行 Routing Refinement Stage 的一个独立并行检查路径，tree-only/read-only。
输入：tree 根目录路径、tree 类型（single 或 multi）、lane_id、check_scope、routing_refinement.md 中与你 check_scope 对应的 R 项。
只读取 tree 目录下的 ROOT.md、ROUTER.md、SKILL.md、SKILL-TREE.md 和本检查定义。
不要读取源 skill、源 skill 引用文件、AGENTS.md 或 CLAUDE.md。
不要修改任何文件。
不要依赖其他 subagent 的结论；你的输出是独立意见，最终修改由主 agent 汇审归并后执行。
必须扫描每一层的每一个 routing node：ROOT.md 和所有 ROUTER.md。若 shared/**/SKILL.md 或 cross-cutting/SKILL.md 内包含显式 markdown routing table，也纳入 routing table inventory。
对每个 routing table，将同表 rows 视为 sibling group，并比较它们的判断条件、关键词信号、上下文规则和 fallback。
Multi-Skill 树中的 shared/ 和 cross-cutting/ 只有在包含显式路由表时才作为 sibling group 检查；否则仅用于多意图路径和目标路径验证。
只逐项返回 check_scope 内的 pass/fail。失败项使用结构化格式：lane_id、check_id、status、severity、file_path、sibling_group、ambiguous_signals、reason、recommended_fix、evidence。
R7 lane 必须额外返回 regression prompt matrix：prompt、expected_route_path、actual_or_manual_trace、status。
```

## R1: Sibling Mutual Exclusivity

**执行方**: subagent（tree-only）

- 对 routing table inventory 中的每个表比较所有 sibling rows。Inventory 包括 `ROOT.md`、所有 `ROUTER.md`，以及 `shared/**/SKILL.md` / `cross-cutting/SKILL.md` 中显式定义的 markdown routing table。
- 找出重叠条件、同义词重复、过宽类别、顺序依赖但未说明优先级的规则。

**通过标准**: 每个 sibling row 具备互斥条件，或明确写出冲突时的优先级/上下文消歧方式。

## R2: High-Frequency Shared Keyword Handling

**执行方**: subagent（tree-only）

逐项检查以下高频共享词是否被正确消歧：

- `create` / `新建` / `生成`
- `export` / `导出` / `渲染`
- `list` / `info` / `查询` / `查看`
- `config` / `配置` / `设置`
- `test` / `测试` / `验证`

同时检查当前 sibling group 中实际重复出现的领域词、文件类型、对象名、命令名和同义词。若某个词在两个或更多 sibling rows 中出现，它也必须按共享词处理。

**通过标准**: 高频词和动态发现的共享词不能单独决定 sibling 路由；必须结合 Skill 名称、唯一领域词、文件类型、上下文或询问用户策略。

## R3: Fallback Quality

**执行方**: subagent（tree-only）

- 检查 `其他/未明确`、`default`、`general` 等 fallback 是否过宽。
- 检查 fallback 是否会吞掉可通过唯一信号区分的任务。
- 检查 fallback 行是否说明何时询问用户、何时进入通用 leaf。

**通过标准**: fallback 只处理真实未明确场景；不能覆盖已有明确 sibling 信号。

## R4: Unique Positive Signals

**执行方**: subagent（tree-only）

- 每个 sibling row 必须有至少一个正向唯一信号，或有明确的上下文消歧规则。
- 不能只依赖否定条件、宽泛动词或同层共享词。
- Fallback row 不要求唯一正向信号；若它满足 R3，并明确说明进入条件、询问用户策略或通用 leaf 使用边界，则通过 R4。

**通过标准**: 对每个非 fallback sibling，subagent 能构造一个只命中该 sibling 的 prompt；fallback row 能构造一个真实未明确且不会覆盖其他唯一信号的 prompt。

## R5: Multi-Intent Path Preservation

**执行方**: subagent（tree-only；Multi-Skill 必跑；Single-Skill 若支持多 leaf 并行也应检查）

Single-Skill 是否支持多 leaf 并行，由 tree 内证据判断：`ROOT.md` / `ROUTER.md` 明确写有拆分独立子任务、同时读取多个叶节点、保留多个命中路径，或 routing table 中存在可并行执行的多目标规则。没有这些证据时，Single-Skill 的 R5 只需确认单意图优先级不会吞掉明确路由。

- 检查 `ROOT.md` 是否要求拆分独立子任务并保留所有命中路径。
- Multi-Skill：构造包含多个 skill 名称、多个唯一领域词、共享能力 + 专属能力的 prompt。
- Single-Skill：若 tree 内证据显示支持多 leaf 并行，构造包含多个 capability、多个 leaf 或多个模块意图的 prompt；否则只检查单意图优先级不会吞掉明确路由。
- 确认信号优先级只在单个子任务内部消歧，不会丢弃其他明确意图。

**通过标准**:
- Multi-Skill：多意图 prompt 保留所有预期 Skill/leaf/shared route paths；只有存在数据依赖或执行顺序要求时才进入 `cross-cutting/SKILL.md` 编排。
- Single-Skill 且支持多 leaf 并行：多意图 prompt 保留所有预期 leaf route paths，优先级只用于单个子任务内部消歧。
- Single-Skill 且不支持多 leaf 并行：单意图 prompt 不会被优先级、fallback 或宽泛共享词吞掉明确路由；发现多个独立意图时必须询问用户、说明一次只处理一个 leaf，或有明确的串行处理策略。

## R6: Route Target and Path Validity

**执行方**: subagent（tree-only）

- 检查所有 `Read ...ROUTER.md` 和 `Read ...SKILL.md` 目标存在，覆盖相对路径、tree 内路径，以及 agent skill-dir 风格路径（如 `{skills-dir}/{skill-tree}/...`）。
- 检查目标类型正确：非叶节点应指向 `ROUTER.md`，叶节点应指向包含 `[LEAF NODE]` 的 `SKILL.md`。
- 检查 sibling group 是否引用重复目标、过期目标或移动后残留路径。

**通过标准**: 每个 route target 都能解析到 tree 内实际文件，且类型与路由层级一致。

## R7: Regression Prompt Matrix

**执行方**: subagent（tree-only）

对每个 sibling group 构造最小回归用例：

1. 每个 sibling 至少 1 个唯一命中 prompt。
2. 每个共享/高频词至少 1 个冲突 prompt。
3. 每个 fallback 至少 1 个未明确 prompt。
4. Multi-Skill tree 至少 3 个多意图 prompt，对应 validation 的 M5 场景。

每个用例必须记录 `prompt`、`expected_route_path`、`actual_or_manual_trace` 和 `status`。`actual_or_manual_trace` 应逐层列出 ROOT → ROUTER → SKILL 的追踪过程；多路径场景必须列出所有保留路径。

**通过标准**: 所有 regression prompts 都能手动追踪到预期 route path；失败时必须指出具体文件、sibling group、冲突信号和建议修复方向。

## R8: Fallback Specificity Check

**执行方**: subagent（tree-only）

- 检查每个 routing table 的 fallback row 是否默认指向某个过于具体的 leaf。
- 如果一个 router 有多个 sibling leaf，且 fallback 直接 `Read` 其中某个具体 leaf，则必须确认该 leaf 在路由表或 sibling 差异说明中被明确标注为 `canonical`、`default`、`general-purpose` 或等价通用入口。
- 如果没有明确默认能力，fallback 应询问用户补充需求，并列出当前 router 的主要可选能力或能力类别。
- 对只有 2 个 sibling 的 router 也要执行该检查；leaf 数量越多，默认落到单个具体 leaf 的误路由风险越高。

**通过标准**: fallback 不会把模糊请求静默路由到具体 leaf；若存在默认 leaf，其默认边界必须写清楚，并能解释为什么其他 sibling 不适合处理未明确请求。

## R9: Shared Keyword Collision Severity

**执行方**: subagent（tree-only）

- 在 R2 动态发现共享词的基础上，对 sibling keyword collision 进行严重程度分级，而不只返回 pass/fail。
- 分级标准：
  - `fatal`: 两个或更多 sibling 只有共享词，没有足够 unique signal，或常见 prompt 无法稳定区分。
  - `degraded`: 两个或更多 sibling 共享高权重核心词，但仍存在部分 unique signal；典型用户短 prompt 可能误路由。
  - `warning`: 共享词存在，但路由表已提供清晰上下文、优先级或消歧说明，误路由风险较低。
- 高权重核心词包括用户可能直接输入的动作词、对象词、文件类型、工具名、领域实体和常见中文/英文同义词。
- 对 `fatal` 和 `degraded`，recommended_fix 必须建议增加限定词、拆分语义、调整优先级、增加 ask-user fallback，或在 sibling 差异说明中补充冲突处理。

**通过标准**: 所有共享词冲突都有 severity；`fatal` 必须 fail，`degraded` 默认 fail，除非同表已有明确且可执行的消歧规则；`warning` 可 pass 但必须记录原因。

## R10: Multi-Intent Dependency Clarity

**执行方**: subagent（tree-only；Multi-Skill 必跑；Single-Skill 若支持多 leaf 并行也应检查）

- 检查 `ROOT.md`、`cross-cutting/SKILL.md` 和任何显式多意图 routing table 是否区分：
  - 独立多意图：多个子任务可并行或分别执行，没有输入输出依赖。
  - 有依赖多意图：一个子任务的输出是另一个子任务的输入。
  - 顺序 workflow：需要按步骤编排、聚合结果、转换格式或跨 domain 串联。
- 多意图规则中不得使用无条件的 `or` / `或` / `either` 在 “读取所有 matched routes” 和 “进入 cross-cutting/workflow” 之间摇摆；如果使用，必须说明触发条件。
- 当 prompt 同时命中多个 domain 或多个 leaf 时，路由说明必须写明何时保留所有 matched paths、何时额外读取 `cross-cutting/SKILL.md`，以及是否仍保留原 domain/leaf paths。

**通过标准**: subagent 能为独立多意图和有依赖 workflow 各构造至少 1 个 prompt，并手动追踪到不同、明确且不互相吞并的 route path。

## 输出格式

每个 subagent lane 必须返回：

```markdown
## Routing Refinement Result

| lane_id | check_id | status | severity | file_path | sibling_group | ambiguous_signals | reason | recommended_fix | evidence |
|---------|----------|--------|----------|-----------|---------------|-------------------|--------|-----------------|----------|
| lane-a-disambiguation | R1 | pass/fail | fatal/degraded/warning/none | ROOT.md | row labels / targets | create, 新建 | ... | ... | ... |

## Regression Prompt Matrix

| prompt | expected_route_path | actual_or_manual_trace | status |
|--------|---------------------|------------------------|--------|
| ... | ROOT.md -> module/ROUTER.md -> leaf/SKILL.md | ROOT row ... -> ROUTER row ... | pass/fail |
```

主 agent 汇审归并后必须在 `GENERATION-REPORT.md` 的 Routing Refinement section 记录：

```markdown
## Routing Refinement Consolidation Review

| issue_id | source_lanes | status | severity | file_path | sibling_group | merged_reason | merged_fix |
|----------|--------------|--------|----------|-----------|---------------|---------------|------------|
| RR-001 | lane-a-disambiguation, lane-c-path-regression | fixed/pass | fatal | ROOT.md | ... | ... | ... |
```

## 总通过标准

R1-R10 全部通过；每个 lane 均返回通过状态；归并后的 issue ledger 中没有未处理失败项；每个 sibling group 都能用唯一信号、上下文优先级、显式消歧或询问用户策略稳定地区分；fallback 不静默吞掉模糊请求；多意图与跨 domain workflow 的依赖边界清晰可追踪。
