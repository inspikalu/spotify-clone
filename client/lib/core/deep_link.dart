import 'package:flutter/widgets.dart';

const resetScheme = 'spotifyclone';
const resetHost = 'auth';

String? extractResetToken() {
  final routeName =
      WidgetsBinding.instance.platformDispatcher.defaultRouteName;
  final uri = Uri.tryParse(routeName);
  if (uri == null ||
      uri.scheme != resetScheme ||
      uri.host != resetHost ||
      !uri.pathSegments.contains('reset')) {
    return null;
  }
  final token = uri.queryParameters['token'];
  return (token == null || token.isEmpty) ? null : token;
}