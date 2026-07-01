# ROUTER.md Template

This template defines the routing logic for non-leaf nodes in a skill-tree.

---

## Template

```markdown
# {Module Name} Router [Ln]

你已到达 {module} 子树。基于当前任务进一步判断：

## 路由规则 [MANDATORY]

- 先使用当前对话上下文、用户明确提到的对象/文件/平台/目标，再匹配关键词。
- 路由条件必须从最具体到最通用排序；`其他/未明确` 必须放在最后。
- 如果一个用户请求自然需要多个叶子能力，必须读取所有匹配叶子，不要退回到 `其他/未明确`。
- 每个条件必须包含用户会说的意图词、操作对象、文件类型、平台、产物或成功标准；不要只写内部技能名。
- 代表性关键词用于语义召回，不是穷举清单；用户使用同义词、口语或业务目标描述时，也应按真实任务目标路由。
- 只有没有任何具体条件匹配时，才使用 `其他/未明确`。

| 判断条件 | 下一跳 |
|---------|--------|
| {condition1} | Read `./{path1}/ROUTER.md` |
| {condition2} | Read `./{path2}/SKILL.md` |
| {condition3} | Read `./{path3}/SKILL.md` |
| {condition requiring multiple capabilities} | Read `./{pathA}/SKILL.md` and Read `./{pathB}/SKILL.md` |
| 其他/未明确 | Read `./{default}/SKILL.md` |

注意：如果当前对话中用户已明确说明{context_hint}，优先以对话上下文为准。

**路由追踪**：当追踪模式激活时，输出 `[Route]   → <匹配的能力> [LEAF]`。若匹配多个则每个输出一行。
```

---

## Level Markers

- `[L1]` - First level below ROOT
- `[L2]` - Second level
- `[L3]` - Third level
- etc.

---

## Routing Requirements [MANDATORY]

Treat these as acceptance criteria for every generated `ROUTER.md`. If any criterion fails, revise the routing table before writing the file.

1. **Context First**: The generated router must explicitly say that conversation context and user-stated objects, files, platforms, and goals take priority over keyword-only matching.
2. **Specificity Order**: Conditions must be ordered from most specific to most general. The fallback row (`其他/未明确`, `其他/通用`, or equivalent) must be last.
3. **Signal-Rich Conditions**: Each non-fallback condition must include enough user-facing signals to be matched reliably: intent words, artifacts/inputs, file types, services/platforms, expected outcomes, or success criteria. Do not use only source skill names, product/API names, or internal implementation terms.
4. **Boundary Clarity**: Nearby sibling rows must be distinguishable. When two rows overlap, add concrete disambiguating signals instead of leaving broad ambiguous conditions.
5. **Coverage**: Every likely request should match at least one specific row or the explicit fallback row. Do not rely on a vague fallback when a source skill contains clear trigger signals.
6. **Multi-Match Preservation**: If one user request naturally requires multiple leaf capabilities, route to all of them with `Read ... and Read ...`; do not collapse to `其他/通用` or choose only one leaf just because no single leaf fully covers the task.
7. **Brevity With Precision**: Conditions should be concise, but never so short that they lose the signals needed for reliable routing.

### Pre-Write Router Checklist [MANDATORY]

Before writing each generated `ROUTER.md`, verify:

- The fallback row is present and last.
- At least one condition uses concrete signals extracted from each child skill/router.
- Every non-fallback row includes at least one natural-language signal a user might say; technical terms are supplemental unless they are the only valid invocation form.
- Broad rows such as `创建/修改/删除`, `其他`, or `通用` do not appear before more specific rows.
- Any obvious end-to-end task spanning multiple sibling leaves has an explicit multi-read row.
- No row points to a child merely because its directory name sounds related; the condition must be supported by source skill content or examples.

---

## Routing Conditions Guidelines

### Condition Types

1. **Keyword Matching**
   ```
   | 涉及 React/Vue/DOM | Read `./frontend/ROUTER.md` |
   ```

2. **Task Pattern**
   ```
   | 创建/新建/生成 | Read `./create/SKILL.md` |
   | 修改/编辑/更新 | Read `./edit/SKILL.md` |
   | 删除/移除 | Read `./delete/SKILL.md` |
   ```

