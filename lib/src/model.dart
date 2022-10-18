class AuthentificationState {
  static UserInformation? current;
}

class UserInformation {
  final bool isAuthenticated;
  final String? name;
  final Map<String, dynamic>? claims;
  final String? jwt;

  const UserInformation(this.isAuthenticated, this.name, this.claims, this.jwt);
}

class UserInformationUpdated {
  final UserInformation newUser;

  UserInformationUpdated(this.newUser);
}
