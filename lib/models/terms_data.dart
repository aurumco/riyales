import 'package:equatable/equatable.dart';

/// Stores title, content, and last updated timestamp for app terms.
class TermsData extends Equatable {
  final String title;
  final String content;
  final String lastUpdated;

  /// Creates a [TermsData] with the given title, content, and lastUpdated.
  const TermsData({
    required this.title,
    required this.content,
    required this.lastUpdated,
  });

  /// Creates a [TermsData] from a JSON map.
  factory TermsData.fromJson(Map<String, dynamic> json) => TermsData(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        lastUpdated: json['last_updated'] as String? ?? '',
      );

  @override
  List<Object?> get props => [title, content, lastUpdated];
}
