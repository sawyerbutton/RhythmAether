# AI 音乐生成集成与世界观音乐体系设计

> 文档日期：2026-03-23
> 文档类型：设计方案
> 关联文档：[市场调研报告](../research/game-research-report.md)、[玩法设计与运营调研](../research/gameplay-design-operations-report.md)

---

## 1. 设计背景与动机

### 1.1 从调研中提炼的机会

市场调研明确指出，音游领域存在两个高价值蓝海：

- **AI 自动生成谱面**：导入任意音乐秒生成可玩谱面，当前市场完全空白
- **本地音乐导入**：玩家社区高频诉求，几乎所有竞品都未满足

但这两个能力仅解决了"有音乐 → 有谱面"的问题。如果进一步引入 **AI 音乐生成**（如 Suno），链路将延伸为从无到有的完整闭环——玩家甚至不需要准备音乐素材。

### 1.2 核心主张

**将 Suno 等 AI 音乐生成能力作为平台级基础设施集成**，实现：

```
文字描述 / 情绪关键词
        ↓
  Suno API 生成音乐
        ↓
  librosa + madmom 分析节拍
        ↓
  AI 生成 RACF 谱面
        ↓
  直接可玩 / 进入编辑器微调
```

这条全链路在现有竞品中**完全不存在**，是 RhythmAether 最强的差异化武器。

### 1.3 与世界观的耦合

AI 音乐生成不应是一个孤立的工具功能，而应与世界观「逆位乐章」深度绑定：**世界观定义音乐的审美框架，AI 在框架内生成内容**。角色不仅是视觉元素，更是音乐风格的锚点。

---

## 2. Suno 集成方案

### 2.1 集成架构

```
┌─────────────────────────────────────────────────────┐
│                    客户端（Godot）                     │
│                                                       │
│  ┌─────────────┐    ┌──────────────┐    ┌──────────┐ │
│  │  创作界面    │───→│  音乐预览     │───→│ 谱面编辑  │ │
│  │ (文字/角色)  │    │  (试听/选择)  │    │ (微调)   │ │
│  └──────┬──────┘    └──────────────┘    └──────────┘ │
│         │                                             │
└─────────┼─────────────────────────────────────────────┘
          │ API 请求
          ▼
┌─────────────────────────────────────────────────────┐
│                  后端（FastAPI）                       │
│                                                       │
│  ┌───────────────┐   ┌──────────────┐   ┌──────────┐ │
│  │ Suno API 调用  │──→│ 音频分析管线  │──→│ 谱面生成  │ │
│  │ (音乐生成)    │   │ (librosa +   │   │ (RACF    │ │
│  │               │   │  madmom)     │   │  输出)   │ │
│  └───────────────┘   └──────────────┘   └──────────┘ │
│                                                       │
│  ┌───────────────────────────────────────────────┐   │
│  │        角色音乐档案系统（Prompt 模板库）         │   │
│  │  角色 → 音乐风格参数 + 视觉参数 + 谱面风格参数  │   │
│  └───────────────────────────────────────────────┘   │
│                                                       │
└─────────────────────────────────────────────────────┘
```

### 2.2 三种创作模式

| 模式 | 输入 | 适用场景 | 门槛 |
|---|---|---|---|
| **自由创作** | 用户自由输入文字描述 / 风格标签 | 有明确想法的创作者 | 低 |
| **角色灵感** | 选择一个逆位乐章角色 → 自动填充该角色的音乐风格模板 | 想探索世界观的玩家 | 极低 |
| **导入音乐** | 上传本地音乐文件 | 已有音乐素材的用户 | 低 |

三种模式最终都汇入同一条管线：**音频 → 节拍分析 → 谱面生成**。

### 2.3 Suno API 调用设计

```python
# 角色音乐档案驱动的 Suno prompt 构建示例
class SunoPromptBuilder:
    def build_from_character(self, character_id: str, user_input: str = "") -> dict:
        """
        基于角色音乐档案构建 Suno API 请求参数
        """
        profile = self.character_profiles[character_id]

        # 角色基础风格 + 用户自定义叠加
        prompt = {
            "style": profile["music_style"],        # e.g. "dark ambient, trip-hop"
            "mood": profile["emotional_tone"],       # e.g. "melancholic, introspective"
            "bpm_range": profile["bpm_range"],       # e.g. [80, 120]
            "instruments": profile["instruments"],   # e.g. ["piano", "synth pad", "lo-fi drums"]
            "user_description": user_input,          # 用户额外描述（可选）
        }
        return prompt

    def build_from_freeform(self, user_description: str) -> dict:
        """
        自由创作模式，直接使用用户描述
        """
        return {
            "description": user_description,
        }
```

### 2.4 分阶段落地计划

