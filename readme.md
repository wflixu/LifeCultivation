# LifeCultivation (人生修行)

<div align="center">

![LifeCultivation Logo](Assets.xcassets/AppIcon.appiconset/AppIcon.png)

**一款专注于健康生活方式培养的iOS原生应用**

[![Swift Version](https://img.shields.io/badge/Swift-5.0+-orange.svg)](https://swift.org)
[![iOS Version](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios/)
[![Xcode Version](https://img.shields.io/badge/Xcode-16.1.1+-green.svg)](https://developer.apple.com/xcode/)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

## 项目简介

LifeCultivation 是一个专注于健康生活方式培养的iOS原生应用，通过科学评分体系和数据可视化帮助用户建立并维持良好的生活习惯。

- **习惯追踪**：全方位记录日常饮食、作息、运动和屏幕使用情况
- **数据管理**：完整的历史记录编辑和数据追溯功能
- **可视化分析**：基于SwiftUI Charts的直观图表展示
- **激励机制**：科学的评分等级和持续进步的正向反馈

## 功能特性

### 核心评分系统

应用采用0-12分的日常评分系统：

#### 饮食评分 (0-3分)
- 三餐规律：按时完成早餐、午餐、晚餐
- 饮食健康：避免辛辣食物和垃圾食品
- **评分标准**：按时三餐(-1分)、不吃辛辣(-1分)、不吃垃圾食品(-1分)

#### 作息评分 (0-3分)
- 规律起床：按设定时间起床
- 规律睡觉：按设定时间就寝
- **评分标准**：按时起床(-1.5分)、按时睡觉(-1.5分)

#### 屏幕时间评分 (0-4分)
- **评分标准**：
  - 30分钟以内：4分
  - 31-60分钟：2分
  - 超过60分钟：0分

#### 运动评分 (无上限)
- **评分标准**：每次锻炼加1分 + 每周完成3次额外加1分

### 数据展示功能

- **趋势图表**：使用SwiftUI Charts展示历史趋势
- **时间筛选**：支持周、月、季、半年、年多维度分析
- **统计指标**：平均分、记录天数、等级分布等
- **等级评定**：
  - 12分：自律大师
  - 10-11分：高手
  - 8-9分：践行者
  - 6-7分：新手
  - 0-5分：休整日

## 技术架构

### 技术栈
- **语言**：Swift 5.0+
- **UI框架**：SwiftUI
- **数据持久化**：SwiftData (iOS 17+)
- **图表框架**：SwiftUI Charts
- **架构模式**：MVVM

### 项目结构
```
LifeCultivation/
├── LifeCultivation/                  # 主应用
│   ├── Models.swift                  # 数据模型
│   ├── ContentView.swift             # 主Tab视图
│   ├── LifeCultivationApp.swift       # 应用入口
│   ├── Views/                        # UI组件
│   │   ├── TodayView.swift           # 今日评分页面
│   │   ├── HistoryView.swift         # 历史记录页面
│   │   ├── SettingsView.swift        # 设置页面
│   │   ├── ScoreCardView.swift       # 分数卡片组件
│   │   ├── ExerciseSectionView.swift # 运动记录组件
│   │   ├── DietSectionView.swift     # 饮食记录组件
│   │   ├── SleepSectionView.swift    # 作息记录组件
│   │   ├── ScreenTimeSectionView.swift # 屏幕时间组件
│   │   ├── HistoryEditView.swift     # 历史记录编辑
│   │   └── DatePickerView.swift      # 日期选择组件
│   └── Assets.xcassets/              # 应用资源
├── LifeCultivation.xcodeproj/         # Xcode项目
├── LifeCultivationTests/             # 单元测试
├── LifeCultivationUITests/           # UI测试
└── spec/                             # 产品文档
    └── prd.md                        # 产品需求文档
```

### 数据模型

```swift
@Model
final class DailyRecord {
    var date: Date                    // 日期
    var dietScore: Int               // 饮食评分 (0-3)
    var sleepScore: Int              // 作息评分 (0-3)
    var screenTimeScore: Int         // 屏幕时间评分 (0-4)
    var exerciseCount: Int           // 运动次数 (每次1分，无上限)
    var exerciseCompleted: Bool      // 是否完成运动
    var note: String?                // 备注

    // 总分数 (0-12+)
    var totalScore: Int { ... }

    // 等级评定
    var rating: String { ... }
}
```

## 系统要求

- **iOS**: 17.0+ (支持SwiftData)
- **设备**: iPhone
- **Xcode**: 16.1.1+ (推荐最新版本)
- **Swift**: 5.0+

## 快速开始

### 环境准备

1. **安装Xcode**
   ```bash
   # 从App Store下载安装Xcode
   # 确保版本 >= 16.1.1
   ```

2. **克隆项目**
   ```bash
   git clone https://github.com/your-username/LifeCultivation.git
   cd LifeCultivation
   ```

### 运行项目

1. **打开项目**
   ```bash
   open LifeCultivation.xcodeproj
   ```

2. **选择设备**
   - 连接iPhone设备进行真机调试
   - 或选择iOS模拟器，确保系统版本 >= 17.0

3. **构建运行**
   ```bash
   # 构建项目
   xcodebuild -scheme LifeCultivation -destination 'platform=iOS Simulator,name=iPhone 17' build

   # 运行测试
   xcodebuild test -scheme LifeCultivation
   ```

### 开发说明

项目采用现代化的Swift开发模式，结合SwiftUI和SwiftData框架提供优秀的用户体验和数据持久化能力。

## 测试指南

### 运行单元测试
```bash
xcodebuild test -scheme LifeCultivation -destination 'platform=iOS Simulator,name=iPhone 17'
```

### 测试覆盖
- 数据模型验证测试
- UI组件交互测试
- 数据持久化测试
- 图表数据准确性测试

## 应用截图

<div align="center">
    <img src="Screenshots/TodayView.png" alt="今日评分页面" width="250">
    <img src="Screenshots/HistoryView.png" alt="历史记录页面" width="250">
    <img src="Screenshots/ChartsView.png" alt="数据图表页面" width="250">
</div>

## 开发路线图

### v1.0 (当前版本) - 核心功能
- [x] 日常习惯评分系统
- [x] 历史记录查看和编辑
- [x] 数据可视化图表
- [x] 完整的用户界面

### v1.1 (下个版本) - 体验优化
- [ ] 数据导入导出
- [ ] 深色模式适配
- [ ] 更多数据维度
- [ ] 运动类型细分

### v1.2 (未来版本) - 高级功能
- [ ] iCloud数据同步
- [ ] macOS版本适配
- [ ] HealthKit健康数据集成
- [ ] 智能提醒功能

### v2.0 (长期规划) - 智能化
- [ ] 社交功能分享
- [ ] AI健康建议
- [ ] 个性化目标设定
- [ ] Apple Watch独立应用

## 贡献指南

我们欢迎任何形式的贡献，包括但不限于功能开发、bug修复、文档完善等。

### 如何贡献

1. **Fork项目**到你的GitHub账户
2. **创建功能分支**：
   ```bash
   git checkout -b feature/amazing-feature
   ```
3. **提交更改**：
   ```bash
   git commit -m "Add amazing feature"
   ```
4. **推送到分支**：
   ```bash
   git push origin feature/amazing-feature
   ```
5. **创建Pull Request**

### 开发规范
- 遵循Swift编码规范
- 确保测试覆盖率
- 更新相关文档
- 保持代码简洁和可读性

### 问题反馈
如果发现bug或有功能建议，请通过以下方式反馈：
1. 提交[Issues](../../issues)并详细描述问题
2. 在Issues中提供复现步骤和环境信息
3. 等待维护者处理和回复

## 开源协议

本项目采用MIT开源协议 - 查看 [LICENSE](LICENSE) 文件了解详情

## 项目信息

- **作者**: [Your Name](https://github.com/your-username)
- **邮箱**: your.email@example.com
- **项目地址**: [https://github.com/your-username/LifeCultivation](https://github.com/your-username/LifeCultivation)

## 致谢

感谢以下开源项目和技术支持：

- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - 现代化UI框架
- [SwiftData](https://developer.apple.com/documentation/swiftdata/) - 数据持久化框架
- [Charts](https://developer.apple.com/documentation/charts) - 数据可视化框架

## Star History

感谢所有给这个项目点Star的开发者！

[![Star History Chart](https://api.star-history.com/svg?repos=your-username/LifeCultivation&type=Date)](https://star-history.com/#your-username/LifeCultivation&Date)

---

<div align="center">

**LifeCultivation** - 让每一天都成为进步的阶梯

Made with ❤️ by [Your Name]

</div>