use crate::types::{EvidenceOption, RuleView};

// ---------------------------------------------------------------------------
// Evidence options — what the user can select in the UI.
// Each entry represents a first-order predicate fact instance.
// Examples of corresponding predicates:
//   BugCheck(0xD1)  ≡  bugcheck:0xD1
//   RecentDriverUpdate(gpu)  ≡  recent_change:driver_update
//   Symptom(random_crash)    ≡  symptom:random_crash
// ---------------------------------------------------------------------------

pub fn evidence_options() -> Vec<EvidenceOption> {
    vec![
        // -- Bugcheck codes --
        EvidenceOption {
            id: "bugcheck:0xD1".into(),
            label: "蓝屏代码 0xD1".into(),
            category: "蓝屏代码".into(),
            description: "DRIVER_IRQL_NOT_LESS_OR_EQUAL — 驱动 IRQL 冲突".into(),
        },
        EvidenceOption {
            id: "bugcheck:0xEA".into(),
            label: "蓝屏代码 0xEA".into(),
            category: "蓝屏代码".into(),
            description: "THREAD_STUCK_IN_DEVICE_DRIVER — 驱动线程卡死".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x1A".into(),
            label: "蓝屏代码 0x1A".into(),
            category: "蓝屏代码".into(),
            description: "MEMORY_MANAGEMENT — 内存管理异常".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x50".into(),
            label: "蓝屏代码 0x50".into(),
            category: "蓝屏代码".into(),
            description: "PAGE_FAULT_IN_NONPAGED_AREA — 非分页区页面错误".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x7B".into(),
            label: "蓝屏代码 0x7B".into(),
            category: "蓝屏代码".into(),
            description: "INACCESSIBLE_BOOT_DEVICE — 无法访问启动设备".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x24".into(),
            label: "蓝屏代码 0x24".into(),
            category: "蓝屏代码".into(),
            description: "NTFS_FILE_SYSTEM — NTFS 文件系统错误".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x9F".into(),
            label: "蓝屏代码 0x9F".into(),
            category: "蓝屏代码".into(),
            description: "DRIVER_POWER_STATE_FAILURE — 驱动电源状态异常".into(),
        },
        EvidenceOption {
            id: "bugcheck:0x133".into(),
            label: "蓝屏代码 0x133".into(),
            category: "蓝屏代码".into(),
            description: "DPC_WATCHDOG_VIOLATION — DPC 超时死锁".into(),
        },

        // -- Crash scenarios --
        EvidenceOption {
            id: "symptom:random_crash".into(),
            label: "随机蓝屏".into(),
            category: "崩溃场景".into(),
            description: "系统在任何操作下均可能蓝屏，无明显规律".into(),
        },
        EvidenceOption {
            id: "symptom:bsod_under_load".into(),
            label: "高负载时蓝屏".into(),
            category: "崩溃场景".into(),
            description: "仅在运行大型程序、游戏或编译时蓝屏".into(),
        },
        EvidenceOption {
            id: "symptom:boot_failure".into(),
            label: "启动失败/无法进入系统".into(),
            category: "崩溃场景".into(),
            description: "开机后无法正常进入 Windows，蓝屏或反复重启".into(),
        },
        EvidenceOption {
            id: "symptom:bsod_after_update".into(),
            label: "更新后蓝屏".into(),
            category: "崩溃场景".into(),
            description: "Windows 更新或安装补丁后开始出现蓝屏".into(),
        },
        EvidenceOption {
            id: "symptom:sleep_wake_crash".into(),
            label: "休眠/唤醒时蓝屏".into(),
            category: "崩溃场景".into(),
            description: "电脑从睡眠、休眠状态唤醒时发生崩溃".into(),
        },
        EvidenceOption {
            id: "symptom:freeze_then_crash".into(),
            label: "画面卡死后蓝屏".into(),
            category: "崩溃场景".into(),
            description: "鼠标键盘卡死，画面定格数秒后才出现蓝屏".into(),
        },

        // -- Recent changes --
        EvidenceOption {
            id: "recent_change:driver_update".into(),
            label: "近期更新过驱动".into(),
            category: "近期变更".into(),
            description: "最近安装或更新了显卡、声卡、网卡等驱动程序".into(),
        },
        EvidenceOption {
            id: "recent_change:new_device".into(),
            label: "近期接入新外设".into(),
            category: "近期变更".into(),
            description: "最近连接了新的 USB 设备、打印机、外接硬盘等".into(),
        },
        EvidenceOption {
            id: "recent_change:ram_install".into(),
            label: "近期更换/加装内存".into(),
            category: "近期变更".into(),
            description: "最近更换、加装或拔插过内存条".into(),
        },
        EvidenceOption {
            id: "recent_change:ram_overclock".into(),
            label: "内存超频/开启 XMP".into(),
            category: "近期变更".into(),
            description: "内存以高于标称频率运行或开启了 XMP/DOCP 配置".into(),
        },
        EvidenceOption {
            id: "recent_change:system_update".into(),
            label: "近期 Windows 更新".into(),
            category: "近期变更".into(),
            description: "最近安装了 Windows 功能更新或质量更新".into(),
        },
        EvidenceOption {
            id: "recent_change:patch_install".into(),
            label: "近期安装安全补丁".into(),
            category: "近期变更".into(),
            description: "最近安装了 KB 补丁或第三方安全更新".into(),
        },
        EvidenceOption {
            id: "recent_change:psu_change".into(),
            label: "近期更换电源".into(),
            category: "近期变更".into(),
            description: "最近更换或调整过电源供应器 (PSU)".into(),
        },
        EvidenceOption {
            id: "recent_change:gpu_change".into(),
            label: "近期更换显卡".into(),
            category: "近期变更".into(),
            description: "最近更换、升级或拆装过独立显卡".into(),
        },
        EvidenceOption {
            id: "recent_change:system_file_corrupt".into(),
            label: "系统文件损坏".into(),
            category: "近期变更".into(),
            description: "系统提示文件损坏或 sfc /scannow 发现完整性冲突".into(),
        },
        EvidenceOption {
            id: "recent_change:bios_update".into(),
            label: "近期刷新过 BIOS".into(),
            category: "近期变更".into(),
            description: "最近升级或重置了主板 BIOS/UEFI 设置".into(),
        },
        EvidenceOption {
            id: "recent_change:undervolt".into(),
            label: "CPU/GPU 降压 (Undervolt)".into(),
            category: "近期变更".into(),
            description: "为降低温度而调低了处理器的运行电压".into(),
        },

        // -- Hardware symptoms --
        EvidenceOption {
            id: "hardware:device_manager_yellow".into(),
            label: "设备管理器有黄色感叹号".into(),
            category: "硬件症状".into(),
            description: "设备管理器中存在未识别或驱动异常的设备".into(),
        },
        EvidenceOption {
            id: "hardware:disk_noise".into(),
            label: "磁盘异响/坏道".into(),
            category: "硬件症状".into(),
            description: "硬盘发出咔嗒声，或磁盘检测工具报告坏道".into(),
        },
        EvidenceOption {
            id: "hardware:high_temp".into(),
            label: "CPU/GPU 温度过高".into(),
            category: "硬件症状".into(),
            description: "监控软件显示 CPU 或 GPU 温度持续高于 85°C".into(),
        },
        EvidenceOption {
            id: "hardware:auto_restart".into(),
            label: "频繁自动重启".into(),
            category: "硬件症状".into(),
            description: "蓝屏后系统频繁自动重启，甚至未进入桌面即重启".into(),
        },
        EvidenceOption {
            id: "hardware:antivirus_alert".into(),
            label: "杀毒软件报警".into(),
            category: "硬件症状".into(),
            description: "杀毒软件或 Windows Defender 报告检测到威胁".into(),
        },
        EvidenceOption {
            id: "symptom:abnormal_process".into(),
            label: "异常进程/高 CPU 占用".into(),
            category: "硬件症状".into(),
            description: "任务管理器中存在可疑进程或不明原因的高占用".into(),
        },
    ]
}

