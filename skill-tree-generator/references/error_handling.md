# Error Handling & Reference File Processing (Unified Specification)

本节规则适用于 Mode 1/2/3 的所有生成操作。

## Error Severity & Handling Strategy

| 级别 | 触发条件 | 处理方式 |
|------|---------|---------|
| **Fatal** | 源技能文件不存在（路径无效或无 SKILL.md） | 立即报错终止，列出所有缺失的技能路径 |
| **Fatal** | 源技能文件存在但内容为空（0 字节或无有效指令内容） | 立即报错终止 |
| **Degraded** | 源技能存在，但某个子能力/子章节的内容不可获取（如解析出的子模块在原技能中找不到对应段落） | 生成带 `[AUTO-GENERATED FALLBACK - NO SOURCE CONTENT]` 标记的回退叶节点，包含基于上下文推断的最小可执行指令。**禁止**生成仅含标题+摘要+外部链接的存根 |
| **Warning** | 源技能中引用的某个外部文件在源技能包中不存在 | 删除该引用条目，替换为可直接执行的自包含指令（如用 Grep/Read 替代脚本调用），继续生成 |

**Fatal 与 Degraded 的边界**: 源技能**整体**不可用（文件不存在/全空）→ Fatal。源技能**整体可用**但**局部内容**缺失 → Degraded。

**Degraded 比例阈值**: 如果 Degraded 叶节点数量超过叶节点总数的 30%，在继续前发出警告，列出受影响节点让用户确认。

**生成时 vs 运行时边界**: 源技能路径只允许作为生成时输入和 `GENERATION-REPORT.md` 审计记录。叶节点不得把源技能路径作为运行时执行步骤、"完整指令"入口或备用说明来源。生成后的 tree 必须能在源技能目录被删除、移动或不可访问时继续执行。

## Atomicity Guarantees

- 在创建/修改 tree 目录结构之前，先完成所有内容生成（在内存或临时位置）
- 拷贝大目录（>5 files 或 >50KB）时优先使用平台原生命令：Unix/macOS 使用 `cp -a`（`cp -r` 仅作 fallback），Windows 使用 `robocopy`。禁止用 Write 工具逐文件拷贝；`xcopy /E /I` 仅在 `robocopy` 不可用时作为最后 fallback
- 大目录拷贝必须采用 staging 策略：先拷贝到 tree 内或临时位置的全新 staging 目录，校验成功后再替换/移动到最终目标目录；不得直接覆盖最终目标目录
- Windows 下 `robocopy` 返回码 `< 8` 视为成功，`>= 8` 视为失败；不得按“非 0 即失败”判断 `robocopy`
- 如果文件系统操作（拷贝大目录、替换目标目录等）失败，报错并清理本次生成的 staging/临时文件，不保留半成品 tree
- 替换已存在目标目录前，必须避免混入旧文件：使用全新 staging 目录生成完整内容，校验后替换目标目录，或显式删除目标中不属于本次输出 manifest 的旧文件

---

## Reference File Processing Flow

**"源技能包"定义**: 以源技能 SKILL.md 所在目录为根目录的整个目录树。例如 `.claude/skills/my-skill/` 下的所有文件（含子目录）。

### Step R1: Inventory External References

对源技能内容中每个被引用的外部文件/目录：

1. 以源技能 SKILL.md 所在目录为基准解析相对路径
2. 使用 Glob 确认文件/目录是否存在
3. 对每个命中的文件/目录解析真实路径（resolve absolute/canonical path），确认其仍位于源技能包根目录内；禁止通过 `..`、符号链接、junction 或绝对路径引入源技能包外部内容
4. 存在且真实路径位于源技能包中 → 继续 Step R2
5. 不存在或真实路径逃逸到源技能包外 → 标记为"不可用"

### Step R2: Decide Handling Strategy

| 引用类型 | 量化标准 | 处理方式 |
|---------|---------|---------|
| 短文件 | ≤ 200 行 **且** ≤ 10KB | 内联完整内容到叶节点中 |
| 中等文件集 | 2-5 个文件，每个 > 200 行 | 逐个评估：优先内联，总行数 > 800 行时可拷贝到 tree 内 |
| 大文件集 | > 5 个文件 **或** 总大小 > 50KB | **使用 staging + 平台原生命令拷贝整个目录**到 tree 内对应位置（如 `{skill}/docs/`）：Unix/macOS 优先 `cp -a`，Windows 优先 `robocopy`，`xcopy /E /I` 仅作最后 fallback。**禁止用 Write 工具逐文件拷贝**。叶节点中可使用 tree 内部相对路径（`../docs/` 或 `./docs/`） |
| 不可用 | 文件在源技能包中不存在 | 删除引用条目，替换为可直接执行的自包含指令（如用 Grep/Read 替代脚本调用，用内联数据替代外部 JSON 文件） |

