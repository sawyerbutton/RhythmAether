# RhythmAether

> 创作者优先的开放音游平台 | Creator-First Open Rhythm Game Platform

---

## 项目定位

RhythmAether 是一款**日系中二风二次元音游**，核心定位为**「创作者优先的开放音游平台」**——不是又一款"更好看的下落式音游"，而是通过 AI 赋能和 UGC 生态构建全新的音游体验。

## 核心差异化

### 1. AI 全链路创作（行业首创）

```
文字描述 / 角色风格 → AI 生成音乐（ElevenLabs）→ AI 分析节拍（librosa）→ AI 生成谱面 → 直接可玩
```

- **AI 谱面生成**：导入任意音乐，秒生成可游玩谱面（已实现）
- **AI 音乐生成**：集成 ElevenLabs Music API，从文字描述到音乐到谱面的零门槛创作（已实现）
- **角色风格引导**：选择角色/英雄风格，AI 自动生成匹配风格的音乐（已实现 Dota 2 英雄主题）

### 2. 内置谱面编辑器

手机端完整创作体验，填补市场空白。

### 3. 社区谱面工坊

Steam Workshop 式的创作者生态，建立护城河。

## 当前开发状态

**M1 Tech Demo 已完成，M3 核心功能（AI 链路）已提前验证。**

已实现功能：
- 4 轨道下落式玩法（Tap + Hold）
- 判定系统（Perfect ±45ms / Great ±90ms / Good ±130ms / Miss）
- 计分系统（100 万满分，Phi/V/S/A/B/C/F 评级）
- 键盘操作（D/F/J/K）+ 触控/鼠标支持
- AI 概念美术（Imagen 4 生成背景 + 角色概念）
- 墨水扩散视觉风格（「逆位乐章」主题）
- 粒子特效 + 屏幕震动 + 判定线脉动
- Hitsound 系统 + Combo 里程碑音效
- 完整游戏流程（标题 → 游玩 → 结算）
- **AI 谱面生成器**（Python + librosa，任意音频 → RACF 谱面）
- **AI 音乐生成**（ElevenLabs Music API）
- **Dota 2 英雄主题音乐**（Invoker / Phantom Assassin / Crystal Maiden）
- FastAPI 后端（谱面生成 API）

## 世界观：「逆位乐章」（Inverse Opus）

现实与镜像世界的双面设定。每个人在"逆位世界"都有一个"音影"——内心情感的具象化。主角通过"演奏"净化情感崩坏的音影，每首歌背后都是一个角色的内心故事。

**视觉语言**：黑白分界线 / 镜像对称构图 / 墨水扩散的流动感

**配色方案**：`#1A1A2E` 深墨蓝 / `#E94560` 暗红 / `#0F3460` 深蓝 / `#533483` 紫

## 技术栈

| 层级 | 选型 |
|---|---|
| 游戏引擎 | Godot 4.3（GDScript） |
| 谱面格式 | RACF（RhythmAether Chart Format，JSON） |
| AI 谱面生成 | Python + librosa（BPM 检测 + 频段分析 + Pattern 生成） |
| AI 音乐生成 | ElevenLabs Music API（含 provider 抽象层） |
| AI 美术 | Google Imagen 4（概念图 + 背景） |
| 后端 | FastAPI |
| 数据库 | Supabase（PostgreSQL）— 待接入 |

## 项目结构

```
RhythmAether/
├── game/                                  # Godot 项目
│   ├── project.godot
│   ├── scenes/                            # 场景
│   │   ├── title_screen.tscn             # 标题界面
│   │   ├── gameplay.tscn                 # 游玩场景
│   │   └── result_screen.tscn            # 结算界面
│   ├── scripts/                           # GDScript
│   │   ├── game_manager.gd               # 全局状态
│   │   ├── chart_loader.gd               # RACF 解析器
│   │   ├── judge.gd                      # 判定 + 计分系统
│   │   ├── gameplay.gd                   # 游戏主循环
│   │   ├── note_object.gd               # Note 渲染
│   │   ├── hit_particle.gd              # 粒子效果
│   │   ├── title_screen.gd              # 标题逻辑
│   │   └── result_screen.gd             # 结算逻辑
│   ├── resources/
│   │   ├── audio/                         # 音频文件
│   │   ├── charts/                        # RACF 谱面
│   │   ├── hitsounds/                     # 打击音效
│   │   └── shaders/                       # 着色器
│   └── assets/textures/                   # AI 生成的背景图
│
├── backend/                               # Python 后端
│   ├── app/
│   │   ├── main.py                       # FastAPI 入口
│   │   └── services/
│   │       ├── chart_generator.py        # AI 谱面生成
│   │       └── music_generator.py        # AI 音乐生成
│   └── requirements.txt
│
└── docs/                                  # 设计文档
    ├── research/
    │   ├── game-research-report.md
    │   └── gameplay-design-operations-report.md
    └── design/
        ├── core-gameplay-design.md
        └── ai-music-integration.md
```

## 开发里程碑

| 阶段 | 目标 | 状态 |
|---|---|---|
| **M1** Tech Demo | 单曲可玩 + 判定 + 音频同步 | **已完成** |
| **M2** Playable Prototype | 选曲界面 + 多首谱面 + 完整 UI | 进行中 |
| **M3** Alpha | AI 谱面生成 + AI 音乐生成 | **核心已验证** |
| **M4** Beta | 谱面编辑器 + 工坊 + 排行榜 | 待开发 |

## 开发方式

本项目采用 **Vibe Coding**（AI 辅助编码）方式开发。

## License

MIT