// ---------------------------------------------------------------------------
// Production rules — IF premises THEN conclusion.
//
// Each rule models a first-order implication, e.g.:
//   ∀x (BugCheck(x) ∧ RecentDriverUpdate(x) → Cause(driver_conflict, x))
//
// Forward chaining: when all premises are present in working memory, the
// conclusion fact is added and the rule trace is recorded.
// ---------------------------------------------------------------------------

pub struct ProductionRule {
    pub id: String,
    pub name: String,
    /// Fact IDs that must all be present in working memory
    pub premises: Vec<String>,
    /// Fact ID produced when the rule fires
    pub conclusion: String,
    /// Confidence level: "high", "medium", "low"
    pub confidence: String,
    /// Human-readable explanation
    pub explanation: String,
}

/// Returns all production rules in the knowledge base.
/// Rules are ordered so that rules producing the same conclusion are adjacent.
pub fn production_rules() -> Vec<ProductionRule> {
    vec![
        // ---- Driver conflict / driver corruption ----
        ProductionRule {
            id: "R1".into(),
            name: "D1 驱动更新冲突".into(),
            premises: vec!["bugcheck:0xD1".into(), "recent_change:driver_update".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "high".into(),
            explanation: "0xD1 常由驱动 IRQL 冲突引发；近期驱动更新进一步提高了驱动冲突的可能性".into(),
        },
        ProductionRule {
            id: "R2".into(),
            name: "EA 驱动卡死".into(),
            premises: vec!["bugcheck:0xEA".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "high".into(),
            explanation: "0xEA (THREAD_STUCK_IN_DEVICE_DRIVER) 明确指示设备驱动程序中的线程卡死".into(),
        },
        ProductionRule {
            id: "R3".into(),
            name: "D1 随机崩溃".into(),
            premises: vec!["bugcheck:0xD1".into(), "symptom:random_crash".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "medium".into(),
            explanation: "0xD1 配合随机崩溃模式，典型驱动冲突表现".into(),
        },
        ProductionRule {
            id: "R4".into(),
            name: "新外设 D1".into(),
            premises: vec!["recent_change:new_device".into(), "bugcheck:0xD1".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "high".into(),
            explanation: "新接入外设往往自带驱动或触发即插即用驱动安装，与现有驱动产生 IRQL 冲突".into(),
        },
        ProductionRule {
            id: "R5".into(),
            name: "驱动更新随机崩溃".into(),
            premises: vec!["recent_change:driver_update".into(), "symptom:random_crash".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "medium".into(),
            explanation: "驱动更新后出现随机崩溃，强烈暗示驱动版本不兼容或驱动文件损坏".into(),
        },
        ProductionRule {
            id: "R6".into(),
            name: "设备管理器异常".into(),
            premises: vec![
                "hardware:device_manager_yellow".into(),
                "symptom:random_crash".into(),
            ],
            conclusion: "cause:driver_conflict".into(),
            confidence: "medium".into(),
            explanation: "设备管理器中存在未识别设备同时伴随随机崩溃，提示驱动缺失或冲突".into(),
        },

        // ---- Memory fault ----
        ProductionRule {
            id: "R7".into(),
            name: "1A 内存管理".into(),
            premises: vec!["bugcheck:0x1A".into()],
            conclusion: "cause:memory_fault".into(),
            confidence: "high".into(),
            explanation: "0x1A (MEMORY_MANAGEMENT) 直接指向内存管理子系统异常，常见于硬件内存故障".into(),
        },
        ProductionRule {
            id: "R8".into(),
            name: "50 页面错误".into(),
            premises: vec!["bugcheck:0x50".into()],
            conclusion: "cause:memory_fault".into(),
            confidence: "high".into(),
            explanation: "0x50 (PAGE_FAULT_IN_NONPAGED_AREA) 表示引用了无效内存地址，通常与 RAM 硬件错误相关".into(),
        },
        ProductionRule {
            id: "R9".into(),
            name: "加装内存后随机崩溃".into(),
            premises: vec!["symptom:random_crash".into(), "recent_change:ram_install".into()],
            conclusion: "cause:memory_fault".into(),
            confidence: "high".into(),
            explanation: "更换或加装内存后出现随机崩溃，大概率是新内存不兼容、接触不良或本身有缺陷".into(),
        },
        ProductionRule {
            id: "R10".into(),
            name: "超频内存随机崩溃".into(),
            premises: vec!["symptom:random_crash".into(), "recent_change:ram_overclock".into()],
            conclusion: "cause:memory_fault".into(),
            confidence: "medium".into(),
            explanation: "内存超频或 XMP 配置不稳会导致随机数据损坏和蓝屏".into(),
        },

        // ---- Disk / filesystem corruption ----
        ProductionRule {
            id: "R11".into(),
            name: "7B 启动设备".into(),
            premises: vec!["bugcheck:0x7B".into()],
            conclusion: "cause:disk_corruption".into(),
            confidence: "high".into(),
            explanation: "0x7B (INACCESSIBLE_BOOT_DEVICE) 表示 Windows 无法访问启动磁盘".into(),
        },
        ProductionRule {
            id: "R12".into(),
            name: "24 NTFS 错误".into(),
            premises: vec!["bugcheck:0x24".into()],
            conclusion: "cause:disk_corruption".into(),
            confidence: "high".into(),
            explanation: "0x24 (NTFS_FILE_SYSTEM) 指向 NTFS 文件系统损坏或磁盘物理故障".into(),
        },
        ProductionRule {
            id: "R13".into(),
            name: "启动失败磁盘异响".into(),
            premises: vec!["symptom:boot_failure".into(), "hardware:disk_noise".into()],
            conclusion: "cause:disk_corruption".into(),
            confidence: "high".into(),
            explanation: "启动失败伴随磁盘异响/坏道，高度提示硬盘物理故障".into(),
        },
        ProductionRule {
            id: "R14".into(),
            name: "启动失败系统文件损坏".into(),
            premises: vec![
                "symptom:boot_failure".into(),
                "recent_change:system_file_corrupt".into(),
            ],
            conclusion: "cause:disk_corruption".into(),
            confidence: "medium".into(),
            explanation: "启动失败且存在系统文件损坏，可能是磁盘逻辑坏道或文件系统错误".into(),
        },

        // ---- Overheating / power instability ----
        ProductionRule {
            id: "R15".into(),
            name: "高负载蓝屏高温".into(),
            premises: vec!["symptom:bsod_under_load".into(), "hardware:high_temp".into()],
            conclusion: "cause:overheat".into(),
            confidence: "high".into(),
            explanation: "高负载下蓝屏且温度监测显示高温，典型过热保护触发或热降频不稳".into(),
        },
        ProductionRule {
            id: "R16".into(),
            name: "高负载蓝屏自动重启".into(),
            premises: vec!["symptom:bsod_under_load".into(), "hardware:auto_restart".into()],
            conclusion: "cause:overheat_or_power".into(),
            confidence: "medium".into(),
            explanation: "高负载蓝屏且频繁自动重启，可能为电源供电不足或过热保护触发".into(),
        },
        ProductionRule {
            id: "R17".into(),
            name: "更换电源".into(),
            premises: vec!["recent_change:psu_change".into()],
            conclusion: "cause:overheat_or_power".into(),
            confidence: "medium".into(),
            explanation: "近期更换电源后出现问题，可能新电源功率不足或供电不稳定".into(),
        },
        ProductionRule {
            id: "R18".into(),
            name: "更换显卡".into(),
            premises: vec!["recent_change:gpu_change".into()],
            conclusion: "cause:overheat_or_power".into(),
            confidence: "medium".into(),
            explanation: "近期更换显卡后出现问题，可能电源功率不足或显卡本身有硬件缺陷".into(),
        },

        // ---- System update / patch issues ----
        ProductionRule {
            id: "R19".into(),
            name: "更新后无法启动".into(),
            premises: vec!["recent_change:system_update".into(), "symptom:boot_failure".into()],
            conclusion: "cause:update_issue".into(),
            confidence: "high".into(),
            explanation: "Windows 更新后无法启动，更新可能引入了不兼容的驱动或损坏了启动配置".into(),
        },
        ProductionRule {
            id: "R20".into(),
            name: "更新后随机崩溃".into(),
            premises: vec!["recent_change:system_update".into(), "symptom:random_crash".into()],
            conclusion: "cause:update_issue".into(),
            confidence: "medium".into(),
            explanation: "Windows 更新后出现随机崩溃，更新可能引入了稳定性问题".into(),
        },
        ProductionRule {
            id: "R21".into(),
            name: "补丁后蓝屏".into(),
            premises: vec![
                "recent_change:patch_install".into(),
                "symptom:bsod_after_update".into(),
            ],
            conclusion: "cause:update_issue".into(),
            confidence: "high".into(),
            explanation: "安全补丁安装后蓝屏，补丁可能与现有驱动或软件冲突".into(),
        },

        // ---- Malware / system file damage ----
        ProductionRule {
            id: "R22".into(),
            name: "异常进程杀毒报警".into(),
            premises: vec![
                "symptom:abnormal_process".into(),
                "hardware:antivirus_alert".into(),
            ],
            conclusion: "cause:malware".into(),
            confidence: "high".into(),
            explanation: "异常进程配合杀毒软件报警，高度提示恶意软件感染".into(),
        },
        ProductionRule {
            id: "R23".into(),
            name: "系统文件破坏异常进程".into(),
            premises: vec![
                "recent_change:system_file_corrupt".into(),
                "symptom:abnormal_process".into(),
            ],
            conclusion: "cause:malware".into(),
            confidence: "medium".into(),
            explanation: "系统文件损坏且存在异常进程，可能是恶意软件篡改系统文件".into(),
        },

        // ---- Power Management & CPU Instability ----
        ProductionRule {
            id: "R24".into(),
            name: "9F 唤醒崩溃".into(),
            premises: vec!["bugcheck:0x9F".into(), "symptom:sleep_wake_crash".into()],
            conclusion: "cause:power_management".into(),
            confidence: "high".into(),
            explanation: "0x9F 与休眠唤醒强相关，通常是主板 BIOS 电源管理缺陷或存储/网卡驱动未响应电源状态切换".into(),
        },
        ProductionRule {
            id: "R25".into(),
            name: "BIOS 更新电源异常".into(),
            premises: vec!["recent_change:bios_update".into(), "symptom:sleep_wake_crash".into()],
            conclusion: "cause:power_management".into(),
            confidence: "medium".into(),
            explanation: "刷新 BIOS 后唤醒失败，可能是 BIOS 恢复了默认电源配置 (如 ErP) 与系统配置不符".into(),
        },
        ProductionRule {
            id: "R26".into(),
            name: "133 冻结后蓝屏".into(),
            premises: vec!["bugcheck:0x133".into(), "symptom:freeze_then_crash".into()],
            conclusion: "cause:driver_conflict".into(),
            confidence: "high".into(),
            explanation: "DPC_WATCHDOG_VIOLATION 常表现为先死机后蓝屏，原因是底层驱动 (常为磁盘控制器或网卡) 霸占了 CPU 无法释放".into(),
        },
        ProductionRule {
            id: "R27".into(),
            name: "降压导致随机崩溃".into(),
            premises: vec!["recent_change:undervolt".into(), "symptom:random_crash".into()],
            conclusion: "cause:cpu_instability".into(),
            confidence: "high".into(),
            explanation: "降压 (Undervolt) 幅度过大会导致 CPU 在电压跳变时指令计算错误，引发随机蓝屏".into(),
        },
        ProductionRule {
            id: "R28".into(),
            name: "降压导致高负载崩溃".into(),
            premises: vec!["recent_change:undervolt".into(), "symptom:bsod_under_load".into()],
            conclusion: "cause:cpu_instability".into(),
            confidence: "high".into(),
            explanation: "CPU 在高负载下需要更高的电流，过度降压会导致供电不稳，触发硬件级别报错".into(),
        },
    ]
}

/// Returns a `RuleView` for every production rule (for UI rule browsing).
pub fn rule_views() -> Vec<RuleView> {
    production_rules()
        .into_iter()
        .map(|r| RuleView {
            id: r.id,
            name: r.name,
            premises: r.premises,
            conclusion: r.conclusion,
            confidence: r.confidence,
            explanation: r.explanation,
        })
        .collect()
}

// ---------------------------------------------------------------------------
// Conclusion descriptions — used to build DiagnosisConclusion after inference.
// ---------------------------------------------------------------------------

pub struct ConclusionMeta {
    pub cause_id: String,
    pub title: String,
    pub severity: String,
    pub recommendations: Vec<String>,
}

pub fn conclusion_meta(cause_id: &str) -> Option<ConclusionMeta> {
    match cause_id {
        "cause:driver_conflict" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "驱动冲突/驱动损坏".into(),
            severity: "critical".into(),
            recommendations: vec![
                "进入安全模式，卸载最近安装的驱动程序".into(),
                "使用 DDU (Display Driver Uninstaller) 彻底清除显卡驱动后重装最新 WHQL 版本".into(),
                "拔掉近期接入的外设，逐一排查".into(),
                "运行 verifier.exe 开启驱动验证程序定位问题驱动".into(),
                "检查设备管理器中带黄色感叹号的设备并安装正确驱动".into(),
            ],
        }),
        "cause:memory_fault" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "内存故障".into(),
            severity: "critical".into(),
            recommendations: vec![
                "运行 Windows 内存诊断工具 (mdsched.exe) 进行完整检测".into(),
                "如果近期加装/更换过内存，尝试恢复原配置".into(),
                "关闭 XMP/DOCP，恢复内存为 JEDEC 标准频率".into(),
                "尝试单条内存启动，逐条排查故障内存条".into(),
                "使用 MemTest86 进行更全面的内存压力测试".into(),
            ],
        }),
        "cause:disk_corruption" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "磁盘或文件系统损坏".into(),
            severity: "critical".into(),
            recommendations: vec![
                "立即备份重要数据".into(),
                "运行 chkdsk /f /r 检查并修复磁盘错误".into(),
                "运行 sfc /scannow 修复系统文件".into(),
                "使用 CrystalDiskInfo 检查磁盘 S.M.A.R.T. 健康状态".into(),
                "如硬盘出现物理坏道，尽快更换新硬盘".into(),
            ],
        }),
        "cause:overheat" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "过热保护触发".into(),
            severity: "warning".into(),
            recommendations: vec![
                "清理机箱内部灰尘，特别是 CPU/GPU 散热器和风扇".into(),
                "检查散热器安装是否牢固，重新涂抹导热硅脂".into(),
                "改善机箱风道，增加机箱风扇".into(),
                "使用 HWMonitor 或 HWiNFO 在负载下监测温度".into(),
                "检查 CPU/GPU 风扇是否正常运转".into(),
            ],
        }),
        "cause:overheat_or_power" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "过热或电源不稳定".into(),
            severity: "warning".into(),
            recommendations: vec![
                "清理散热系统并监测温度".into(),
                "检查电源供应器额定功率是否满足整机需求".into(),
                "如近期更换过硬件，确认电源 +12V 各路供电充足".into(),
                "使用万用表或电源测试仪检查电源输出稳定性".into(),
                "尝试更换已知良好的电源进行交叉测试".into(),
            ],
        }),
        "cause:update_issue" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "系统更新/补丁问题".into(),
            severity: "warning".into(),
            recommendations: vec![
                "进入安全模式 → 设置 → Windows 更新 → 更新历史 → 卸载最新更新".into(),
                "使用系统还原点回滚到更新前的状态".into(),
                "运行 DISM /Online /Cleanup-Image /RestoreHealth 修复系统映像".into(),
                "暂时暂停 Windows 更新，等待微软发布修复补丁".into(),
                "检查更新相关日志：事件查看器 → Windows 日志 → 系统".into(),
            ],
        }),
        "cause:malware" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "恶意软件/系统文件破坏".into(),
            severity: "critical".into(),
            recommendations: vec![
                "在安全模式下运行 Windows Defender 脱机扫描".into(),
                "使用 Malwarebytes 或 HitmanPro 进行二次扫描".into(),
                "运行 sfc /scannow 修复被篡改的系统文件".into(),
                "检查启动项和计划任务中是否有可疑条目".into(),
                "如无法清除，考虑从已知良好的安装介质进行修复安装".into(),
            ],
        }),
        "cause:power_management" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "电源管理/BIOS ACPI 异常".into(),
            severity: "warning".into(),
            recommendations: vec![
                "在设备管理器中，取消勾选网卡/USB控制器的“允许计算机关闭此设备以节约电源”".into(),
                "检查主板官网是否有新的 BIOS 更新以修复 ACPI 休眠唤醒问题".into(),
                "进入控制面板，关闭“快速启动 (Fast Startup)”".into(),
                "在 BIOS 中检查睡眠状态支持 (如 S3/现代待机 S0ix) 是否正确配置".into(),
            ],
        }),
        "cause:cpu_instability" => Some(ConclusionMeta {
            cause_id: cause_id.into(),
            title: "CPU 供电不稳/降压过度".into(),
            severity: "warning".into(),
            recommendations: vec![
                "进入 BIOS 或使用 ThrottleStop/XTU 恢复 CPU 默认电压".into(),
                "如果必须降压，请每次回调 5-10mV 并进行长时间压力测试 (如 Prime95)".into(),
                "关闭主板 BIOS 中的自动 AI 超频选项".into(),
                "如果是主板防掉压 (LLC) 级别太低，可尝试调高一档 LLC".into(),
            ],
        }),
        _ => None,
    }
}