**混合场景**: 如果源技能同时包含短文件引用和大文件集引用，分别按各自标准处理。

**拷贝过滤规则**: 拷贝目录时默认排除 `.git/`、`.svn/`、`.hg/`、`node_modules/`、`dist/`、`build/`、`coverage/`、缓存目录、临时文件、`.DS_Store`、`Thumbs.db`、`.env`、`.env.*`、密钥/证书文件（如 `*.pem`、`*.key`）。只有源技能明确要求且不含敏感信息时，才可有意纳入被排除类型。

**拷贝校验规则**: staging 目录生成后，至少校验文件数量、总大小、关键入口文件存在性，以及目标引用路径可从叶节点相对访问。校验失败必须清理 staging 并报错，不得继续生成。

### Step R3: Post-Generation Cleanup

所有叶节点生成完毕后，执行以下扫描和清理：

**R3.1 Scan for residual references** — Grep 所有叶节点中以下模式（不区分大小写）：

| 类别 | Grep 模式 |
|------|----------|
| 中文参考段落 | `参考文档索引`、`参考资料`、`相关文档`、`扩展阅读` |
| 英文参考段落 | `Reference Documents`、`References`、`See Also`、`Further Reading`、`Related Documents`、`External References` |
| 外部指针短语 | `For more details, see`、`Additional resources`、`Refer to`、`See {path}`、`Read {path}`、`Full Instructions: Read`、`Read the skill at` |
| tree 外部绝对路径 | `(\.claude|\.agent|\.openclaw)/skills/(?!.*-tree/)|~/.openclaw/workspace/skills/|~/core_skills/|~/openclaw/node_modules/openclaw/skills/`（匹配常见 agent 源 skill 目录，但不匹配 tree 内部相对路径） |

**R3.2 Three-step handling per reference entry**：

- 文件已拷贝到 tree 内 → 路径替换为 tree 内部相对路径
- 内容已内联到叶节点 → 删除该引用条目（内容已在叶节点中）
- 文件在源技能包中不存在 → 删除整个参考段落

**R3.3 External path replacement** — Grep 所有叶节点中指向 tree 外部的绝对路径，全部替换为 tree 内部相对路径或删除。

### Step R4: Immediate Validation

在完成叶节点生成后、进入输出结构创建或后续路由/报告步骤之前，**必须**执行以下检查（不必等到最终验证阶段）：

1. **存根检测**: Grep 所有新生成的叶节点，确认不包含 Step R3.1 中列出的存根/外部指针模式
2. **外部路径检测**: Grep 所有新生成的叶节点，确认不包含指向 tree 外部的绝对路径、用户目录路径或 agent 源 skill 目录
3. 如果命中 → 立即修复，修复后重新检测
4. 只有通过后才继续后续步骤

---

## Self-Containment Rule [MANDATORY]

skill tree 必须整体自包含，完全独立于源技能包和 tree 外部路径。叶节点应优先内联执行所需内容；当引用属于 Step R2 定义的大文件集时，允许叶节点引用已拷贝到同一 tree 内的相对路径。绝对禁止创建只包含摘要和指向 tree 外部文件指针的存根文件。仅加载 tree 的 agent 必须具备执行所需的一切。包括：

- 含 Min/Max 范围和换算系数的特性字典
- API 端点规格，含端点地址、参数和响应格式
- 枚举值、查找表、分类编码
- 可执行的工作流步骤、代码示例和使用模式
- 原始技能中包含或引用的任何数据

如果原始技能引用了外部文件，按 Step R2 决定内联或拷贝到 tree 内。短文件必须内联到对应叶节点中；大文件集可拷贝到 tree 内并使用 tree 内部相对路径引用。不得保留指向源技能包或其他 tree 外部位置的"见文件 X"类引用，也不得出现"读取源 skill 获取完整指令"这类运行时依赖。
