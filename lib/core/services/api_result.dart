enum FailureType { timeout, noConnection, cancelled, badCertificate, badResponse, unknown }

class Failure {
  const Failure(this.message, {this.statusCode, this.type = FailureType.unknown});

  final String message;
  final int? statusCode;
  final FailureType type;

  @override
  String toString() => message;
}

sealed class ApiResult<T> {
  const ApiResult();

  R when<R>({required R Function(T data) success, required R Function(Failure failure) failure}) {
    return switch (this) {
      ApiSuccess<T>(:final data) => success(data),
      ApiError<T>(failure: final f) => failure(f),
    };
  }
}

final class ApiSuccess<T> extends ApiResult<T> {
  const ApiSuccess(this.data);

  final T data;
}

final class ApiError<T> extends ApiResult<T> {
  const ApiError(this.failure);

  final Failure failure;
}
