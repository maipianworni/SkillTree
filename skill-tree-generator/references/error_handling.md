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

## Atomicity Guarantees

- 在创建/修改 tree 目录结构之前，先完成所有内容生成（在内存或临时位置）
- 如果文件系统操作（拷贝大目录等）失败，报错并清理已生成的临时文件，不保留半成品 tree

---

## Reference File Processing Flow

**"源技能包"定义**: 以源技能 SKILL.md 所在目录为根目录的整个目录树。例如 `.claude/skills/my-skill/` 下的所有文件（含子目录）。

### Step R1: Inventory External References

对源技能内容中每个被引用的外部文件/目录：

1. 以源技能 SKILL.md 所在目录为基准解析相对路径
2. 使用 Glob 确认文件/目录是否存在
3. 存在于源技能包中 → 继续 Step R2
4. 不存在于源技能包中 → 标记为"不可用"

### Step R2: Decide Handling Strategy

| 引用类型 | 量化标准 | 处理方式 |
|---------|---------|---------|
| 短文件 | ≤ 200 行 **且** ≤ 10KB | 内联完整内容到叶节点中 |
| 中等文件集 | 2-5 个文件，每个 > 200 行 | 逐个评估：优先内联，总行数 > 800 行时可拷贝到 tree 内 |
| 大文件集 | > 5 个文件 **或** 总大小 > 50KB | 拷贝整个目录到 tree 内对应位置（如 `{skill}/docs/`），叶节点中使用 tree 内部相对路径（`../docs/` 或 `./docs/`） |
| 不可用 | 文件在源技能包中不存在 | 删除引用条目，替换为可直接执行的自包含指令（如用 Grep/Read 替代脚本调用，用内联数据替代外部 JSON 文件） |

**混合场景**: 如果源技能同时包含短文件引用和大文件集引用，分别按各自标准处理。

### Step R3: Post-Generation Cleanup

所有叶节点生成完毕后，执行以下扫描和清理：

**R3.1 Scan for residual references** — Grep 所有叶节点中以下模式（不区分大小写）：

| 类别 | Grep 模式 |
|------|----------|
| 中文参考段落 | `参考文档索引`、`参考资料`、`相关文档`、`扩展阅读` |
| 英文参考段落 | `Reference Documents`、`References`、`See Also`、`Further Reading`、`Related Documents`、`External References` |
| 外部指针短语 | `For more details, see`、`Additional resources`、`Refer to`、`See {path}`、`Read {path}`、`Full Instructions: Read`、`Read the skill at` |
| tree 外部绝对路径 | `\.claude/skills/(?!.*-tree/)`（匹配 `.claude/skills/xxx/` 但不匹配 `.claude/skills/xxx-tree/`） |

**R3.2 Three-step handling per reference entry**：

- 文件已拷贝到 tree 内 → 路径替换为 tree 内部相对路径
- 内容已内联到叶节点 → 删除该引用条目（内容已在叶节点中）
- 文件在源技能包中不存在 → 删除整个参考段落

**R3.3 External path replacement** — Grep 所有叶节点中指向 tree 外部的绝对路径，全部替换为 tree 内部相对路径或删除。

### Step R4: Immediate Validation

在进入各模式的 Step 6 / Step D / 最终输出之前，**必须**执行以下检查（不必等到最终验证阶段）：

1. **存根检测**: Grep 所有新生成的叶节点，确认不包含 Step R3.1 中列出的存根/外部指针模式
2. **外部路径检测**: Grep 所有新生成的叶节点，确认不包含指向 tree 外部的绝对路径
3. 如果命中 → 立即修复，修复后重新检测
4. 只有通过后才继续后续步骤

---

## Self-Containment Rule [MANDATORY]

每个叶节点必须完全自包含，无论包含的是可执行指令还是参考数据。绝对禁止创建只包含摘要和指向外部文件指针的存根文件。仅加载 tree 的 agent 必须具备执行所需的一切。包括：

- 含 Min/Max 范围和换算系数的特性字典
- API 端点规格，含端点地址、参数和响应格式
- 枚举值、查找表、分类编码
- 可执行的工作流步骤、代码示例和使用模式
- 原始技能中包含或引用的任何数据

如果原始技能引用了外部文件，读取该文件并将其内容内联到对应的叶节点中。不得保留"见文件 X"类引用。
