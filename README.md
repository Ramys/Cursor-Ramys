# Cursor 设备指纹修改工具

一个用于重置 Cursor 编辑器设备标识的 PowerShell 脚本工具。

## 🚀 快速使用

### 运行要求

- Windows 系统
- 管理员权限（必须）
- 已安装 Cursor

### 使用方法

**1. 以管理员身份打开 PowerShell**

- 按 `Win + X` → 选择"Windows PowerShell (管理员)"

**2. 执行命令**

```powershell
# 在线运行（推荐）
irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/cursor-free-vip/main/reset.ps1 | iex

# 或下载后运行
irm https://raw.githubusercontent.com/Huo-zai-feng-lang-li/cursor-free-vip/main/reset.ps1 -OutFile reset.ps1
.\reset.ps1

# 或本地运行（如果已克隆项目）
cd "项目目录路径"
.\reset.ps1
```

**3. 按提示操作**

- 脚本自动关闭 Cursor 进程
- 选择是否禁用自动更新
- 完成后重启 Cursor

### 功能说明

- 🔄 重置设备标识符
- 🗂️ 修改系统注册表
- 🗑️ 清理使用历史
- 🛡️ 自动备份配置
- 🚫 可选禁用更新

## ⚠️ 注意事项

### 风险提示

- 会修改系统注册表，需管理员权限
- 会清理 Cursor 使用历史和工作区数据
- 可能违反软件使用协议，请自行评估风险
- 部分杀毒软件可能误报

### 使用建议

- 使用前备份重要配置和项目文件
- 建议先在测试环境验证效果

## 📊 执行流程

```mermaid
graph TD
    A[🚀 启动脚本] --> B{🔐 检查管理员权限}
    B -->|❌ 否| C[⚠️ 提示需要管理员权限并退出]
    B -->|✅ 是| D[🔍 检测 Cursor 版本]
    D --> E[🛑 关闭 Cursor 进程]
    E --> F[💾 备份配置文件]
    F --> G[🎲 生成新设备标识]
    G --> H[📝 更新配置文件]
    H --> I[🗂️ 修改注册表]
    I --> J[🗑️ 清理历史数据]
    J --> K{🚫 是否禁用更新}
    K -->|✅ 是| L[🔒 创建更新阻止文件]
    K -->|❌ 否| M[✨ 完成]
    L --> M
    M --> N[🔄 提示重启 Cursor]

    %% 样式定义
    classDef startNode fill:#4CAF50,stroke:#2E7D32,stroke-width:3px,color:#fff
    classDef processNode fill:#2196F3,stroke:#1565C0,stroke-width:2px,color:#fff
    classDef decisionNode fill:#FF9800,stroke:#E65100,stroke-width:2px,color:#fff
    classDef errorNode fill:#F44336,stroke:#C62828,stroke-width:2px,color:#fff
    classDef successNode fill:#8BC34A,stroke:#558B2F,stroke-width:3px,color:#fff
    classDef backupNode fill:#9C27B0,stroke:#6A1B9A,stroke-width:2px,color:#fff
    classDef modifyNode fill:#FF5722,stroke:#D84315,stroke-width:2px,color:#fff

    %% 应用样式
    class A startNode
    class D,E,G,H,I,J,L processNode
    class B,K decisionNode
    class C errorNode
    class M,N successNode
    class F backupNode
```

## 🏗️ 系统架构

```mermaid
graph LR
    subgraph "🖥️ 用户层"
        U[👤 用户]
        PS[💻 PowerShell 管理员]
    end

    subgraph "🛠️ 脚本层"
        S[📜 reset.ps1]
        F1[🔍 权限检查]
        F2[📋 进程管理]
        F3[🎲 ID生成器]
        F4[💾 备份管理]
    end

    subgraph "📁 文件系统层"
        CF[📄 storage.json]
        BF[🗂️ 备份文件]
        HF[📚 历史文件]
        UF[🚫 更新阻止文件]
    end

    subgraph "🗃️ 注册表层"
        REG[🔑 MachineGuid]
        HKLM[🏛️ HKEY_LOCAL_MACHINE]
    end

    subgraph "🎯 Cursor 应用"
        APP[🖱️ Cursor.exe]
        DATA[📊 应用数据]
    end

    %% 连接关系
    U --> PS
    PS --> S
    S --> F1
    S --> F2
    S --> F3
    S --> F4

    F1 --> REG
    F2 --> APP
    F3 --> CF
    F4 --> BF

    S --> CF
    S --> HF
    S --> UF
    S --> REG

    REG --> HKLM
    CF --> DATA
    APP --> DATA

    %% 样式定义
    classDef userStyle fill:#E3F2FD,stroke:#1976D2,stroke-width:2px,color:#0D47A1
    classDef scriptStyle fill:#F3E5F5,stroke:#7B1FA2,stroke-width:2px,color:#4A148C
    classDef fileStyle fill:#E8F5E8,stroke:#388E3C,stroke-width:2px,color:#1B5E20
    classDef regStyle fill:#FFF3E0,stroke:#F57C00,stroke-width:2px,color:#E65100
    classDef appStyle fill:#FFEBEE,stroke:#D32F2F,stroke-width:2px,color:#B71C1C

    %% 应用样式
    class U,PS userStyle
    class S,F1,F2,F3,F4 scriptStyle
    class CF,BF,HF,UF fileStyle
    class REG,HKLM regStyle
    class APP,DATA appStyle
```

## 🔧 技术原理

### 修改内容

- **配置文件**: `%APPDATA%\Cursor\User\globalStorage\storage.json`
- **注册表**: `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography\MachineGuid`
- **清理目录**: History、workspaceStorage、state.vscdb 等
- **更新控制**: 创建 `%LOCALAPPDATA%\cursor-updater` 阻止文件

### 设备标识符

- `machineId`: auth0|user\_ + 随机十六进制
- `macMachineId`: 标准 UUID v4 格式
- `devDeviceId`: .NET GUID
- `sqmId`: 大写 GUID 格式

## 📄 免责声明

**本工具仅供学习和技术研究使用**

- 使用者需自行承担所有风险（系统损坏、数据丢失等）
- 可能违反软件使用协议，请自行评估法律风险
- 作者不承担任何直接或间接损失责任
- 仅限个人学习研究，禁止商业用途
- 不得用于绕过软件正当授权

### 技术支持

- 问题反馈：提交 Issue
- 交流学习：关注公众号【彩色之外】

---

**⚠️ 继续使用即表示您已理解并同意承担相应风险**
