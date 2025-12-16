# Excel2VCard iOS Native App

本文档说明如何构建和使用 Excel2VCard 的原生 iOS 应用程序。

## 概述

Excel2VCard iOS 是一款原生 SwiftUI 应用程序，可以将 Excel/CSV 联系人文件转换为 VCF 格式，并支持直接导入到 iOS 通讯录。

### 主要功能

- 📱 **原生 iOS 体验**：基于 SwiftUI，支持 iOS 15+ 和 iPadOS
- 📁 **文件格式支持**：支持 .xlsx 和 .csv 文件
- 🔍 **智能字段识别**：自动识别中英文表头（姓名、电话、邮箱、公司、职位等）
- 👥 **联系人预览**：解析后展示可滚动的联系人列表
- 🔄 **自动去重**：按"姓名+手机号"去重，手机号自动规范化（去除空格、+86、连字符）
- 📤 **多种导出方式**：
  - 分享 VCF 文件（可保存到文件、AirDrop 等）
  - 直接写入通讯录（需要通讯录权限）
- 🌏 **中文优先**：界面、提示均为中文

## 系统要求

- **开发环境**：macOS 13.0+ with Xcode 15+
- **运行环境**：iOS 15.0+ / iPadOS 15.0+
- **依赖**：CoreXLSX (通过 Swift Package Manager 自动安装)

## 构建说明

### 1. 打开项目

```bash
cd ios/Excel2VCard
open Excel2VCard.xcodeproj
```

### 2. 安装依赖

首次打开项目时，Xcode 会自动下载 Swift Package 依赖（CoreXLSX）。如果没有自动下载：

1. 在 Xcode 中选择 **File → Packages → Resolve Package Versions**
2. 等待 CoreXLSX 下载完成

### 3. 选择目标设备

在 Xcode 顶部工具栏：
- 选择 **Excel2VCard** scheme
- 选择目标设备（iPhone 模拟器或真机）

### 4. 运行应用

- **模拟器**：直接点击运行按钮（⌘R）
- **真机**：
  1. 连接 iPhone/iPad
  2. 在 **Signing & Capabilities** 中设置开发团队
  3. 点击运行按钮

## 使用说明

### 字段映射规则

应用会自动识别以下表头关键词（不区分大小写）：

| VCF 字段 | 识别的表头关键词 |
|---------|----------------|
| 姓名 | 姓名, Name, name, 名字, 联系人, Full Name |
| 电话/手机 | 电话, Phone, 手机号, 手机, Mobile, Tel |
| 邮箱 | 邮箱, Email, 邮件, Mail |
| 公司 | 公司, Company, 单位, 组织, Org |
| 职位 | 职位, Title, 职务, Position |

**注意**：
- 至少需要包含"姓名"列
- 其他字段为可选
- 未识别的列会被忽略

### 去重规则

应用会自动按以下规则去重：
1. 组合键：`姓名（小写）+ 规范化手机号`
2. 手机号规范化：
   - 去除所有空格
   - 去除 `+86` 前缀
   - 去除连字符 `-`
3. 示例：
   - "张三" + "138 0013 8000" 
   - "张三" + "+86-13800138000"
   - 以上两条会被识别为重复并只保留一条

### 通讯录权限

当你选择"直接写入通讯录"时，应用会请求通讯录访问权限：

```
需要访问通讯录以便写入联系人。仅在你选择"写入通讯录"时使用。
```

- 首次使用时会弹出系统权限请求
- 如果拒绝，可稍后在 **设置 → 隐私 → 通讯录** 中开启
- 导出 VCF 文件不需要此权限

### 示例文件

项目包含示例文件：`ios/Samples/contacts-sample.csv`

可以使用此文件测试应用功能。

## 发布到 TestFlight

### 准备工作

1. **Apple Developer Account**：需要付费开发者账号
2. **App Store Connect**：创建应用记录
3. **Bundle Identifier**：设置唯一的 Bundle ID（如 `com.yourcompany.Excel2VCard`）

### 打包步骤

