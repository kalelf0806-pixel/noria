enum InferenceMode {
  local('LOCAL'),
  cloud('CLOUD');

  const InferenceMode(this.label);
  final String label;
}

enum ComputeBackend {
  cpu('CPU'),
  gpu('GPU'),
  npu('NPU');

  const ComputeBackend(this.label);
  final String label;
}
