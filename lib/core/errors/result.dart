import 'failures.dart';

/// Başarı ya da [Failure] döndüren işlemler için tip güvenli sonuç.
sealed class Result<T> {
  const Result();

  const factory Result.success(T value) = Success<T>;
  const factory Result.failure(Failure failure) = Err<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Err<T>;

  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Err() => null,
  };

  /// Başarısızlıkta [Failure]'ı fırlatır; `guard` içinde zincirleme
  /// işlemler için.
  T get requireValue => switch (this) {
    Success(:final value) => value,
    Err(:final failure) => throw failure,
  };

  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Err(:final failure) => failure,
  };

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(:final value) => success(value),
      Err(failure: final f) => failure(f),
    };
  }

  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success(:final value) => Result.success(transform(value)),
      Err(:final failure) => Result.failure(failure),
    };
  }
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
