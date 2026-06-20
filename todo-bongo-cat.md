# Bongo Cat 核心机制分析与 Pata Dog 借鉴实现规划

本文件基于 Steam 热门桌宠应用 [Bongo Cat (Steam App 3419430)](https://store.steampowered.com/app/3419430/Bongo_Cat/) 的核心机制进行深度拆解，并为我们的 **Pata Dog** 整理出了一套可供模仿、复制和借鉴的开发规划。

---

## 1. Bongo Cat 核心玩法与体验特征拆解

Bongo Cat 并非传统的音乐节奏游戏，而是一个定位为 **“解压/放置/陪伴 (Idle Desktop Companion)”** 的系统级桌宠应用，其成功核心在于：
1. **打字强力打击感 (Tap-to-Beat)**：在任务栏或桌面上“拍打”，每一次键盘或鼠标输入都会实时联动“啪啪啪”的爪子拍打动作，伴随清脆的敲击或敲鼓音效。
2. **放置积分累加 (Idle Clicker Points)**：用户在电脑上的任何操作（码字写代码、打游戏、点击鼠标）都会转化为积分（1 click = 1 point）。
3. **开箱随机收集 (Gacha & Lootboxes)**：每累积 1000 次操作（积分），系统赠送一个宝箱，开箱可以随机获得一件用于打扮猫咪的装饰品。
4. **丰富的换装扩展 (Custom Cosmetics)**：收集各种帽子（Hats）、眼镜配饰（Glasses）、手里拿着的物品/乐器（Instruments/Props）。
5. **多人同屏联机房间 (Co-op Meowtiplayer)**：支持多人进入同一个线上房间，数十只别人的猫咪在您的屏幕底端一齐陪您打字拍击，还能发送 meow 表情互动，营造强烈的“云搬砖/云学习”氛围。
6. **无缝后台集成 (Focus Free & Non-Intrusive)**：常驻系统右下角，完全不抢占其他窗口的工作焦点，占用内存极小。

---

## 2. Pata Dog 的模仿/复制/借鉴实现清单 (TODO)

为了让 **Pata Dog** 从一个单纯的“动态小摆件”演变为具有“游戏性与收集欲”的桌面伴侣，建议分阶段加入以下功能：

### 🟢 Phase 1: 机械键盘与打鼓敲击音效 (Audio Beat-mapping)
* [ ] **引入高品质音频采样**：
  * 引入 2-3 种不同的键盘轴体音效（例如：青轴、茶轴、麻将音）。
  * 引入萌系的打击音效（如小太鼓、木鱼、汪汪叫声）。
* [ ] **打击节奏绑定**：
  * 当用户按下按键或鼠标时，调用 `_tap_sound()` 播放选定的敲击音效。
  * 根据当前敲击速度（Excitement 兴奋度）动态微调音调（Pitch Scale），使其声音听起来更加生动。

### 🟡 Phase 2: 积分计算器与存档系统 (Typing Points & Save Data)
* [ ] **打字点数追踪**：
  * 在 `main.gd` 中维护全局变量 `total_clicks`（总点击数）和 `current_points`（当前积分）。
  * 每次键盘输入、鼠标点击都会使这两个数值加 1。
* [ ] **本地自动存取档**：
  * 使用 Godot 的 `FileAccess`，在每次退出时或每隔 100 步将数据序列化保存到 `user://pata_dog_save.json`。
  * 启动时自动读取存档，恢复已累计的打字总数。

### 🟡 Phase 3: 1000 次开箱与饰品装扮系统 (Chest Gacha & Cosmetics)
* [ ] **1000 次敲击宝箱**：
  * 在 UI 界面右上角增加一个打字计数条。
  * 每满 1000 积分，触发“宝箱生成”动画（箱子在屏幕边缘可爱抖动）。
  * 点击箱子播放可爱的开箱音效与爆炸粒子特效，开出随机饰品。
* [ ] **骨骼饰品挂载槽 (Slots)**：
  * 在 `HeadJoint` 下增加 `HatSlot`（帽子挂载点）。
  * In `BodyJoint` 下增加 `GlassesSlot` / `NecklaceSlot`（眼睛/项圈挂载点）。
  * 在 `LeftPawJoint` / `RightPawJoint` 下增加 `PropSlot`（手持小乐器/鼠标等）。
* [ ] **简易背包/衣柜 UI (Wardrobe)**：
  * 在编辑器侧边栏增加“衣柜 (Wardrobe)”分类。
  * 采用网格布局（GridContainer）展示已解锁的皮肤和饰品，点击即可完成穿戴/脱下，穿戴状态需写入本地存档。

### 🔴 Phase 4: 全局系统集成优化 (System & OS Integration)
* [ ] **全局键鼠钩口 (Global Input Hooks)**：
  * 研究在 Godot 4 中实现全局无焦点键鼠监听（当玩家在玩游戏或写 VS Code 时，Pata Dog 仍在后台实时拍击）。
* [ ] **自启动与系统托盘**：
  * 增加开机自启动选项。
  * 支持右键点击桌宠最小化至 Windows 系统托盘（常驻右下角通知区域）。
