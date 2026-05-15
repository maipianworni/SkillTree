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

## Multi-Skill 模式（Domain-First）

````markdown
# {Domain} Tree Overview

## 概述
本 skill-tree 将 {N} 个能力组织为 domain-first 分层路由树，覆盖 {M} 个 skill。

## 路由原理
```
用户意图 → ROOT.md (Phase 1: 选能力域) → ROUTER.md (Phase 2: 选 skill) → LEAF SKILL.md
```

## 目录结构
```
{domain}-tree/
├── ROOT.md                          # Phase 1: 选能力域
├── SKILL-TREE.md                    # 本文件
│
├── {domain_a}/                      # 能力域 A
│   ├── ROUTER.md                    # Phase 2: 选 skill（≥2 skills 时需要）
│   ├── {skill_x}/SKILL.md           # skill_x 在 domain_a 的能力
│   ├── {skill_y}/SKILL.md           # skill_y 在 domain_a 的能力
│   └── {skill_z}/SKILL.md
│
├── {domain_b}/                      # 能力域 B
│   ├── ROUTER.md
│   ├── {skill_x}/SKILL.md
│   └── {skill_y}/SKILL.md
│
├── {domain_c}/                      # Unique 能力域（仅 1 个 skill）
│   └── {skill_x}/SKILL.md           # 无需 ROUTER.md
│
├── shared/                          # 共享能力
│   └── {capability}/SKILL.md        # 标注: 适用于 skill_x, skill_y
│
└── cross-cutting/
    └── SKILL.md                     # 跨 skill 工作流
```

## 能力域 → Skill → 叶节点映射表

| 能力域 | Skill | 叶节点路径 |
|--------|-------|-----------|
| `{domain_a}` | `{skill_x}` | `{domain_a}/{skill_x}/SKILL.md` |
| `{domain_a}` | `{skill_y}` | `{domain_a}/{skill_y}/SKILL.md` |
| `{domain_b}` | `{skill_x}` | `{domain_b}/{skill_x}/SKILL.md` |
| `{domain_c}` | `{skill_x}` | `{domain_c}/{skill_x}/SKILL.md` (Unique) |
| `shared` | `{skill_x}, {skill_y}` | `shared/{capability}/SKILL.md` |

## Skill 覆盖统计

| Skill | 涉及能力域数 | 叶节点数 |
|-------|------------|---------|
| `{skill_x}` | {N} | {M} |
| `{skill_y}` | {N} | {M} |
| shared | — | {N} |
| cross-cutting | — | 1 |
| **总计** | **{total_domains} domains** | **{total_leaves}** |

## 新增 Skill 指南
1. 分析新 skill 的能力 → 映射到现有能力域或创建新域
2. 对每个涉及的域：创建 `{domain}/{new-skill}/SKILL.md`，更新 `{domain}/ROUTER.md`
3. 更新 ROOT.md Phase 1 路由表 + Skill 快速索引 + 消歧规则
4. 更新 cross-cutting/SKILL.md（工作流 + dependencies）
5. 更新本文件映射表和覆盖统计
````
