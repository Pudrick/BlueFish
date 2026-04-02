/// A lightweight Result type for error handling.
///
/// Use this instead of try-catch to ensure errors are explicitly handled.
sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  /// Returns the data if this is a Success, otherwise returns null.
  T? get dataOrNull => switch (this) {
    Success(:final data) => data,
    Failure() => null,
  };

  /// Returns the data if this is a Success, otherwise throws.
  T get dataOrThrow => switch (this) {
    Success(:final data) => data,
    Failure(:final message, :final exception) =>
      throw exception ?? Exception(message),
  };

  /// Transforms the data if this is a Success.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success(:final data) => Success(transform(data)),
    Failure(:final message, :final exception) => Failure(message, exception),
  };

  /// Executes the appropriate callback based on the result type.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message, Exception? exception) failure,
  }) => switch (this) {
    Success(:final data) => success(data),
    Failure(:final message, :final exception) => failure(message, exception),
  };
}

/// Represents a successful result containing data.
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success($data)';
}

/// Represents a failed result containing an error message and optional exception.
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() =>
      'Failure($message${exception != null ? ', $exception' : ''})';
}
