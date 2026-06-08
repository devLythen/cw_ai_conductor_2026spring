use std::collections::HashSet;

use crate::error::AppError;
use crate::types::{DiagnosisConclusion, DiagnosisRequest, DiagnosisResult, RuleTrace};

use super::knowledge_base::{self, conclusion_meta, ProductionRule};

/// Run forward-chaining inference from user-selected evidence.
///
/// Algorithm:
/// 1. Seed working memory with the user's selected fact IDs.
/// 2. Repeatedly scan the rule base, firing any rule whose premises are
///    fully satisfied and that has not fired yet in this session.
/// 3. Stop when a pass produces no new facts.
/// 4. Collect all `cause:*` facts as conclusions.
/// 5. Generate warnings for edge cases (no rules fired, weak evidence, etc.).
pub fn diagnose(request: &DiagnosisRequest) -> Result<DiagnosisResult, AppError> {
    if request.selected_evidence.is_empty() {
        return Err(AppError::invalid_input(
            "请至少选择一条证据以启动推理（请勾选您遇到的蓝屏现象或症状）",
        ));
    }

    let rules = knowledge_base::production_rules();

    // --- working memory: facts known to be true ---
    let mut facts: HashSet<String> = request.selected_evidence.iter().cloned().collect();

    // --- records of fired rules ---
    let mut traces: Vec<RuleTrace> = Vec::new();
    let mut fired: HashSet<String> = HashSet::new();

    // --- forward-chaining loop ---
    loop {
        let mut new_fact_added = false;

        for rule in &rules {
            if fired.contains(&rule.id) {
                continue;
            }
            if rule.premises.iter().all(|p| facts.contains(p)) {
                // Rule fires
                let is_new = facts.insert(rule.conclusion.clone());
                fired.insert(rule.id.clone());
                traces.push(RuleTrace {
                    rule_id: rule.id.clone(),
                    rule_name: rule.name.clone(),
                    matched_facts: rule.premises.clone(),
                    produced_fact: rule.conclusion.clone(),
                    explanation: rule.explanation.clone(),
                });
                if is_new {
                    new_fact_added = true;
                }
            }
        }

        if !new_fact_added {
            break;
        }
    }

    // --- collect cause:* conclusions ---
    let cause_facts: Vec<String> = facts
        .iter()
        .filter(|f| f.starts_with("cause:"))
        .cloned()
        .collect();

    let conclusions: Vec<DiagnosisConclusion> = cause_facts
        .iter()
        .filter_map(|c| {
            conclusion_meta(c).map(|meta| DiagnosisConclusion {
                id: meta.cause_id.clone(),
                title: meta.title,
                confidence: best_confidence_for_cause(c, &rules, &traces),
                severity: meta.severity,
                explanation: build_explanation(c, &traces),
                recommendations: meta.recommendations,
            })
        })
        .collect();

    // --- inferred facts (excluding original evidence and cause facts) ---
    let inferred_facts: Vec<String> = facts
        .iter()
        .filter(|f| !request.selected_evidence.contains(f) && !f.starts_with("cause:"))
        .cloned()
        .collect();

    // --- warnings ---
    let warnings = generate_warnings(&request.selected_evidence, &traces, &conclusions);

    Ok(DiagnosisResult {
        conclusions,
        inferred_facts,
        traces,
        warnings,
    })
}

/// Pick the highest confidence among rules that produced this cause.
fn best_confidence_for_cause(
    cause: &str,
    rules: &[ProductionRule],
    traces: &[RuleTrace],
) -> String {
    let confidences: Vec<&str> = traces
        .iter()
        .filter(|t| t.produced_fact == cause)
        .filter_map(|t| {
            rules
                .iter()
                .find(|r| r.id == t.rule_id)
                .map(|r| r.confidence.as_str())
        })
        .collect();

    if confidences.iter().any(|c| *c == "high") {
        "high".into()
    } else if confidences.iter().any(|c| *c == "medium") {
        "medium".into()
    } else if !confidences.is_empty() {
        "low".into()
    } else {
        "medium".into()
    }
}

/// Build a natural-language explanation string from rule traces for a cause.
fn build_explanation(cause: &str, traces: &[RuleTrace]) -> String {
    let related: Vec<&RuleTrace> = traces
        .iter()
        .filter(|t| t.produced_fact == cause)
        .collect();

    if related.is_empty() {
        return "无详细推理链可用".into();
    }

    related
        .iter()
        .map(|t| {
            format!(
                "[{}] {}：{} → {}",
                t.rule_id, t.rule_name, t.explanation, t.produced_fact
            )
        })
        .collect::<Vec<_>>()
        .join("；")
}

