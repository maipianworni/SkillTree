# Contributing to Skill Tree Generator

Thanks for your interest! This is a **research preview**, so the most valuable
contributions right now are real-world feedback, routing edge cases, and improvements
to the generator's rules.

[English](#english) · [中文](#中文)

---

## English

### Ways to contribute

- 🐛 **Report a routing bug** — a prompt that routed to the wrong (or no) leaf. Include the
  prompt, the expected leaf, and what actually fired (turn on trace by adding `debug routing`).
- 💡 **Improve the spec** — the generator's behavior lives in
  [`skill-tree-generator/SKILL.md`](skill-tree-generator/SKILL.md) and the templates under
  [`skill-tree-generator/references/`](skill-tree-generator/references/).
- 📚 **Capture a lesson** — recurring pitfalls belong in
  [`references/lessons_learned.md`](skill-tree-generator/references/lessons_learned.md)
  (root cause + prevention), the same format as the existing 16 entries.
- 🔌 **Add agent support** — extend `scripts/aggregate-skills.sh` (the `--agent` cases) and
  document the new skills dir / memory file in both READMEs.

### Before you open a PR

1. **Keep facts in sync.** Any command or path you change must match across
   `scripts/aggregate-skills.sh`, `README.md`, and `README.zh.md`.
2. **Test the script** end to end:
   ```bash
   ./scripts/aggregate-skills.sh .claude/skills            # or your agent's dir + --agent
   ```
   Then run the printed `/skill-tree-generator …` command in your agent and confirm the tree
   builds and routes as expected.
3. **No fabricated behavior.** Don't document features or numbers the generator doesn't produce.
4. **Update both READMEs** when user-facing behavior changes — English (`README.md`) is the
   primary, Chinese (`README.zh.md`) mirrors it.

### Commit & PR conventions

- Keep commits focused and messages descriptive (the existing history uses short imperative
  summaries, e.g. `fix leaf node cut off`).
- Describe *what changed and why* in the PR, and link any related routing edge case.

---

## 中文

### 可以贡献什么

- 🐛 **报告路由 bug** —— 某个 prompt 路由到了错误的叶子（或没命中）。请附上 prompt、
  期望的叶子、以及实际触发的节点（在 prompt 里加 `路由追踪` 可打开 trace）。
- 💡 **改进规范** —— generator 的行为定义在
  [`skill-tree-generator/SKILL.md`](skill-tree-generator/SKILL.md)
  和 [`skill-tree-generator/references/`](skill-tree-generator/references/) 下的模板里。
- 📚 **记录一条 lesson** —— 反复出现的坑请写进
  [`references/lessons_learned.md`](skill-tree-generator/references/lessons_learned.md)
  （根因 + 预防措施），格式与现有 16 条保持一致。
- 🔌 **新增 agent 支持** —— 扩展 `scripts/aggregate-skills.sh` 的 `--agent` 分支，
  并在两份 README 中补充新的 skills 目录 / 记忆文件。

### 提 PR 之前

1. **保持事实一致。** 你改动的任何命令或路径，必须在
   `scripts/aggregate-skills.sh`、`README.md`、`README.zh.md` 之间保持一致。
2. **端到端测试脚本：**
   ```bash
   ./scripts/aggregate-skills.sh .claude/skills            # 或你的 agent 目录 + --agent
   ```
   然后在你的 agent 里运行打印出的 `/skill-tree-generator …` 命令，确认树能正常生成与路由。
3. **不要杜撰行为。** 不要记录 generator 实际不产出的功能或数字。
4. **同步更新两份 README** —— 英文（`README.md`）为主，中文（`README.zh.md`）镜像。

### 提交与 PR 约定

- commit 聚焦、信息清晰（现有历史使用简短的祈使句，如 `fix leaf node cut off`）。
- 在 PR 中说明*改了什么、为什么*，并关联相关的路由边界情况。
