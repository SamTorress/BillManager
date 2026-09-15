class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([
    this.message = 'Cannot Authorize User. Please log in again.',
  ]);

  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException([this.message = 'You don\'t have permission to do that.']);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final String message;
  ServerException([
    this.message = 'Something went wrong on the server. Please try again.',
  ]);

  @override
  String toString() => message;
}
