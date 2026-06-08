/// Unified error model for all Rust-to-Dart error reporting.
///
/// This is the only error type that crosses the FFI boundary.
/// Internal Rust errors are converted to this model in the facade layer.
#[derive(Debug)]
pub struct AppError {
    /// Stable machine-readable error code (e.g. "invalid_input", "internal")
    pub code: String,
    /// Developer-facing message; Flutter translates for end users
    pub message: String,
    /// Optional structured context (JSON or key-value pairs)
    pub details: Option<String>,
    /// Whether the caller may retry the operation
    pub retryable: bool,
}

impl AppError {
    pub fn invalid_input(message: impl Into<String>) -> Self {
        Self {
            code: "invalid_input".into(),
            message: message.into(),
            details: None,
            retryable: false,
        }
    }

    pub fn not_found(message: impl Into<String>) -> Self {
        Self {
            code: "not_found".into(),
            message: message.into(),
            details: None,
            retryable: false,
        }
    }

    pub fn internal(message: impl Into<String>) -> Self {
        Self {
            code: "internal".into(),
            message: message.into(),
            details: None,
            retryable: true,
        }
    }
}

impl std::fmt::Display for AppError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "[{}] {}", self.code, self.message)
    }
}
