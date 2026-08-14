const resetScheme = 'spotifyclone';
const resetHost = 'auth';

String? resetTokenFromUri(Uri? uri) {
  if (uri == null ||
      uri.scheme != resetScheme ||
      uri.host != resetHost ||
      !uri.pathSegments.contains('reset')) {
    return null;
  }
  final token = uri.queryParameters['token'];
  return (token == null || token.isEmpty) ? null : token;
}