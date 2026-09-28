class CaseDocumentModel {
  final String id;
  final String caseId;
  final String uploadedBy;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSizeBytes;
  final DateTime uploadedAt;

  CaseDocumentModel({
    required this.id,
    required this.caseId,
    required this.uploadedBy,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSizeBytes,
    required this.uploadedAt,
  });

  factory CaseDocumentModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return CaseDocumentModel(
      id: json['id'].toString(),
      caseId: json['caseId'].toString(),
      uploadedBy: json['uploadedBy'].toString(),
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileType: json['fileType'],
      fileSizeBytes: json['fileSizeBytes'],
      uploadedAt: DateTime.parse(json['uploadedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseId': caseId,
      'uploadedBy': uploadedBy,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }
}