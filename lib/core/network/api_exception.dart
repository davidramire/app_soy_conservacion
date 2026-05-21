enum ApiExceptionType {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  server,
  invalidResponse,
  unexpected,
}

class ApiException implements Exception {
  const ApiException({
    required this.type,
    required this.message,
    this.statusCode,
    this.uri,
    this.details,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Uri? uri;
  final Object? details;

  const ApiException.network({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.network,
          message: 'No se pudo conectar con el servidor.',
          uri: uri,
          details: details,
        );

  const ApiException.timeout({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.timeout,
          message: 'La solicitud excedió el tiempo de espera.',
          uri: uri,
          details: details,
        );

  const ApiException.unauthorized({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.unauthorized,
          message: 'La sesión ya no es válida.',
          uri: uri,
          details: details,
        );

  const ApiException.forbidden({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.forbidden,
          message: 'No tienes permisos para acceder a este recurso.',
          uri: uri,
          details: details,
        );

  const ApiException.notFound({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.notFound,
          message: 'El recurso solicitado no existe.',
          uri: uri,
          details: details,
        );

  const ApiException.server({required int? statusCode, Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.server,
          message: 'El servidor respondió con un error.',
          statusCode: statusCode,
          uri: uri,
          details: details,
        );

  const ApiException.invalidResponse({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.invalidResponse,
          message: 'La respuesta del servidor no tiene un formato válido.',
          uri: uri,
          details: details,
        );

  const ApiException.unexpected({Uri? uri, Object? details})
      : this(
          type: ApiExceptionType.unexpected,
          message: 'Ocurrió un error inesperado.',
          uri: uri,
          details: details,
        );

  @override
  String toString() => 'ApiException($type, statusCode: $statusCode, uri: $uri, message: $message)';
}