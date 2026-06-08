// ---------------------------------------------------------------------------
// Legacy types — retained for backward compatibility with existing tests.
// ---------------------------------------------------------------------------

/// Application metadata returned by `app_info()`.
#[derive(Debug, Clone)]
pub struct AppInfo {
    pub name: String,
    pub version: String,
    pub rust_version: String,
}

/// A task submitted from Flutter to the Rust core for processing.
#[derive(Debug, Clone)]
pub struct TaskRequest {
    pub id: String,
    pub payload: String,
    pub action: String,
}

/// Result of processing a `TaskRequest`.
#[derive(Debug, Clone)]
pub struct TaskResponse {
    pub task_id: String,
    pub result: String,
    pub status: String,
}

// ---------------------------------------------------------------------------
// WinBSOD Expert — diagnosis types.
// ---------------------------------------------------------------------------

/// An evidence option presented to the user in the UI.
#[derive(Debug, Clone)]
pub struct EvidenceOption {
    /// Stable identifier used as a fact literal (e.g. "bugcheck:0xD1").
    pub id: String,
    /// Display label shown in the UI.
    pub label: String,
    /// Category for grouping (e.g. "蓝屏代码", "崩溃场景").
    pub category: String,
    /// Longer description / tooltip.
    pub description: String,
}

/// User's diagnosis request — just the list of selected evidence IDs.
#[derive(Debug, Clone)]
pub struct DiagnosisRequest {
    pub selected_evidence: Vec<String>,
}

/// A single diagnosis conclusion for a cause.
#[derive(Debug, Clone)]
pub struct DiagnosisConclusion {
    /// Cause fact ID (e.g. "cause:driver_conflict").
    pub id: String,
    /// Human-readable title (e.g. "驱动冲突/驱动损坏").
    pub title: String,
    /// Confidence level: "high", "medium", "low".
    pub confidence: String,
    /// Severity: "critical", "warning", "info".
    pub severity: String,
    /// Natural-language explanation including inference chain.
    pub explanation: String,
    /// Recommended actions.
    pub recommendations: Vec<String>,
}

/// Trace record of a single rule firing.
#[derive(Debug, Clone)]
pub struct RuleTrace {
    pub rule_id: String,
    pub rule_name: String,
    pub matched_facts: Vec<String>,
    pub produced_fact: String,
    pub explanation: String,
}

/// Full diagnosis result returned to Flutter.
#[derive(Debug, Clone)]
pub struct DiagnosisResult {
    /// Diagnosed causes.
    pub conclusions: Vec<DiagnosisConclusion>,
    /// All facts inferred during reasoning (excluding original evidence and causes).
    pub inferred_facts: Vec<String>,
    /// Complete firing trace for explanation.
    pub traces: Vec<RuleTrace>,
    /// Edge-case warnings (no match, weak evidence, conflicts).
    pub warnings: Vec<String>,
}

/// Read-only view of a production rule (for knowledge-base browsing in UI).
#[derive(Debug, Clone)]
pub struct RuleView {
    pub id: String,
    pub name: String,
    pub premises: Vec<String>,
    pub conclusion: String,
    pub confidence: String,
    pub explanation: String,
}