1. **配置签名**：
   ```
   Xcode → Project Settings → Signing & Capabilities
   - Team: 选择你的开发团队
   - Bundle Identifier: 设置唯一 ID
   ```

2. **Archive 构建**：
   ```
   Xcode → Product → Archive
   ```

3. **上传到 App Store Connect**：
   ```
   Archives 窗口 → Distribute App → App Store Connect
   ```

4. **在 App Store Connect 中配置**：
   - 设置应用描述、截图
   - 添加测试人员
   - 提交审核（TestFlight 审核较快，通常 1-2 天）

5. **分发给测试人员**：
   - 审核通过后，邀请测试人员
   - 测试人员通过 TestFlight app 安装

### 提示

- TestFlight 最多支持 10,000 名外部测试人员
- 内部测试（最多 100 人）无需审核
- 每个 build 有效期 90 天

## 项目结构

```
ios/
├── Excel2VCard/
│   ├── Excel2VCard.xcodeproj/        # Xcode 项目文件
│   └── Excel2VCard/                   # 源代码
│       ├── Excel2VCardApp.swift       # 应用入口
│       ├── ContentView.swift          # 主界面 + 文档选择器 + 预览 + 导出
│       ├── ExcelParser.swift          # XLSX/CSV 解析 + 字段映射 + 去重
│       ├── ContactExporter.swift      # VCF 导出 + 通讯录写入
│       ├── Models.swift               # ContactRecord 数据模型
│       ├── Assets.xcassets/           # 应用图标和资源
│       └── Info.plist                 # 应用配置（含权限描述）
└── Samples/
    └── contacts-sample.csv            # 示例联系人文件
```

## 技术栈

- **UI 框架**：SwiftUI
- **最低版本**：iOS 15.0
- **依赖库**：
  - CoreXLSX (0.14.2+) - Excel (.xlsx) 解析
- **系统框架**：
  - Contacts - 联系人数据模型
  - ContactsUI - 联系人 UI 组件
  - UniformTypeIdentifiers - 文件类型识别

## 已知限制与待办事项 (TODO)

### 当前版本不支持

- ❌ 自定义列映射 UI（目前仅支持自动识别）
- ❌ 断点续导、失败重试
- ❌ 更完善的手机号/邮箱格式校验
- ❌ 支持更多字段（网址、生日、社交媒体等）
- ❌ 编辑联系人信息后再导出
- ❌ 支持导入 .xls (旧版 Excel 格式)

### 未来计划

- [ ] **自定义列映射**：允许用户手动选择每列对应的 VCF 字段
- [ ] **增量导入**：支持检测已存在联系人，选择性导入
- [ ] **批量编辑**：在预览界面提供基本的编辑功能
- [ ] **导入历史**：记录导入历史，支持撤销
- [ ] **更多格式**：支持 .xls、.ods 等格式
- [ ] **iCloud 同步**：支持从 iCloud Drive 直接导入

## 常见问题

### Q: 为什么 XLSX 文件无法打开？

A: 确保：
1. 文件格式正确（.xlsx，非 .xls）
2. 文件未损坏
3. 文件包含至少一个工作表和一行数据

### Q: 为什么联系人没有被识别？

A: 检查：
1. Excel 第一行是否为表头（不是数据行）
2. 是否包含"姓名"列（必需）
3. 表头关键词是否匹配（参考字段映射规则）

### Q: 为什么导入通讯录失败？

A: 可能原因：
1. 未授予通讯录权限
2. 联系人数据不完整（至少需要姓名）
3. 系统空间不足

解决方法：
- 检查 **设置 → 隐私 → 通讯录** 中的权限
- 使用"分享 VCF 文件"作为备选方案

### Q: 去重后联系人变少了？

A: 这是预期行为。去重规则：
- 姓名（不区分大小写）+ 规范化手机号相同 = 重复
- 会在预览界面显示：总数 X → 去重后 Y

## 贡献与反馈

如有问题或建议，请在 GitHub 仓库提交 Issue。

---

**版本**：1.0.0  
**最后更新**：2024-12
