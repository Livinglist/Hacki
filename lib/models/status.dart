enum Status {
  idle,
  inProgress,
  success,
  failure,
}

extension StatusExtension on Status {
  bool get isLoading => this == Status.inProgress;

  bool get isSuccessful => this == Status.success;

  bool get hasError => this == Status.failure;
}
