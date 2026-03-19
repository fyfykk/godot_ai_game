---
name: "attack-designer"
description: "根据游戏设计文档（GDD.md）中的攻击系统设计，构思新的攻击方式、相关升级和收藏品。当用户想要‘设计新攻击’、‘添加新技能’或‘构思新武器’时调用。"
---

# 攻击方式设计师 (Attack Designer)

本技能旨在根据项目的设计文档 `docs/GDD.md` 中定义的攻击系统框架，帮助您构思和设计新的攻击方式。

## 核心流程

1.  **回顾设计文档**: 在开始设计前，必须首先回顾 `docs/GDD.md` 中的“攻击系统核心设计”章节，以确保新设计与现有系统保持一致。

2.  **定义新攻击类型**: 
    *   为新的攻击方式指定一个唯一的 `target` ID (例如, `grenade`, `laser`, `chain_lightning`)。
    *   简要描述其核心机制和视觉表现。

3.  **设计核心属性**: 
    *   确定 3-4 个可供“升级”和“收藏品”强化的核心属性 (例如, `damage`, `interval`, `radius`, `projectile_speed`, `pierce_count`)。

4.  **创建关联项目**:
    *   **升级 (Upgrades)**: 在 `data/upgrades.csv` 中为新攻击方式的每个核心属性添加至少一个基础升级项。
    *   **收藏品 (Collectibles)**: 在 `data/collectibles.csv` 中设计至少 2-3 个与新攻击方式相关的收藏品，提供更多样化或更强力的加成。
    *   **解锁机制**: 决定该攻击方式是默认解锁，还是需要通过特定的“升级”或“收藏品”来解锁，并相应地配置 `unlock` 字段。

## 设计范例：设计一个“连锁闪电”攻击

1.  **回顾 GDD**: 确认当前有 `bullet`, `melee`, `magic` 三种攻击类型及其属性。

2.  **定义新攻击**: 
    *   `target` ID: `chain_lightning`
    *   **描述**: 发射一道闪电，击中敌人后会弹跳到附近其他敌人身上。

3.  **设计核心属性**:
    *   `damage`: 闪电伤害
    *   `interval`: 施法间隔
    *   `chain_count`: 弹跳次数
    *   `chain_range`: 弹跳范围

4.  **创建关联项目**:
    *   **升级**: 
        *   `chain_lightning_damage`: 伤害 +2
        *   `chain_lightning_interval`: 间隔 -0.2
    *   **收藏品**:
        *   `C401` (风暴核心): `chain_count` +1, `chain_range` +10
        *   `C402` (静电产生器): 每次弹跳伤害衰减降低 10%
    *   **解锁**: 添加一个史诗级（epic）升级 `attack_chain_lightning` 来解锁此攻击。
