# 优寻（UniSeek）兼职招聘平台

优寻（UniSeek）是一个面向大学生和企业的兼职招聘平台，提供求职信息发布、简历投递、职位管理等功能。平台覆盖 PC 端和鸿蒙端，采用前后端分离架构。

---

## 技术栈

### 后端
- Java 1.8 + Spring Boot 2.2.2.RELEASE
- MyBatis / MyBatis-Plus（ORM）
- MySQL 8（关系型数据库）
- JWT（无状态鉴权）
- Maven（构建管理）

### PC 前端
- Vue 3
- Element Plus
- Pinia（状态管理）
- Vue Router（路由）

### 鸿蒙端
- ArkTS 6.1.1
- ArkUI

---

## 目录结构

```
UniSeek/
├── uniseek_java/              # 后端模块（Spring Boot）
│   ├── src/main/java/         # Java 源码
│   ├── src/main/resources/    # 配置文件
│   └── pom.xml                # Maven 依赖管理
├── uniseek_vue/               # PC 前端模块（Vue 3）
│   ├── src/                   # Vue 源码
│   └── package.json           # 前端依赖配置
├── uniseek_arkts/             # 鸿蒙前端模块（ArkTS）
│   └── entry/src/main/ets/    # ArkTS 源码
├── uniseek_schema.sql         # 数据库建库建表脚本
└── uniseek_mock_data.sql      # Mock 数据脚本
```

---

## 快速开始

### 环境要求
- JDK 1.8+
- MySQL 8
- Node.js 18+
- Maven 3.6+

### 1. 初始化数据库

```bash
mysql -u root -p < uniseek_schema.sql
mysql -u root -p < uniseek_mock_data.sql
```

### 2. 启动后端

```bash
cd uniseek_java
mvn spring-boot:run
```

后端默认启动在 `http://localhost:8080`。

### 3. 启动前端

```bash
cd uniseek_vue
npm install
npm run dev
```

前端默认启动在 `http://localhost:5173`。

---

## 角色说明

| 角色值 | 角色名称 | 说明 |
|--------|----------|------|
| 0      | 求职者   | 浏览职位、投递简历、管理个人资料 |
| 1      | 企业 HR  | 发布职位、管理招聘信息、处理投递 |
| 9      | 管理员   | 平台日常运营管理 |
| 99     | 超级管理员 | 系统级别配置与维护 |

---

## 开发规范

- 所有注释及文档使用中文书写
- 前后端严格分离，不跨模块编写代码
- 后端采用分层架构（Controller / Service / DAO / Entity）
- 各模块职责清晰，命名统一

更多规范详见 `AGENTS.md`。
