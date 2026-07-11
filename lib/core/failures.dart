import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

class ValidationFailure extends Failure {
  const ValidationFailure({required this.field, required this.reason});

  final String field;
  final String reason;

  @override
  List<Object?> get props => [field, reason];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
