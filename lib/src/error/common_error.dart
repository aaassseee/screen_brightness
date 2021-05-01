abstract class _CommonError extends Error {
  int get code;
  String get message;
}

class UnexpectedError extends _CommonError {
  @override
  int get code => -1;

  @override
  String get message => 'Unexpected error occureed';
}
