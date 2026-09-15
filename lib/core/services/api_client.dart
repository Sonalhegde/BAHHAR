import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base HTTP client connecting to the Python/FastAPI ML service
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : _baseUrl = baseUrl ?? 'http://localhost:8000',
        _httpClient = httpClient ?? http.Client();

  final String _baseUrl;
  final http.Client _httpClient;

  /// Default timeout for all requests
  static const Duration defaultTimeout = Duration(seconds: 30);

  /// Performs a GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _httpClient
          .get(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('GET request failed: $e');
    }
  }

  /// Performs a POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('POST request failed: $e');
    }
  }

  /// Performs a PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _httpClient
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('PUT request failed: $e');
    }
  }

  /// Performs a DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    
    try {
      final response = await _httpClient
          .delete(
            uri,
            headers: _buildHeaders(headers),
          )
          .timeout(timeout ?? defaultTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw ApiException('DELETE request failed: $e');
    }
  }

  /// Builds headers with default Content-Type
  Map<String, String> _buildHeaders(Map<String, String>? customHeaders) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?customHeaders,
    };
  }

  /// Handles HTTP response and throws appropriate exceptions
  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      try {
        return json.decode(response.body) as Map<String, dynamic>;
      } catch (e) {
        throw ApiException('Failed to parse response: $e');
      }
    } else if (response.statusCode == 400) {
      throw BadRequestException(
        'Bad request: ${response.body}',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode == 401) {
      throw UnauthorizedException(
        'Unauthorized: ${response.body}',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode == 404) {
      throw NotFoundException(
        'Not found: ${response.body}',
        statusCode: response.statusCode,
      );
    } else if (response.statusCode >= 500) {
      throw ServerException(
        'Server error: ${response.body}',
        statusCode: response.statusCode,
      );
    } else {
      throw ApiException(
        'Request failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Closes the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Base exception for API errors
class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Exception for 400 Bad Request errors
class BadRequestException extends ApiException {
  BadRequestException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Exception for 401 Unauthorized errors
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Exception for 404 Not Found errors
class NotFoundException extends ApiException {
  NotFoundException(super.message, {this.statusCode});
  final int? statusCode;
}

/// Exception for 500+ Server errors
class ServerException extends ApiException {
  ServerException(super.message, {this.statusCode});
  final int? statusCode;
}
