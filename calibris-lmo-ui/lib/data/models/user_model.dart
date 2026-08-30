enum UserRole { lmo, admin, applicant, vendor }

class UserModel {
  final String id;
  final String employeeId;     // login identifier for both roles
  final String name;
  final String district;
  final UserRole role;
  final String? email;
  final String? phone;
  final String? businessName;
  final String? addressLine;
  final String? city;
  final String? state;
  final String? pincode;
  final String? gstNumber;

  const UserModel({
    required this.id,
    required this.employeeId,
    required this.name,
    required this.district,
    required this.role,
    this.email,
    this.phone,
    this.businessName,
    this.addressLine,
    this.city,
    this.state,
    this.pincode,
    this.gstNumber,
  });

  String get effectiveEmail => email ?? '$employeeId@calibris.gov.in';

  bool get isVendor => role == UserRole.vendor || role == UserRole.applicant;
  bool get isLmo => role == UserRole.lmo;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String,
      name: json['name'] as String,
      district: json['district'] as String,
      role: UserRole.values.firstWhere((e) => e.name == json['role']),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      businessName: json['businessName'] as String?,
      addressLine: json['addressLine'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      pincode: json['pincode'] as String?,
      gstNumber: json['gstNumber'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'name': name,
      'district': district,
      'role': role.name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gstNumber': gstNumber,
    };
  }

  UserModel copyWith({
    String? id,
    String? employeeId,
    String? name,
    String? district,
    UserRole? role,
    String? email,
    String? phone,
    String? businessName,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    String? gstNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      name: name ?? this.name,
      district: district ?? this.district,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstNumber: gstNumber ?? this.gstNumber,
    );
  }
}

