# ROUTER.md Template

This template defines the routing logic for non-leaf nodes in a skill-tree.

---

## Template

```markdown
# {Module Name} Router [Ln]

你已到达 {module} 子树。基于当前任务进一步判断：

| 判断条件 | 下一跳 |
|---------|--------|
| {condition1} | Read `./{path1}/ROUTER.md` |
| {condition2} | Read `./{path2}/SKILL.md` |
| {condition3} | Read `./{path3}/SKILL.md` |
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

| 判断条件 | 下一跳 |
|---------|--------|
| 涉及 React/JSX/组件/hooks | Read `./react/SKILL.md` |
| 涉及 Vue/Composition API | Read `./vue/SKILL.md` |
| 涉及 CSS/样式/动画 | Read `./css/SKILL.md` |
| 涉及 TypeScript/类型 | Read `./typescript/SKILL.md` |
| 涉及 测试/Jest/Cypress | Read `./testing/SKILL.md` |
| 其他/通用前端 | Read `./general/SKILL.md` |

注意：如果当前对话中用户已明确说明前端技术栈，优先以对话上下文为准。
```

---

## Best Practices

1. **Mutual Exclusivity**: Conditions should not overlap significantly
2. **Coverage**: Every possible input should match at least one condition
3. **Specificity**: Order conditions from most specific to most general
4. **Brevity**: Keep conditions concise but unambiguous
5. **Context First**: Always mention conversation context priority
