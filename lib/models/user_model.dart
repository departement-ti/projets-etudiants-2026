enum UserRole {
  personneAge,
  assistant,
  doctor,
}

class UserModel {
  final String name;
  final String? dob;
  final String? gender;
  final String? nic;
  final String? address;
  final String? mobile;
  final UserRole role;

  UserModel({
    required this.name,
    this.dob,
    this.gender,
    this.nic,
    this.address,
    this.mobile,
    required this.role,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob,
      'gender': gender,
      'nic': nic,
      'address': address,
      'mobile': mobile,
      'role': role.name,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      dob: map['dob'],
      gender: map['gender'],
      nic: map['nic'],
      address: map['address'],
      mobile: map['mobile'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.personneAge,
      ),
    );
  }
}
