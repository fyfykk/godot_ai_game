---
title: 默认发布规则
---

# 默认发布规则

## 范围
- Windows 与 Web 双平台发布

## 核心原则
- 发布包不依赖 data/*.csv
- 新增配置表必须有对应 packed 产物

## 默认流程
1. 更新配置或数据表
2. 更新对应 PackConfigs 打包逻辑
3. 构建前先执行打包脚本
4. 使用 build_windows.bat / build_web.bat 导出

## 打包规则
- data/*.csv 默认在导出时被排除
- data/packed/*.json 为发布数据源
- PackConfigs.gd 负责生成 packed 文件

## 新增内容检查清单
- 新增 CSV 是否在 PackConfigs.gd 中处理
- 对应 Config 是否优先读取 data/packed
- export_presets 是否仍排除 data/*.csv
- 构建脚本是否执行 PackConfigs.gd
