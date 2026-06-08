use crate::domain::{engine, inference, knowledge_base};
use crate::error::AppError;
use crate::types::{
    AppInfo, DiagnosisRequest, DiagnosisResult, EvidenceOption, RuleView, TaskRequest, TaskResponse,
};

// ---------------------------------------------------------------------------
// App info
// ---------------------------------------------------------------------------

/// Returns application metadata.
pub fn app_info() -> AppInfo {
    AppInfo {
        name: "WinBSOD Expert".into(),
        version: env!("CARGO_PKG_VERSION").into(),
        rust_version: option_env!("CARGO_PKG_RUST_VERSION")
            .unwrap_or("unknown")
            .into(),
    }
}

// ---------------------------------------------------------------------------
// Legacy task processing (kept for backward compat)
// ---------------------------------------------------------------------------

/// Processes a task through the domain engine.
pub fn process_task(request: TaskRequest) -> Result<TaskResponse, AppError> {
    let result = engine::execute(&request.action, &request.payload)?;
    Ok(TaskResponse {
        task_id: request.id,
        result,
        status: "ok".into(),
    })
}

// ---------------------------------------------------------------------------
// WinBSOD Expert — diagnosis APIs
// ---------------------------------------------------------------------------

/// Returns all evidence options the user can select.
pub fn evidence_options() -> Vec<EvidenceOption> {
    knowledge_base::evidence_options()
}

/// Returns all production rules for knowledge-base browsing.
pub fn rule_views() -> Vec<RuleView> {
    knowledge_base::rule_views()
}

/// Runs forward-chaining diagnosis from user-selected evidence.
pub fn diagnose_blue_screen(request: DiagnosisRequest) -> Result<DiagnosisResult, AppError> {
    inference::diagnose(&request)
}