| 阶段 | 内容 | 里程碑对应 |
|---|---|---|
| **Phase 0** | 本地音乐导入 + AI 谱面生成（不依赖 Suno） | M3 |
| **Phase 1** | Suno API 基础集成：自由创作模式 | M3+ |
| **Phase 2** | 角色灵感模式 + 角色音乐档案系统 | M4 |
| **Phase 3** | UGC 工坊中开放 AI 音乐生成能力 | M4+ |

**Phase 0 不依赖任何外部 AI 音乐服务**，确保核心功能可独立运行。Suno 集成作为增强层叠加。

### 2.5 Suno 之外的扩展性

架构设计上应抽象出 `MusicGenerationProvider` 接口，不绑死 Suno：

```python
class MusicGenerationProvider(ABC):
    @abstractmethod
    async def generate(self, params: MusicGenParams) -> AudioResult:
        pass

class SunoProvider(MusicGenerationProvider):
    async def generate(self, params: MusicGenParams) -> AudioResult:
        # Suno API 调用
        ...

class UdioProvider(MusicGenerationProvider):
    async def generate(self, params: MusicGenParams) -> AudioResult:
        # Udio API 调用（备选）
        ...
```

未来可按需切换或多引擎并行，降低对单一供应商的依赖。

---

## 3. 世界观与音乐风格的绑定体系

### 3.1 核心理念

**世界观不是去"适配"AI 音乐生成工具，而是世界观本身定义音乐的审美框架，AI 在框架内生成内容。**

在「逆位乐章」的设定中，每个角色代表一种情感创伤/内心世界，因此每个角色天然对应一种音乐审美。这个对应关系构成**角色音乐档案（Character Sound Profile）**，是连接世界观、视觉设计、音乐风格和谱面特征的核心数据结构。

### 3.2 角色音乐档案系统

每个角色绑定以下维度：

```json
{
  "character_id": "kael",
  "character_name": "カエル / 蛙",
  "emotional_theme": "压抑的愤怒与自我否定",
  "inverse_world_visual": {
    "dominant_colors": ["#1A1A2E", "#E94560", "#0F3460"],
    "particle_style": "墨水碎裂扩散",
    "judgment_line_style": "锯齿状脉冲线",
    "background_mood": "暗红色风暴中的静默眼"
  },
  "music_profile": {
    "primary_genres": ["industrial", "dark electro", "drum and bass"],
    "secondary_genres": ["post-punk", "noise"],
    "mood_tags": ["aggressive", "suffocating", "explosive release"],
    "bpm_range": [140, 180],
    "key_instruments": ["distorted synth", "heavy drums", "glitch FX"],
    "vocal_style": "none or distorted vocal chops",
    "dynamic_arc": "压抑蓄力 → 爆发释放 → 余震回落"
  },
  "chart_profile": {
    "preferred_note_types": ["tap_stream", "flick_burst", "arc_aggressive"],
    "density_curve": "long_buildup_explosive_peak",
    "gimmick_tendency": "screen_shake, speed_change"
  }
}
```

### 3.3 角色音乐风格矩阵（初始设定）

基于「逆位乐章」世界观，以下为首批角色的音乐风格映射：

| 角色代号 | 情感主题 | 音乐风格 | BPM 区间 | 视觉关键词 |
|---|---|---|---|---|
| **Kael（蛙）** | 压抑的愤怒 | Industrial / Dark Electro / DnB | 140-180 | 暗红风暴、墨水碎裂 |
| **Lumen（光）** | 失去的温暖 | Lo-fi / Acoustic / Ambient | 70-100 | 暖黄光晕、水彩晕染 |
| **Nyx（夜）** | 孤独的自我放逐 | Dark Ambient / Trip-hop | 80-110 | 深蓝虚空、星尘消散 |
| **Aria（咏）** | 被压抑的表达欲 | Future Bass / Vocal Electro | 120-150 | 彩色声波、碎片拼合 |
| **Rei（零）** | 情感的麻木与空白 | Minimal Techno / Glitch | 110-130 | 灰白噪点、几何碎形 |
| **Sora（空）** | 理想主义的崩塌 | Post-rock / Orchestral | 90-140 | 崩塌建筑、光穿裂缝 |

每个角色的视觉设计（配色、粒子效果、判定线样式、背景动态）与音乐风格形成统一的审美包。

### 3.4 三位一体的体验闭环

```
         ┌──────────────┐
         │   世界观叙事   │
         │ (角色情感故事)  │
         └──────┬───────┘
                │ 定义
         ┌──────▼───────┐
         │  角色音乐档案  │  ←── 核心数据结构
         └──┬───┬───┬───┘
            │   │   │
     ┌──────▼┐ ┌▼────▼──────┐
     │ 视觉风格│ │ 音乐风格     │
     │ - 配色  │ │ - 流派/BPM   │
     │ - 粒子  │ │ - 乐器/情绪   │
     │ - 判定线│ │ - 动态弧线    │
     │ - 背景  │ │ - Suno prompt │
     └───┬────┘ └──────┬─────┘
         │             │
         └──────┬──────┘
                │ 驱动
         ┌──────▼───────┐
         │   谱面特征     │
         │ - 音符偏好     │
         │ - 密度曲线     │
         │ - Gimmick 风格 │
         └──────────────┘
```

