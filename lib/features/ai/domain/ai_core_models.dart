enum AiCoreStatus {
  unknown,
  checking,
  connected,
  disconnected,
  missingConfig,
  trialAvailable,
  trialExpired,
}

class AiCoreSnapshot {
  const AiCoreSnapshot({
    required this.status,
    required this.message,
    this.usingUserKey = false,
    this.builtInTrialAllowed = false,
    this.trialRemainingDays = 0,
  });

  const AiCoreSnapshot.unknown()
    : status = AiCoreStatus.unknown,
      message = 'AI核心未检测',
      usingUserKey = false,
      builtInTrialAllowed = false,
      trialRemainingDays = 0;

  final AiCoreStatus status;
  final String message;
  final bool usingUserKey;
  final bool builtInTrialAllowed;
  final int trialRemainingDays;

  bool get isWorking => status == AiCoreStatus.connected;
  bool get needsConfiguration =>
      status == AiCoreStatus.missingConfig ||
      status == AiCoreStatus.trialExpired;
}
