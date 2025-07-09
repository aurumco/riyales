class Alert {
  final bool show;
  final String color;
  final int buttonCount;
  final AlertContent en;
  final AlertContent fa;

  Alert({
    required this.show,
    required this.color,
    required this.buttonCount,
    required this.en,
    required this.fa,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      show: json['show'] ?? false,
      color: json['color'] ?? 'blue',
      buttonCount: json['button_count'] ?? 0,
      en: AlertContent.fromJson(json['en'] ?? {}),
      fa: AlertContent.fromJson(json['fa'] ?? {}),
    );
  }
}

class AlertContent {
  final String title;
  final String description;
  final AlertButton? button1;
  final AlertButton? button2;

  AlertContent({
    required this.title,
    required this.description,
    this.button1,
    this.button2,
  });

  factory AlertContent.fromJson(Map<String, dynamic> json) {
    return AlertContent(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      button1: json['button_1'] != null
          ? AlertButton.fromJson(json['button_1'])
          : null,
      button2: json['button_2'] != null
          ? AlertButton.fromJson(json['button_2'])
          : null,
    );
  }
}

class AlertButton {
  final String text;
  final String action;

  AlertButton({required this.text, required this.action});

  factory AlertButton.fromJson(Map<String, dynamic> json) {
    return AlertButton(
      text: json['text'] ?? '',
      action: json['action'] ?? 'close_alert',
    );
  }
}
