---
name: "git-push-flow"
description: "完成本地到远程推送的收尾流程，包括更新功能文档、生成提交信息、推送并汇总diff。触发于每次准备执行git push前后。"
---

# Git 推送收尾流程

## 适用场景
- 用户要求“提交并推送”
- 用户要求“推送并总结diff/提交信息/更新功能文档”
- 每次本地变更即将推送到远程仓库

## 目标
- 推送前确认改动完整、提交信息清晰
- 推送后提供可复核的变更摘要与文档更新

## 输入
- 当前仓库工作区
- 需要更新的功能文档（默认 docs/GDD.md）

## 执行流程
1. 查看变更范围与状态
   - git status -sb
   - git diff --name-only
2. 识别是否涉及功能文档并更新
   - 若功能改动影响玩法/UI/数据表，更新 docs/GDD.md 对应章节
3. 生成提交信息
   - 以 feat/fix/chore/refactor 开头，包含本次核心改动摘要
4. 执行提交与推送
   - git add -A
   - git commit -m "<message>"
   - git push（如无 upstream，使用 git push --set-upstream origin <branch>）
5. 生成diff摘要
   - git show -1 --stat
   - 概括新增/修改/删除的关键模块

## 输出
- 已推送到远程的提交
- 提交信息
- 简明diff摘要
- 功能文档更新点

## 质量门槛
- 功能文档与实际改动一致
- 提交信息可读且可回溯
- 推送成功并记录commit哈希

## 示例
用户：把改动推送到git仓库 并且总结diff的内容 同时给commit备注 并增加到功能文档里
执行：
- 更新 GDD.md
- git add/commit/push
- 输出提交信息与diff摘要
