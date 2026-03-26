\# GitHub 自动上传 Shell 项目

企业级规范 Shell 脚本



\## 项目介绍

本项目实现了一键自动完成Git全流程上传，完整展示Shell编程的工程化能力、错误处理、日志系统、兼容性设计与规范意识。



\## 核心功能

\- 一键完成 git pull → add → commit → push 全流程

\- 全链路错误处理与日志记录

\- 配置与代码分离，支持配置文件+命令行参数双模式

\- 提交信息规范检查（符合Conventional Commits企业规范）

\- 敏感文件安全检查，避免密钥泄露

\- 跨平台兼容（支持Windows Git Bash、Linux、macOS）



\## 使用方法

1\. 给脚本添加执行权限：`chmod +x auto\_git\_push.sh`

2\. 基础使用：`./auto\_git\_push.sh -m "feat: 新增功能"`

3\. 指定分支推送：`./auto\_git\_push.sh -m "fix: 修复bug" -b master`



\## 配置说明

可修改 `config.conf` 配置默认参数，无需每次执行都输入。



\## 项目结构

auto\_git\_upload/

├── auto\_git\_push.sh # 核心脚本

├── config.conf # 配置文件

├── .gitignore # Git 忽略文件

└── README.md # 项目说明文档

## 测试记录
- 2026-03-26：成功用脚本自动上传！