3. **Domain Terminology**
   ```
   | API/REST/GraphQL | Read `./api/SKILL.md` |
   | 数据库/SQL/NoSQL | Read `./database/SKILL.md` |
   ```

4. **File Type**
   ```
   | .tsx/.jsx 文件 | Read `./react/SKILL.md` |
   | .css/.scss/.less | Read `./css/SKILL.md` |
   ```

### Condition Composition

- **Single keyword**: `React`
- **Multiple keywords (OR)**: `React/Vue/DOM`
- **Pattern**: `创建/新建/生成`
- **Negation**: Avoid using; prefer positive conditions

### Signal Adequacy for Generated Routers

When generating a ROUTER.md from source skills, do not only copy the source skill names or internal implementation terms. Expand each row with signals extracted from the source skill and its examples. Every non-fallback row must contain at least one natural-language, user-facing signal; technical terms and product/API names are useful supplements, but they must not be the only signals unless the skill is only invoked by that exact name.

- **User-facing intent words**: verbs and nouns users are likely to say when requesting the capability.
- **Artifacts and inputs**: file types, data types, services, platforms, resources, or objects the skill operates on.
- **Expected outcomes**: deliverables, visible results, state changes, or success criteria produced by the skill.
- **Implicit prerequisites**: supporting capabilities that are normally required to satisfy the outcome, even if users do not name them directly.
- **Negative boundaries**: concise conditions that distinguish nearby sibling leaves when the source skill explicitly excludes a scenario.

When a source example contains a very specific business scenario, generalize the signal to the reusable user need. For example, use "multi-user permission management" rather than a one-off sample app name, unless that sample name is itself a common domain term.

For prompts that imply several sibling capabilities, add a multi-match row that explicitly says to read every matched leaf instead of falling back to a generic handler.

Template:

```markdown
| {end-to-end user outcome requiring capability A + capability B} | Read `./{capability-a}/SKILL.md` and Read `./{capability-b}/SKILL.md` |
```

---

## Path References

| Reference Type | Syntax | Example |
|---------------|--------|---------|
| Sub-router | `./{dir}/ROUTER.md` | `./frontend/ROUTER.md` |
| Leaf skill | `./{dir}/SKILL.md` | `./react/SKILL.md` |
| Parent level | `../ROUTER.md` | (rarely used) |

---

## Context Hints

The `{context_hint}` should guide the router to consider relevant conversation context:

| Module Type | Context Hint Example |
|-------------|---------------------|
| Frontend | `技术栈(React/Vue/etc.)` |
| Backend | `后端语言/框架` |
| Database | `数据库类型` |
| DevOps | `部署环境` |
| Writing | `文档类型/目标读者` |

---

## Complete Example

```markdown
# Frontend Router [L2]

你已到达 frontend 子树。基于当前任务进一步判断：

## 路由规则 [MANDATORY]

- 先使用当前对话上下文、用户明确提到的对象/文件/平台/目标，再匹配关键词。
- 路由条件必须从最具体到最通用排序；`其他/通用前端` 必须放在最后。
- 如果一个用户请求自然需要多个叶子能力，必须读取所有匹配叶子，不要退回到 `其他/通用前端`。
- 每个条件必须包含用户会说的意图词、操作对象、文件类型、平台、产物或成功标准；不要只写内部技能名。
- 代表性关键词用于语义召回，不是穷举清单；用户使用同义词、口语或业务目标描述时，也应按真实任务目标路由。
- 只有没有任何具体条件匹配时，才使用 `其他/通用前端`。

| 判断条件 | 下一跳 |
|---------|--------|
| 涉及 React/JSX/组件/hooks | Read `./react/SKILL.md` |
| 涉及 Vue/Composition API | Read `./vue/SKILL.md` |
| 涉及 CSS/样式/动画 | Read `./css/SKILL.md` |
| 涉及 TypeScript/类型 | Read `./typescript/SKILL.md` |
| 涉及 测试/Jest/Cypress | Read `./testing/SKILL.md` |
| 涉及 React/组件/hooks 且需要类型定义/接口/泛型 | Read `./react/SKILL.md` and Read `./typescript/SKILL.md` |
| 其他/通用前端 | Read `./general/SKILL.md` |

注意：如果当前对话中用户已明确说明前端技术栈，优先以对话上下文为准。
```

