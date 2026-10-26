/// Raw Bluetooth adapter availability, mirrored from the platform plugin.
enum BleAdapterStatus {
  unknown,
  unsupported,
  unauthorized,
  poweredOff,
  poweredOn;

  bool get isReady => this == BleAdapterStatus.poweredOn;
}

/// High-level state of the scanning session — drives the permission/boot gate.
enum BleSessionStatus {
  initializing,

  /// The user still has to grant the runtime BLE permissions.
  permissionRequired,
  permissionDenied,
  permissionPermanentlyDenied,

  /// Permission OK but the radio is off / unavailable.
  adapterOff,
  adapterUnsupported,
  unauthorized,

  scanning,
  paused,
  demoMode,
  error,
  idle;

  bool get isScanningActive => this == BleSessionStatus.scanning || this == BleSessionStatus.demoMode;
  bool get needsGate =>
      this == BleSessionStatus.initializing ||
      this == BleSessionStatus.permissionRequired ||
      this == BleSessionStatus.permissionDenied ||
      this == BleSessionStatus.permissionPermanentlyDenied ||
      this == BleSessionStatus.adapterOff ||
      this == BleSessionStatus.adapterUnsupported ||
      this == BleSessionStatus.unauthorized ||
      this == BleSessionStatus.error;
}
