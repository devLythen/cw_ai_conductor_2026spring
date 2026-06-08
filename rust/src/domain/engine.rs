use crate::error::AppError;

/// Core domain logic: executes an action on a payload.
///
/// This is pure business logic — no FFI, no UI awareness.
/// All errors are returned as `AppError`.
pub fn execute(action: &str, payload: &str) -> Result<String, AppError> {
    match action {
        "echo" => Ok(payload.to_string()),
        "reverse" => Ok(payload.chars().rev().collect()),
        "analyze" => {
            if payload.is_empty() {
                return Err(AppError::invalid_input("payload must not be empty"));
            }
            let char_count = payload.chars().count();
            let word_count = payload.split_whitespace().count();
            Ok(format!("chars: {char_count}, words: {word_count}"))
        }
        _ => Err(AppError::not_found(format!(
            "unknown action: {action}"
        ))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn echo_returns_payload() {
        let result = execute("echo", "hello").unwrap();
        assert_eq!(result, "hello");
    }

    #[test]
    fn reverse_works() {
        let result = execute("reverse", "abc").unwrap();
        assert_eq!(result, "cba");
    }

    #[test]
    fn analyze_counts() {
        let result = execute("analyze", "hi there").unwrap();
        assert!(result.contains("chars: 8"));
        assert!(result.contains("words: 2"));
    }

    #[test]
    fn analyze_empty_rejected() {
        let err = execute("analyze", "").unwrap_err();
        assert_eq!(err.code, "invalid_input");
    }

    #[test]
    fn unknown_action_rejected() {
        let err = execute("bogus", "data").unwrap_err();
        assert_eq!(err.code, "not_found");
    }

    #[test]
    fn echo_empty_string() {
        let result = execute("echo", "").unwrap();
        assert_eq!(result, "");
    }

    #[test]
    fn reverse_unicode() {
        let result = execute("reverse", "你好").unwrap();
        assert_eq!(result, "好你");
    }
}
