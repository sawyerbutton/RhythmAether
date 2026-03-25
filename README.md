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

### 2. 游戏集锦视频背景（创新玩法）

```
游戏集锦视频 + AI 生成战斗音乐 + AI 自动配谱 = 节奏化的高光时刻体验
```

**核心创意**：将 Dota 2 等游戏的精彩集锦作为音游背景，配合 AI 生成的匹配风格音乐和自动谱面。玩家在打音游的同时沉浸在游戏高光画面中，击杀瞬间与节奏强拍对齐，产生 **1+1+1 > 3** 的情感叠加效果。

**为什么这很强**：
- 情感共鸣极强——看到喜欢英雄的五杀集锦就已经兴奋，加上节奏参与感直接翻倍
- 内容天然充足——YouTube/B站海量游戏集锦，不缺素材
- 传播性极强——"打着音游看 Dota 五杀"本身就是视频流量密码
- TI 2026 在中国举办——完美的时间窗口

### 3. 内置谱面编辑器

手机端完整创作体验，填补市场空白。

### 4. 社区谱面工坊

Steam Workshop 式的创作者生态，建立护城河。

## 当前开发状态

**M1 已完成 | M2 进行中 | M3 核心已验证 | 视频背景原型已验证**

已实现功能：
- 4 轨道下落式玩法（Tap + Hold）
- 判定系统（Perfect ±45ms / Great ±90ms / Good ±130ms / Miss）
- 计分系统（100 万满分，Phi/V/S/A/B/C/F 评级）
- 键盘操作（D/F/J/K）+ 触控/鼠标支持
- 完整游戏流程（标题 → 选曲 → 游玩 → 结算）
- 选曲界面（5 首歌曲，键盘/鼠标选择）
- AI 概念美术（Imagen 4 生成背景 + 角色概念）
- 墨水扩散视觉风格（「逆位乐章」主题）
- 宝石几何形态 Note（光柱拖尾 + 多层发光 + 脉动呼吸）
- 粒子特效 + 屏幕震动 + 判定线脉动 + 连击动画
- Hitsound 系统 + Combo 里程碑音效
- **AI 谱面生成器**（Python + librosa，任意音频 → RACF 谱面，支持 5 级难度）
- **AI 音乐生成**（ElevenLabs Music API，风格 prompt → 60s 器乐曲）
- **Dota 2 英雄主题**（Invoker / Phantom Assassin / Crystal Maiden）
- **视频背景播放**（OGV Theora + 自适应遮罩 + 打击联动闪光）
- **视频模式打击感增强**（Perfect 闪亮 / Miss 暗屏 / 加大粒子和震动）
- FastAPI 后端（谱面生成 REST API）

## Dota 2 主题方向

结合 2026 年 TI（The International）在中国举办的契机，探索 Dota 2 游戏集锦 + AI 音乐的音游体验：

| 英雄 | 音乐风格 | BPM | 状态 |
|---|---|---|---|
| Invoker | 史诗管弦乐，奥术能量 | 129 | 已生成 |
| Phantom Assassin | 暗黑电子，暗杀者氛围 | 140 | 已生成 |
| Crystal Maiden | 空灵冰晶，钢琴琶音 | 99 | 已生成 |
| Juggernaut | 日式太鼓 + DnB，武士能量 | 160 | 待生成 |
| Io | 环境 Glitch，宇宙质感 | 120 | 待生成 |
| Tidehunter | 重型 Dubstep，深海低音 | 140 | 待生成 |

**视频背景模式**：Dota 2 集锦视频 + AI 战斗音乐 + AI 谱面 → 节奏化的高光时刻体验

视频背景技术要点：
- 16:9 横屏集锦 → 9:16 竖屏裁切（中央区域，保留英雄和技能特效）
- 视频全屏播放 + 60% 暗色遮罩（Note 可读性优先）
- Perfect 判定时遮罩瞬间变亮（"闪亮"效果，视频与打击联动）
- Miss 判定时遮罩加深（"暗屏"惩罚）
- 视频模式下 Note 发光强度翻倍、粒子数量增加、屏幕震动加大

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
| AI 音乐生成 | ElevenLabs Music API |
| AI 美术 | Google Imagen 4（概念图 + 背景） |
| 视频背景 | Godot VideoStreamPlayer（OGV / Theora） |
| 后端 | FastAPI |
| 数据库 | Supabase（PostgreSQL）— 待接入 |

## 项目结构

```
RhythmAether/
├── game/                                  # Godot 项目
│   ├── project.godot
│   ├── scenes/                            # 场景
│   │   ├── title_screen.tscn             # 标题界面
│   │   ├── song_select.tscn             # 选曲界面
│   │   ├── gameplay.tscn                 # 游玩场景（支持视频背景）
│   │   └── result_screen.tscn            # 结算界面
│   ├── scripts/                           # GDScript
│   │   ├── game_manager.gd               # 全局状态
│   │   ├── chart_loader.gd               # RACF 解析器（含视频路径）
│   │   ├── judge.gd                      # 判定 + 计分系统
│   │   ├── gameplay.gd                   # 游戏主循环 + 视频背景
│   │   ├── note_object.gd               # Note 渲染（几何宝石风格）
│   │   ├── hit_particle.gd              # 粒子效果
│   │   ├── song_select.gd              # 选曲逻辑
│   │   ├── title_screen.gd              # 标题逻辑
│   │   └── result_screen.gd             # 结算逻辑
│   ├── resources/
│   │   ├── audio/                         # 音频（含 AI 生成曲目）
│   │   ├── charts/                        # RACF 谱面（含 AI 生成）
│   │   ├── video/                         # 视频背景素材
│   │   ├── hitsounds/                     # 打击音效
│   │   └── shaders/                       # 着色器
│   └── assets/textures/                   # AI 生成的背景图
│
├── backend/                               # Python 后端
│   ├── app/
│   │   ├── main.py                       # FastAPI 入口
│   │   └── services/
│   │       ├── chart_generator.py        # AI 谱面生成（librosa 分析 + Pattern 生成）
│   │       └── music_generator.py        # AI 音乐生成（ElevenLabs + 英雄档案）
│   └── requirements.txt
│
├── gen_chart.py                           # 手工谱面生成工具
│
└── docs/                                  # 设计文档
    ├── research/
    │   ├── game-research-report.md        # 竞品分析 + 技术选型
    │   └── gameplay-design-operations-report.md  # 玩法哲学 + 运营
    └── design/
        ├── core-gameplay-design.md        # 核心玩法规范
        └── ai-music-integration.md        # AI 音乐集成方案
```

## 开发里程碑

| 阶段 | 目标 | 状态 |
|---|---|---|
| **M1** Tech Demo | 单曲可玩 + 判定 + 音频同步 | **已完成** |
| **M2** Playable Prototype | 选曲界面 + 多首谱面 + 完整 UI | **进行中**（选曲已完成） |
| **M3** Alpha | AI 谱面生成 + AI 音乐生成 | **核心已验证** |
| **Dota 2 特别版** | 英雄主题音乐 + 集锦视频背景 | **原型已验证** |
| **M4** Beta | 谱面编辑器 + 工坊 + 排行榜 | 待开发 |

## 开发方式

本项目采用 **Vibe Coding**（AI 辅助编码）方式开发。

## License

MIT
