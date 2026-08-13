import 'package:dio/dio.dart';
import 'package:spotify_clone/core/api_client.dart';

String apiErrorMessage(Object error) {
  if (error is AuthException) {
    return error.message;
  }
  if (error is DioException) {
    if (error.type == DioExceptionType.badResponse) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      return 'Request failed (${error.response?.statusCode})';
    }
    return 'Cannot reach the server. Check your connection.';
  }
  return 'Something went wrong. Please try again.';
}