**玩家体验路径**：

1. **被动体验**：玩官方谱面 → 感受角色音乐+视觉统一风格 → 通过游玩理解角色故事
2. **主动创作**：在工坊选择"以 Nyx 的风格创作" → AI 生成匹配该角色审美的音乐 → 自动生成谱面 → 发布到社区
3. **社区发现**：浏览工坊时按角色风格筛选 → "Kael 风格的热门谱面" → 世界观成为内容组织的维度

### 3.5 对 UGC 工坊的意义

角色音乐档案系统让 UGC 创作不再是无序的——创作者可以：

- **选择角色风格**作为创作起点，降低"不知道做什么"的决策负担
- **社区内容自然分类**：按角色/情感风格浏览，而非只按曲名/难度
- **风格一致性**：即使是 AI 生成的音乐，也因角色档案的约束而保持与世界观的审美统一
- **创作者身份**：有人擅长做 Kael 风格的高强度谱面，有人专注 Lumen 风格的治愈谱面 → 创作者的个人风格 = 角色偏好，形成社区辨识度

---

## 4. 对现有设计的影响与调整

### 4.1 里程碑调整

原有里程碑基本不变，调整如下：

| 里程碑 | 原内容 | 新增/调整内容 |
|---|---|---|
| **M1** | 技术验证 | 不变 |
| **M2** | 核心游玩 MVP | 不变 |
| **M3** | AI 谱面生成 + 特色音符 | **新增**：Suno API 基础集成（自由创作模式）；角色音乐档案数据结构定义 |
| **M4** | 编辑器 + 工坊 | **新增**：角色灵感创作模式；按角色风格的工坊分类/筛选 |

### 4.2 技术栈补充

| 模块 | 新增选型 | 说明 |
|---|---|---|
| AI 音乐生成 | Suno API（主）/ Udio（备选） | 通过 Provider 接口抽象，不绑死供应商 |
| 角色音乐档案 | JSON 配置 + Supabase 存储 | 档案数据可热更新，无需客户端发版 |
| Prompt 模板管理 | 后端配置中心 | 便于迭代优化 AI 生成质量 |

### 4.3 项目目录结构补充

在原有后端目录中新增：

```
backend/
├── app/
│   ├── api/
│   │   ├── ai_generate.py      # AI 谱面生成（已有）
│   │   └── ai_music.py         # AI 音乐生成（新增）
│   ├── services/
│   │   ├── chart_generator.py   # AI 谱面生成核心（已有）
│   │   ├── beat_detector.py     # 节拍检测（已有）
│   │   └── music_generator.py   # 音乐生成 Provider（新增）
│   └── data/
│       └── character_profiles/  # 角色音乐档案 JSON（新增）
│           ├── kael.json
│           ├── lumen.json
│           ├── nyx.json
│           ├── aria.json
│           ├── rei.json
│           └── sora.json
```

### 4.4 商业模式考量

Suno API 有调用成本，需考虑：

| 策略 | 说明 |
|---|---|
| **免费额度** | 每日/每月 N 次免费 AI 音乐生成（引流体验） |
| **付费额度** | 超出免费额度后按次或包月付费 |
| **导入音乐免费** | 导入本地音乐 + AI 谱面生成始终免费，不受 Suno 成本影响 |
| **缓存复用** | 社区已生成的 AI 音乐可被其他玩家直接使用，摊薄成本 |

**核心原则**：AI 音乐生成是增值层，不是门槛。本地音乐导入 + AI 谱面生成作为基础能力始终可用。

---

## 5. 开放问题

以下问题需在后续设计中进一步明确：

1. **版权归属**：Suno 生成的音乐在 UGC 工坊中分享时的版权归属如何处理？需研究 Suno ToS 对生成内容的商用授权条款
2. **质量控制**：AI 生成的音乐质量波动较大，是否需要设置社区审核/评分门槛才能进入工坊精选？
3. **角色扩展节奏**：首批 6 个角色的音乐档案何时需要扩展？是否与世界观叙事进度绑定？
4. **离线支持**：AI 音乐生成依赖网络，离线模式下如何保持创作体验？（可能方案：本地缓存已生成音乐 + 离线仅支持导入模式）
5. **Suno API 稳定性与替代方案**：若 Suno 服务不可用或价格变动，切换到 Udio/其他方案的成本和时间评估

---

## 附录：参考资料

- [Suno API 文档](https://docs.suno.com/)
- [Udio API 文档](https://docs.udio.com/)
- RhythmAether 市场调研报告 - AI 赋能机会章节
- RhythmAether 玩法设计调研 - 体验派设计哲学章节