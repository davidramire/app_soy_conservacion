export function asyncHandler(handler) {
  return function asyncMiddleware(request, response, next) {
    Promise.resolve(handler(request, response, next)).catch(next);
  };
}