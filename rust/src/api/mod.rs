// FRB-scanned bridge module.
// Public functions here are auto-bridged to Dart by flutter_rust_bridge.
// Each function is a thin wrapper — real logic lives in facade/domain.

use crate::facade;
use crate::types::{
    AppInfo, DiagnosisRequest, DiagnosisResult, EvidenceOption, RuleView, TaskRequest, TaskResponse,
};

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

/// Returns application metadata (name, version, rust_version).
#[flutter_rust_bridge::frb(sync)]
pub fn app_info() -> AppInfo {
    facade::app_info()
}

/// Process a task via the Rust core engine (legacy).
pub fn process_task(request: TaskRequest) -> Result<TaskResponse, crate::error::AppError> {
    facade::process_task(request)
}

// ---------------------------------------------------------------------------
// WinBSOD Expert
// ---------------------------------------------------------------------------

/// Returns all available evidence options.
#[flutter_rust_bridge::frb(sync)]
pub fn evidence_options() -> Vec<EvidenceOption> {
    facade::evidence_options()
}

/// Returns all production rules (for knowledge-base browsing).
#[flutter_rust_bridge::frb(sync)]
pub fn rule_views() -> Vec<RuleView> {
    facade::rule_views()
}

/// Runs the forward-chaining diagnosis engine.
pub fn diagnose_blue_screen(
    request: DiagnosisRequest,
) -> Result<DiagnosisResult, crate::error::AppError> {
    facade::diagnose_blue_screen(request)
}
