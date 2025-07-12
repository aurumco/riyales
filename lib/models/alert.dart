class Alert {
  /// Represents a UI alert with content in English and Farsi.
  final bool show;
  final String color;
  final int buttonCount;
  final AlertContent en;
  final AlertContent fa;

  /// Creates an [Alert].
  const Alert({
    required this.show,
    required this.color,
    required this.buttonCount,
    required this.en,
    required this.fa,
  });

  /// Creates an [Alert] from a JSON map.
  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        show: json['show'] as bool? ?? false,
        color: json['color'] as String? ?? 'blue',
        buttonCount: json['button_count'] as int? ?? 0,
        en: AlertContent.fromJson(json['en'] as Map<String, dynamic>? ?? {}),
        fa: AlertContent.fromJson(json['fa'] as Map<String, dynamic>? ?? {}),
      );
}

class AlertContent {
  /// Represents the content of an [Alert], including title, description, and optional buttons.
  final String title;
  final String description;
  final AlertButton? button1;
  final AlertButton? button2;

  /// Creates an [AlertContent].
  const AlertContent({
    required this.title,
    required this.description,
    this.button1,
    this.button2,
  });

  /// Creates an [AlertContent] from a JSON map.
  factory AlertContent.fromJson(Map<String, dynamic> json) => AlertContent(
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        button1: json['button_1'] != null
            ? AlertButton.fromJson(json['button_1'] as Map<String, dynamic>)
            : null,
        button2: json['button_2'] != null
            ? AlertButton.fromJson(json['button_2'] as Map<String, dynamic>)
            : null,
      );
}

class AlertButton {
  /// Represents a button in an [AlertContent].
  final String text;
  final String action;

  /// Creates an [AlertButton].
  const AlertButton({required this.text, required this.action});

  /// Creates an [AlertButton] from a JSON map.
  factory AlertButton.fromJson(Map<String, dynamic> json) => AlertButton(
        text: json['text'] as String? ?? '',
        action: json['action'] as String? ?? 'close_alert',
      );
}
