class UserInformation {
  final bool isAuthenticated;
  final String? name;
  final Map<String, dynamic>? claims;

  const UserInformation(this.isAuthenticated, this.name, this.claims);
}

class UserInformationUpdated {
  final UserInformation newUser;

  UserInformationUpdated(this.newUser);
}
