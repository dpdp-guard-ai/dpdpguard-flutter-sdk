/// Plain Dart response models for the `/api/v1` wire shapes
/// (`/home/user/dpdpbot/openapi/v1.yaml`). Each `fromJson` factory reads only
/// the keys it needs from the decoded `Map<String, dynamic>` and never
/// validates that the map contains *only* the expected keys — per ADR-002
/// D4, this SDK must keep working when the server adds a new response
/// field.

int _asInt(dynamic value) => (value as num).toInt();

int? _asIntOrNull(dynamic value) => value == null ? null : (value as num).toInt();

/// `GET /api/v1/org/{slug}` response.
class OrgSummary {
  final String orgId;
  final String name;
  final String slug;

  const OrgSummary({required this.orgId, required this.name, required this.slug});

  factory OrgSummary.fromJson(Map<String, dynamic> json) {
    return OrgSummary(
      orgId: json['orgId'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
    );
  }
}

/// One entry of a [Notice]'s `itemized` list.
class NoticeItem {
  final String purpose;
  final String personalDataDescription;

  const NoticeItem({required this.purpose, required this.personalDataDescription});

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    return NoticeItem(
      purpose: json['purpose'] as String,
      personalDataDescription: json['personalDataDescription'] as String,
    );
  }
}

/// A published (or, for staff surfaces, draft) consent notice.
class Notice {
  final String id;
  final String organizationId;
  final int version;
  final List<NoticeItem> itemized;

  /// Map of language code to `{ title, body }`.
  final Map<String, dynamic> content;
  final String status;

  const Notice({
    required this.id,
    required this.organizationId,
    required this.version,
    required this.itemized,
    required this.content,
    required this.status,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    final itemizedJson = json['itemized'] as List<dynamic>? ?? const [];
    return Notice(
      id: json['_id'] as String,
      organizationId: json['organizationId'] as String,
      version: _asInt(json['version']),
      itemized: itemizedJson
          .map((item) => NoticeItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      content: (json['content'] as Map<String, dynamic>?) ?? const {},
      status: json['status'] as String,
    );
  }
}

/// `POST /api/v1/org/{orgId}/banner-config` (well, `GET`) response.
class BannerConfig {
  final Map<String, dynamic>? bannerSettings;
  final int configVersion;

  const BannerConfig({this.bannerSettings, required this.configVersion});

  factory BannerConfig.fromJson(Map<String, dynamic> json) {
    return BannerConfig(
      bannerSettings: json['bannerSettings'] as Map<String, dynamic>?,
      configVersion: _asInt(json['configVersion']),
    );
  }
}

/// `POST /api/v1/auth/broker-token` response.
class BrokeredToken {
  final String accessToken;

  /// Unix epoch milliseconds.
  final int expiresAt;
  final String tokenType;

  const BrokeredToken({
    required this.accessToken,
    required this.expiresAt,
    required this.tokenType,
  });

  factory BrokeredToken.fromJson(Map<String, dynamic> json) {
    return BrokeredToken(
      accessToken: json['accessToken'] as String,
      expiresAt: _asInt(json['expiresAt']),
      tokenType: json['tokenType'] as String,
    );
  }
}

/// One entry of a [LinkAnonymousConsentResult]'s `needsReconsent` list.
class NeedsReconsentEntry {
  final String noticeId;
  final String purpose;

  const NeedsReconsentEntry({required this.noticeId, required this.purpose});

  factory NeedsReconsentEntry.fromJson(Map<String, dynamic> json) {
    return NeedsReconsentEntry(
      noticeId: json['noticeId'] as String,
      purpose: json['purpose'] as String,
    );
  }
}

/// `POST /api/v1/link-anonymous-consent` response.
class LinkAnonymousConsentResult {
  final int linkedCount;
  final List<NeedsReconsentEntry> needsReconsent;

  const LinkAnonymousConsentResult({
    required this.linkedCount,
    required this.needsReconsent,
  });

  factory LinkAnonymousConsentResult.fromJson(Map<String, dynamic> json) {
    final list = json['needsReconsent'] as List<dynamic>? ?? const [];
    return LinkAnonymousConsentResult(
      linkedCount: _asInt(json['linkedCount']),
      needsReconsent: list
          .map((e) => NeedsReconsentEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A Data Subject Request (spec §4.2).
class DsrRequest {
  final String requestId;

  /// One of `"summary"`, `"processors"`, `"correction"`, `"erasure"`.
  final String type;

  /// One of `"pending"`, `"in_progress"`, `"completed"`, `"rejected"`.
  final String status;

  /// SLA deadline, Unix epoch milliseconds.
  final int? dueAt;
  final String? requestDetails;

  const DsrRequest({
    required this.requestId,
    required this.type,
    required this.status,
    this.dueAt,
    this.requestDetails,
  });

  factory DsrRequest.fromJson(Map<String, dynamic> json) {
    return DsrRequest(
      requestId: json['requestId'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      dueAt: _asIntOrNull(json['dueAt']),
      requestDetails: json['requestDetails'] as String?,
    );
  }
}

/// A grievance (spec §4.2).
class Grievance {
  final String grievanceId;
  final String subject;
  final String description;

  /// One of `"open"`, `"in_progress"`, `"resolved"`.
  final String status;

  /// SLA deadline, Unix epoch milliseconds.
  final int dueAt;
  final int? respondedAt;
  final String? response;

  const Grievance({
    required this.grievanceId,
    required this.subject,
    required this.description,
    required this.status,
    required this.dueAt,
    this.respondedAt,
    this.response,
  });

  factory Grievance.fromJson(Map<String, dynamic> json) {
    return Grievance(
      grievanceId: json['grievanceId'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      dueAt: _asInt(json['dueAt']),
      respondedAt: _asIntOrNull(json['respondedAt']),
      response: json['response'] as String?,
    );
  }
}

/// A successor nomination (spec §4.2).
class Nomination {
  final String nominationId;
  final String nomineeName;
  final String nomineeContact;

  /// One of `"active"`, `"revoked"`.
  final String status;

  const Nomination({
    required this.nominationId,
    required this.nomineeName,
    required this.nomineeContact,
    required this.status,
  });

  factory Nomination.fromJson(Map<String, dynamic> json) {
    return Nomination(
      nominationId: json['nominationId'] as String,
      nomineeName: json['nomineeName'] as String,
      nomineeContact: json['nomineeContact'] as String,
      status: json['status'] as String,
    );
  }
}
