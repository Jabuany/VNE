enum DiagnosticSeverity { info, warning, error }

/// Details intended for local display must omit private paths and credentials.
typedef Diagnostic = ({
  DiagnosticSeverity severity,
  String code,
  String message,
});
