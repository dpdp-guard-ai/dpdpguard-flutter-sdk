/// Typed request/response shapes for the `/api/v1` surface, hand-ported
/// from `openapi/v1.yaml` (the wire source of truth per ADR-002 D1). Every
/// model's `fromJson` only reads the keys it knows about (ADR-002 D4's
/// tolerant-reader rule) - an unrecognized extra field from the server is
/// silently ignored rather than causing a decode failure.

class OrgSummary {
  final String orgId;
  final String name;
  final String slug;

  const OrgSummary(
      {required this.orgId, required this.name, required this.slug});

  factory OrgSummary.fromJson(Map<String, dynamic> json) => OrgSummary(
        orgId: json['orgId'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
      );
}

class NoticeItem {
  final String purpose;
  final String personalDataDescription;

  const NoticeItem(
      {required this.purpose, required this.personalDataDescription});

  factory NoticeItem.fromJson(Map<String, dynamic> json) => NoticeItem(
        purpose: json['purpose'] as String,
        personalDataDescription: json['personalDataDescription'] as String,
      );
}

/// One language's `{ title, body }` entry in [Notice.content].
class NoticeContent {
  final String? title;
  final String? body;

  const NoticeContent({this.title, this.body});

  factory NoticeContent.fromJson(Map<String, dynamic> json) => NoticeContent(
        title: json['title'] as String?,
        body: json['body'] as String?,
      );
}

class Notice {
  final String id;
  final String organizationId;
  final int version;
  final List<NoticeItem> itemized;

  /// Map of language code (e.g. `"en"`, `"hi"`) to that language's content.
  final Map<String, NoticeContent> content;

  /// `"draft" | "published"` - kept as a raw string so a future status
  /// value never breaks decoding.
  final String status;

  const Notice({
    required this.id,
    required this.organizationId,
    required this.version,
    required this.itemized,
    required this.content,
    required this.status,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => Notice(
        id: json['_id'] as String,
        organizationId: json['organizationId'] as String,
        version: json['version'] as int,
        itemized: ((json['itemized'] as List<dynamic>?) ?? const [])
            .map((e) => NoticeItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        content: ((json['content'] as Map<String, dynamic>?) ?? const {}).map(
          (key, value) => MapEntry(
              key, NoticeContent.fromJson(value as Map<String, dynamic>)),
        ),
        status: json['status'] as String,
      );
}

class BannerConfigResponse {
  /// Free-form presentation settings (ADR-006 D2); shape is intentionally
  /// not pinned here.
  final Map<String, dynamic>? bannerSettings;

  /// ADR-006 D3: a presentation-config version, distinct from [Notice.version].
  final int configVersion;

  const BannerConfigResponse(
      {this.bannerSettings, required this.configVersion});

  factory BannerConfigResponse.fromJson(Map<String, dynamic> json) =>
      BannerConfigResponse(
        bannerSettings: json['bannerSettings'] as Map<String, dynamic>?,
        configVersion: json['configVersion'] as int,
      );
}

class ReconsentTarget {
  final String noticeId;
  final String purpose;

  const ReconsentTarget({required this.noticeId, required this.purpose});

  factory ReconsentTarget.fromJson(Map<String, dynamic> json) =>
      ReconsentTarget(
        noticeId: json['noticeId'] as String,
        purpose: json['purpose'] as String,
      );
}

class LinkAnonymousConsentResponse {
  final int linkedCount;
  final List<ReconsentTarget> needsReconsent;

  const LinkAnonymousConsentResponse(
      {required this.linkedCount, required this.needsReconsent});

  factory LinkAnonymousConsentResponse.fromJson(Map<String, dynamic> json) =>
      LinkAnonymousConsentResponse(
        linkedCount: json['linkedCount'] as int,
        needsReconsent: ((json['needsReconsent'] as List<dynamic>?) ?? const [])
            .map((e) => ReconsentTarget.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class GiveConsentAnonymousResponse {
  final String consentId;
  final String purpose;
  final List<String> dataTypes;
  final int givenAt;

  const GiveConsentAnonymousResponse({
    required this.consentId,
    required this.purpose,
    required this.dataTypes,
    required this.givenAt,
  });

  factory GiveConsentAnonymousResponse.fromJson(Map<String, dynamic> json) =>
      GiveConsentAnonymousResponse(
        consentId: json['consentId'] as String,
        purpose: json['purpose'] as String,
        dataTypes: ((json['dataTypes'] as List<dynamic>?) ?? const [])
            .map((e) => e as String)
            .toList(),
        givenAt: json['givenAt'] as int,
      );
}

class DsrRequest {
  final String requestId;

  /// `"summary" | "processors" | "correction" | "erasure"`.
  final String type;

  /// `"pending" | "in_progress" | "completed" | "rejected"`.
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

  factory DsrRequest.fromJson(Map<String, dynamic> json) => DsrRequest(
        requestId: json['requestId'] as String,
        type: json['type'] as String,
        status: json['status'] as String,
        dueAt: json['dueAt'] as int?,
        requestDetails: json['requestDetails'] as String?,
      );
}

class Grievance {
  final String grievanceId;
  final String subject;
  final String description;

  /// `"open" | "in_progress" | "resolved"`.
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

  factory Grievance.fromJson(Map<String, dynamic> json) => Grievance(
        grievanceId: json['grievanceId'] as String,
        subject: json['subject'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        dueAt: json['dueAt'] as int,
        respondedAt: json['respondedAt'] as int?,
        response: json['response'] as String?,
      );
}

class Nomination {
  final String nominationId;
  final String nomineeName;
  final String nomineeContact;

  /// `"active" | "revoked"`.
  final String status;

  const Nomination({
    required this.nominationId,
    required this.nomineeName,
    required this.nomineeContact,
    required this.status,
  });

  factory Nomination.fromJson(Map<String, dynamic> json) => Nomination(
        nominationId: json['nominationId'] as String,
        nomineeName: json['nomineeName'] as String,
        nomineeContact: json['nomineeContact'] as String,
        status: json['status'] as String,
      );
}
