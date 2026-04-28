# SKILL-TREE.md Overview Template

> 本模板用于生成树目录下的 `SKILL-TREE.md` 概览文件。

---

## Single-Skill 模式

````markdown
# {Skill Name} Tree Overview

## 概述
本 skill-tree 将 {N} 个能力组织为分层路由树。

## 路由原理
```
用户意图 → ROOT.md (L1 模块) → ROUTER.md (L2 子模块) → LEAF SKILL.md (具体能力)
```

## 目录结构
```
{skill-name}-tree/
├── ROOT.md                          # L1: {N}个模块路由
├── SKILL-TREE.md                    # 本文件
│
├── {module1}/                       # {module1_display}
│   ├── ROUTER.md                    # {sub_count}个子模块消歧
│   └── {sub1}/SKILL.md              # → {capabilities}
│
└── {module2}/                       # {module2_display}
    └── SKILL.md                     # → {capabilities}
```

## 能力 → 叶节点映射表

| 能力 | 叶节点路径 |
|------|-----------|
| `{capability_1}` | `{module}/{sub}/SKILL.md` |
| `{capability_2}` | `{module}/{sub}/SKILL.md` |

## 新增能力指南
1. 确定所属模块（L1 category）
2. 如该模块已有 ROUTER.md，添加新行到路由表
3. 如该模块无 ROUTER.md，创建新模块目录 + ROUTER.md
4. 创建或更新叶节点 SKILL.md
5. 更新本文件的映射表
````

---

## Multi-Skill 模式

````markdown
# {Domain} Tree Overview

## 概述
本 skill-tree 将 {N} 个能力组织为跨 skill 分层路由树，覆盖 {M} 个 skill。

## 路由原理
```
用户意图 → ROOT.md (Phase 1: 选 Skill) → ROUTER.md (Phase 2: 选能力) → LEAF SKILL.md
```

## 目录结构
```
{domain}-tree/
├── ROOT.md                          # Phase 1: 选 Skill
├── SKILL-TREE.md                    # 本文件
│
├── {skill_a}/                       # {Skill_A} 子树
│   ├── ROUTER.md                    # Phase 2: 选能力
│   └── {capability}/SKILL.md
│
├── {skill_b}/                       # {Skill_B} 子树
│   ├── ROUTER.md
│   └── {capability}/SKILL.md
│
├── shared/                          # 共享能力
│   └── {capability}/SKILL.md        # 标注: 适用于 skill_a, skill_b
│
└── cross-cutting/
    └── SKILL.md                     # 跨 skill 工作流
```

## 能力 → 叶节点映射表

| Skill | 能力 | 叶节点路径 |
|-------|------|-----------|
| `skill-a` | {capability} | `skill-a/{module}/SKILL.md` |
| `skill-b` | {capability} | `skill-b/{module}/SKILL.md` |
| `skill-a, skill-b` | {shared capability} | `shared/{capability}/SKILL.md` |

## Skill 覆盖统计

| Skill | 能力数 | 叶节点数 |
|-------|--------|---------|
| `{skill_a}` | {N} | {M} |
| `{skill_b}` | {N} | {M} |
| shared | {N} | {M} |
| cross-cutting | {N} workflows | 1 |
| **总计** | **{total}** | **{total}** |

## 新增 Skill 指南
1. 创建 `{new-skill}/ROUTER.md` + 叶节点
2. 更新 ROOT.md Phase 1 路由表 + 消歧规则
3. 更新 cross-cutting/SKILL.md（工作流 + dependencies）
4. 更新本文件映射表和覆盖统计
````
