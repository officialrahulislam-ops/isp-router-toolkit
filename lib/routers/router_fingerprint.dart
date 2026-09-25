/// A single piece of evidence gathered while probing a gateway over HTTP,
/// used by adapters' [RouterAdapter.canHandle] to decide ownership.
/// Kept as plain data (not tied to any adapter) so new fingerprints can be
/// added to the registry without touching adapter classes, and so the
/// same probe result can be tested against every adapter in turn.
class RouterProbeResult {
  final int? statusCode;
  final Map<String, String> headers;
  final String? bodySnippet; // first ~4KB, for title/known-string matching
  final String? finalUrl; // after redirects — some routers redirect to /cgi-bin/luci etc.

  const RouterProbeResult({
    this.statusCode,
    this.headers = const {},
    this.bodySnippet,
    this.finalUrl,
  });

  bool bodyContains(String needle) =>
      bodySnippet?.toLowerCase().contains(needle.toLowerCase()) ?? false;

  bool headerContains(String headerName, String needle) {
    final value = headers[headerName.toLowerCase()];
    return value?.toLowerCase().contains(needle.toLowerCase()) ?? false;
  }
}
