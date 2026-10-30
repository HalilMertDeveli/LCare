/// DTOs for `/api/auth/*` and `/api/me` (see packages/contracts/openapi.json).
library;

class AccessTokenResponse {
  const AccessTokenResponse({
    required this.tokenType,
    required this.accessToken,
    required this.expiresIn,
    required this.refreshToken,
  });

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) =>
      AccessTokenResponse(
        tokenType: json['tokenType'] as String?,
        accessToken: json['accessToken'] as String,
        expiresIn: (json['expiresIn'] as num).toInt(),
        refreshToken: json['refreshToken'] as String,
      );

  final String? tokenType;
  final String accessToken;
  final int expiresIn;
  final String refreshToken;
}

/// `OrganizationRole` enum of the contract.
enum OrganizationRole {
  serviceManager('ServiceManager'),
  dispatcher('Dispatcher'),
  remoteSupportTechnician('RemoteSupportTechnician'),
  fieldTechnician('FieldTechnician'),
  customer('Customer');

  const OrganizationRole(this.apiValue);

  final String apiValue;

  static OrganizationRole? tryParse(String value) {
    for (final r in values) {
      if (r.apiValue == value) return r;
    }
    return null;
  }
}

const kPlatformSuperAdmin = 'PlatformSuperAdmin';

class MembershipDto {
  const MembershipDto({
    required this.organizationId,
    required this.organizationName,
    required this.roles,
    required this.customerId,
    required this.customerName,
  });

  factory MembershipDto.fromJson(Map<String, dynamic> json) => MembershipDto(
        organizationId: json['organizationId'] as String,
        organizationName: json['organizationName'] as String,
        // Unknown future roles are ignored rather than crashing the client.
        roles: (json['roles'] as List<dynamic>)
            .map((e) => OrganizationRole.tryParse(e as String))
            .whereType<OrganizationRole>()
            .toList(),
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String?,
      );

  final String organizationId;
  final String organizationName;
  final List<OrganizationRole> roles;
  final String? customerId;
  final String? customerName;
}

class MeResponse {
  const MeResponse({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.platformRoles,
    required this.memberships,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) => MeResponse(
        userId: json['userId'] as String,
        email: json['email'] as String,
        displayName: json['displayName'] as String,
        platformRoles:
            (json['platformRoles'] as List<dynamic>).cast<String>().toList(),
        memberships: (json['memberships'] as List<dynamic>)
            .map((e) => MembershipDto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String userId;
  final String email;
  final String displayName;
  final List<String> platformRoles;
  final List<MembershipDto> memberships;

  Set<OrganizationRole> get allRoles =>
      {for (final m in memberships) ...m.roles};

  /// Which UI shell this user gets (contracts.md → `GET /api/me`).
  AppShell get shell {
    final roles = allRoles;
    if (platformRoles.contains(kPlatformSuperAdmin) ||
        roles.contains(OrganizationRole.serviceManager) ||
        roles.contains(OrganizationRole.dispatcher)) {
      return AppShell.admin;
    }
    if (roles.contains(OrganizationRole.customer)) return AppShell.customer;
    if (roles.contains(OrganizationRole.remoteSupportTechnician) ||
        roles.contains(OrganizationRole.fieldTechnician)) {
      return AppShell.technician;
    }
    return AppShell.none;
  }
}

enum AppShell { admin, customer, technician, none }
