# WinBSOD Expert — Windows 蓝屏原因诊断产生式系统

## 课程作业说明

本系统为《人工智能导论》课程作业：**小型产生式系统设计与实现**。

### 实验目的

设计并实现一个面向 Windows 蓝屏（BSOD）原因诊断的产生式系统，验证以下知识点：

1. **一阶谓词逻辑知识表示**：将蓝屏现象、错误代码、系统症状表示为谓词实例（如 `BugCheck(0xD1)`、`RecentDriverUpdate(gpu)`、`Symptom(random_crash)`）。
2. **产生式规则**：以 `IF 前提1 ∧ 前提2 ... THEN 结论` 的形式编码领域知识。
3. **知识库与推理机分离**：知识库（规则、证据选项、结论元数据）独立于推理算法，便于规则增删和修改。
4. **正向推理**：从用户输入的初始证据出发，循环匹配规则并产生新事实，直至不再有新事实产生。
5. **人机交互界面**：图形化证据输入、诊断结论展示、推理链解释、异常匹配提示。

### 系统名称

**WinBSOD Expert：Windows 蓝屏原因诊断产生式系统**。

### 知识表示

#### 一阶谓词逻辑示例

诊断领域的事实用一元/二元谓词表达：

- `BugCheck(code)`：系统蓝屏时的错误检查码。
  - 例：`BugCheck(0xD1)` 表示蓝屏代码为 DRIVER_IRQL_NOT_LESS_OR_EQUAL。
- `RecentDriverUpdate(component)`：近期更新过某硬件驱动。
- `Symptom(type)`：观察到的崩溃场景类型。
- `HardwareSymptom(type)`：硬件层面的异常表现。
- `RecentChange(type)`：近期的系统或硬件变更。
- `Cause(reason)`：诊断结论。

系统内部使用字符串事实表示谓词实例，例如 `bugcheck:0xD1`、`symptom:random_crash`、`cause:driver_conflict`。

#### 产生式规则示例

```
R1: IF bugcheck:0xD1 ∧ recent_change:driver_update
    THEN cause:driver_conflict (confidence: high)

R7: IF bugcheck:0x1A
    THEN cause:memory_fault (confidence: high)

R15: IF symptom:bsod_under_load ∧ hardware:high_temp
     THEN cause:overheat (confidence: high)
```

完整规则库包含 23 条产生式规则，覆盖驱动冲突、内存故障、磁盘损坏、过热/电源不稳、系统更新问题、恶意软件六大类常见蓝屏原因。

### 模块结构

```
Flutter App (UI)
  ├─ lib/main.dart                    — 证据输入、诊断结论、推理链展示、规则浏览
  ├─ lib/rust/service.dart            — Dart service wrapper（封装 generated bridge）
  └─ lib/src/rust/                    — flutter_rust_bridge 自动生成代码
        ↓ FFI
Rust Crate
  ├─ rust/src/api/mod.rs              — FRB-scanned 桥接函数（薄封装）
  ├─ rust/src/facade.rs               — 稳定粗粒度 API
  ├─ rust/src/domain/
  │   ├─ knowledge_base.rs            — 知识库：证据选项、产生式规则、结论元数据
  │   └─ inference.rs                 — 推理机：正向链推理算法
  ├─ rust/src/types.rs                — 边界类型定义
  └─ rust/src/error.rs                — 统一错误模型
```

### 推理流程

1. 用户在 UI 中选择观察到的证据（蓝屏代码、崩溃场景、近期变更、硬件症状）。
2. 证据 ID 列表通过 FFI 传递至 Rust 推理机。
3. 推理机以正向链方式工作：
   - 将用户选择的证据作为初始事实放入综合数据库（工作内存）。
   - 循环扫描规则库：若某规则的所有前提均在工作内存中且该规则尚未被触发，则将其结论加入工作内存，并记录推理轨迹。
   - 当一轮扫描未产生任何新事实时停止。
4. 从工作内存中筛选 `cause:*` 事实作为诊断结论。
5. 生成异常提示：未命中规则、弱证据、多结论冲突等。
6. 结果返回 Flutter UI 展示。

### 覆盖的蓝屏原因

| 类别 | 典型代码 | 关联证据 |
|------|----------|----------|
| 驱动冲突/损坏 | 0xD1, 0xEA | 近期驱动更新、新外设、随机崩溃、设备管理器异常 |
| 内存故障 | 0x1A, 0x50 | 随机崩溃、加装内存、内存超频/XMP |
| 磁盘/文件系统损坏 | 0x7B, 0x24 | 启动失败、磁盘异响/坏道、系统文件损坏 |
| 过热/电源不稳 | — | 高负载蓝屏、温度过高、自动重启、更换电源/显卡 |
| 系统更新问题 | — | 更新后蓝屏、无法启动、近期安装补丁 |
| 恶意软件 | — | 异常进程、杀毒报警、系统文件校验失败 |

## 运行方式

> **注意：所有命令必须在项目根目录 `cw_ai_conductor_2026spring/` 下执行。**

```bash
# 1. 进入项目目录
cd cw_ai_conductor_2026spring

# 2. 安装依赖
flutter pub get

# 3. （修改 Rust API 后）重新生成 bridge 代码
flutter_rust_bridge_codegen generate

# 4. 运行 Rust 单元测试
cd rust && cargo test && cd ..

# 5. 运行 Flutter 测试
flutter test

# 6. 静态分析
flutter analyze

# 7. 运行应用
flutter run
```

## 工具链要求

| 工具 | 版本 |
|------|------|
| Flutter | 3.41.2 |
| Dart | 3.11.0 |
| Rust | 1.95.0 |
| flutter_rust_bridge_codegen | 2.12.0 |

## 架构原则

- **Flutter** 负责 UI、交互、状态展示和用户反馈。
- **Rust** 负责平台无关的核心逻辑（推理机、知识库），不感知 Widget、BuildContext 或 Flutter 生命周期。
- **Dart service wrapper**（`lib/rust/service.dart`）隔离 UI 与自动生成代码的变更。
- **Facade 层**提供稳定粗粒度 API；所有错误统一为 `AppError` 跨越 FFI。
- **知识库和推理机完全分离**：`knowledge_base.rs` 仅保存规则和数据，`inference.rs` 仅实现推理算法。
