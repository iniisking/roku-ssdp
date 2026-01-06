enum DeviceType {
  roku,
  googleTv,
}

class DeviceModel {
  final String ipAddress;
  final DeviceType type;
  final String? name;

  DeviceModel({
    required this.ipAddress,
    required this.type,
    this.name,
  });

  String get displayName {
    if (name != null) return name!;
    return type == DeviceType.roku ? 'Roku Device' : 'Google TV';
  }

  @override
  String toString() => ipAddress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeviceModel &&
        other.ipAddress == ipAddress &&
        other.type == type;
  }

  @override
  int get hashCode => ipAddress.hashCode ^ type.hashCode;
}