/// Generate warnings for edge cases.
fn generate_warnings(
    selected: &[String],
    traces: &[RuleTrace],
    conclusions: &[DiagnosisConclusion],
) -> Vec<String> {
    let mut warnings: Vec<String> = Vec::new();

    // No rule fired at all
    if traces.is_empty() {
        warnings.push(
            "未命中任何规则：您选择的证据组合不足以触发已有产生式规则。请尝试提供更多证据（如蓝屏代码），或检查证据是否互相矛盾。".into(),
        );
    }

    // No cause identified despite rules firing (should not normally happen)
    if !traces.is_empty() && conclusions.is_empty() {
        warnings.push(
            "推理链存在但未推导出明确原因，可能存在规则冲突或知识库不完整。".into(),
        );
    }

    // Weak evidence: no bugcheck code, no hardware symptom, only soft symptoms
    let has_bugcheck = selected.iter().any(|s| s.starts_with("bugcheck:"));
    let has_hardware = selected.iter().any(|s| s.starts_with("hardware:"));

    if !has_bugcheck && !has_hardware && !traces.is_empty() {
        warnings.push(
            "提示：您未提供蓝屏代码或硬件症状，当前基于软证据的推理置信度可能偏低。建议提供蓝屏错误代码以获得更准确的诊断。".into(),
        );
    }

    // Conflicting evidence heuristics
    let has_driver_update = selected.contains(&"recent_change:driver_update".to_string());
    let has_ram_change = selected.contains(&"recent_change:ram_install".to_string())
        || selected.contains(&"recent_change:ram_overclock".to_string());

    if has_driver_update && has_ram_change && has_bugcheck {
        warnings.push(
            "注意：您同时报告了驱动更新和内存变更。蓝屏可能由多种因素叠加引起，建议逐一排查。".into(),
        );
    }

    // Multiple causes found
    if conclusions.len() >= 2 {
        warnings.push(
            "检测到多种可能原因，系统可能同时存在多个问题。建议按严重程度从高到低逐一排查。".into(),
        );
    }

    warnings
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::types::DiagnosisRequest;

    #[test]
    fn empty_evidence_rejected() {
        let req = DiagnosisRequest {
            selected_evidence: vec![],
        };
        let err = diagnose(&req).unwrap_err();
        assert_eq!(err.code, "invalid_input");
    }

    #[test]
    fn driver_conflict_from_d1_and_driver_update() {
        let req = DiagnosisRequest {
            selected_evidence: vec![
                "bugcheck:0xD1".into(),
                "recent_change:driver_update".into(),
            ],
        };
        let result = diagnose(&req).unwrap();
        assert!(!result.traces.is_empty(), "至少应有一条规则命中");
        assert!(
            result
                .conclusions
                .iter()
                .any(|c| c.id == "cause:driver_conflict"),
            "应包含驱动冲突结论"
        );
        assert!(result.warnings.is_empty(), "正常推理不应出现警告");
    }

    #[test]
    fn memory_fault_from_1a() {
        let req = DiagnosisRequest {
            selected_evidence: vec!["bugcheck:0x1A".into()],
        };
        let result = diagnose(&req).unwrap();
        assert!(
            result
                .conclusions
                .iter()
                .any(|c| c.id == "cause:memory_fault"),
            "0x1A 应推导出内存故障"
        );
    }

    #[test]
    fn no_rules_fired_warning() {
        let req = DiagnosisRequest {
            selected_evidence: vec!["symptom:random_crash".into()],
        };
        let result = diagnose(&req).unwrap();
        assert!(result.traces.is_empty(), "仅 random_crash 不应命中规则");
        assert!(
            result.warnings.iter().any(|w| w.contains("未命中任何规则")),
            "应提示未命中任何规则"
        );
    }

    #[test]
    fn multiple_causes_from_strong_evidence() {
        let req = DiagnosisRequest {
            selected_evidence: vec![
                "bugcheck:0xD1".into(),
                "bugcheck:0x1A".into(),
                "recent_change:driver_update".into(),
            ],
        };
        let result = diagnose(&req).unwrap();
        // 0xD1 + driver_update → driver_conflict; 0x1A → memory_fault
        let has_driver = result
            .conclusions
            .iter()
            .any(|c| c.id == "cause:driver_conflict");
        let has_memory = result
            .conclusions
            .iter()
            .any(|c| c.id == "cause:memory_fault");
        assert!(has_driver);
        assert!(has_memory);
        assert!(
            result.warnings.iter().any(|w| w.contains("多种可能原因")),
            "多结论应触发警告"
        );
    }

    #[test]
    fn confidence_is_high_for_strong_match() {
        let req = DiagnosisRequest {
            selected_evidence: vec!["bugcheck:0xEA".into()],
        };
        let result = diagnose(&req).unwrap();
        let c = result
            .conclusions
            .iter()
            .find(|c| c.id == "cause:driver_conflict")
            .unwrap();
        assert_eq!(c.confidence, "high");
    }

    #[test]
    fn inferred_facts_are_reported() {
        // R15: bsod_under_load + high_temp → overheat
        let req = DiagnosisRequest {
            selected_evidence: vec![
                "symptom:bsod_under_load".into(),
                "hardware:high_temp".into(),
            ],
        };
        let result = diagnose(&req).unwrap();
        assert!(
            result.conclusions.iter().any(|c| c.id == "cause:overheat"),
            "cause:overheat 应在结论中"
        );
    }
}
