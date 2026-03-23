# RhythmAether

> 创作者优先的开放音游平台 | Creator-First Open Rhythm Game Platform

---

## 项目定位

RhythmAether 是一款**日系中二风二次元音游**，核心定位为**「创作者优先的开放音游平台」**——不是又一款"更好看的下落式音游"，而是通过 AI 赋能和 UGC 生态构建全新的音游体验。

## 核心差异化

### 1. AI 全链路创作（行业首创）

```
文字描述 / 情绪关键词 → AI 生成音乐（Suno）→ AI 分析节拍 → AI 生成谱面 → 直接可玩
```

- **AI 谱面生成**：导入任意音乐，秒生成可游玩谱面
- **AI 音乐生成**：集成 Suno 等 AI 音乐服务，从文字到音乐到谱面的零门槛创作
- **角色风格引导**：选择游戏内角色风格，AI 自动生成匹配世界观的音乐

### 2. 内置谱面编辑器

手机端完整创作体验，填补市场空白。

### 3. 社区谱面工坊

Steam Workshop 式的创作者生态，建立护城河。

## 世界观：「逆位乐章」（Inverse Opus）

现实与镜像世界的双面设定。每个人在"逆位世界"都有一个"音影"——内心情感的具象化。主角通过"演奏"净化情感崩坏的音影，每首歌背后都是一个角色的内心故事。

**视觉语言**：黑白分界线 / 镜像对称构图 / 墨水扩散的流动感

**角色-音乐-视觉一体化**：每位角色绑定独立的音乐风格、视觉模板和叙事主题，形成完整的「角色体验包」。世界观定义音乐审美框架，AI 音乐生成在框架内运作。

## 技术栈

| 层级 | 选型 |
|---|---|
| 游戏引擎 | Godot 4.3 LTS（GDScript） |
| 谱面格式 | RACF（RhythmAether Chart Format，JSON） |
| AI 谱面生成 | Python + librosa + madmom |
| AI 音乐生成 | Suno API（含 provider 抽象层，支持多服务切换） |
| 后端 | FastAPI |
| 数据库 | Supabase（PostgreSQL） |
| CI/CD | GitHub Actions |

## 开发里程碑

| 阶段 | 目标 | 核心交付 |
|---|---|---|
| **M1** Tech Demo | 技术验证 | 单曲 Tap Note 下落 + 判定 + 音频同步 |
| **M2** Playable Prototype | 完整单人体验 | 3 种 Note + 3-5 首谱面 + 完整 UI 流程 |
| **M3** Alpha | 差异化特性 | AI 谱面生成 + 角色视觉模板 + 角色 Music Profile |
| **M4** Beta | 社区生态 | Suno 集成 + 谱面编辑器 + 工坊 + 排行榜 |

## 项目文档

```
docs/
├── research/                              # 市场调研
│   ├── game-research-report.md            # 竞品分析 + 技术选型 + MVP 定义 + 世界观设计
│   └── gameplay-design-operations-report.md # 玩法设计哲学 + 运营模式
│
└── design/                                # 设计决策
    ├── core-gameplay-design.md            # 核心玩法设计（Note 类型 / 判定系统 / 分数评级 / 手感规范）
    └── ai-music-integration.md            # AI 音乐生成集成 + 世界观音乐匹配系统
```

## 开发方式

本项目采用 **Vibe Coding**（AI 辅助编码）方式开发。

## License

TBD