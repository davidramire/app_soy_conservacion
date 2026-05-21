export function notFound(request, response) {
  response.status(404).json({ message: `Route not found: ${request.method} ${request.originalUrl}` });
}

export function errorHandler(error, request, response, next) {
  if (response.headersSent) {
    return next(error);
  }

  const statusCode = error.statusCode ?? 500;
  const message = error.message ?? 'Unexpected server error';
  response.status(statusCode).json({
    message,
    ...(process.env.NODE_ENV === 'development' ? { stack: error.stack } : {}),
  });
}