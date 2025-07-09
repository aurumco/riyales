import 'package:equatable/equatable.dart';

class TermsData extends Equatable {
  final String title;
  final String content;
  final String lastUpdated;

  const TermsData({
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  factory TermsData.fromJson(Map<String, dynamic> json) {
    return TermsData(
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      lastUpdated: json['last_updated'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [title, content, lastUpdated];
}
