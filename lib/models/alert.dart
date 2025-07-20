class Alert {
  /// Represents a UI alert with content in English and Farsi.
  final bool show;
  final String color;
  final int buttonCount;
  final AlertContent en;
  final AlertContent fa;
  final AdInfo? ad;

  /// Creates an [Alert].
  const Alert({
    required this.show,
    required this.color,
    required this.buttonCount,
    required this.en,
    required this.fa,
    this.ad,
  });

  /// Creates an [Alert] from a JSON map.
  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
        show: json['show'] as bool? ?? false,
        color: json['color'] as String? ?? 'blue',
        buttonCount: json['button_count'] as int? ?? 0,
        en: AlertContent.fromJson(json['en'] as Map<String, dynamic>? ?? {}),
        fa: AlertContent.fromJson(json['fa'] as Map<String, dynamic>? ?? {}),
        ad: json['ad'] != null
            ? AdInfo.fromJson(json['ad'] as Map<String, dynamic>)
            : null,
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

/// Advertisement data attached to an Alert configuration.
class AdInfo {
  final bool enabled;
  final int timeMs; // default duration for image ads
  final String device; // mobile/desktop/all (global)
  final List<AdEntry> entries;

  const AdInfo({
    required this.enabled,
    required this.timeMs,
    required this.device,
    required this.entries,
  });

  factory AdInfo.fromJson(Map<String, dynamic> json) {
    final enabled = json['enabled'] as bool? ?? false;
    final timeMs = int.tryParse(json['time']?.toString() ?? '') ?? 5000;
    final globalDevice = (json['device']?.toString() ?? 'all').toLowerCase();

    final List<AdEntry> entries = [];
    for (int i = 1; i <= 3; i++) {
      final url = json['ad$i'] ?? '';
      if (url == null || url.toString().isEmpty) continue;
      final id = json['idAd$i']?.toString() ?? '$i';
      final link = json['linkAd$i']?.toString() ?? '';
      final device = (json['deviceAd$i']?.toString() ?? 'all').toLowerCase();
      final repeatStr = json['repeatAd$i']?.toString() ?? '';
      final repeatCount = repeatStr.isEmpty ? null : int.tryParse(repeatStr);
      entries.add(AdEntry(
          id: id,
          url: url.toString(),
          link: link,
          device: device,
          repeatCount: repeatCount));
    }

    return AdInfo(
        enabled: enabled,
        timeMs: timeMs,
        device: globalDevice,
        entries: entries);
  }

  List<AdEntry> entriesForDevice(bool isMobileDevice) {
    return entries.where((e) {
      String target = e.device.isEmpty ? 'all' : e.device;
      if (target == 'all') {
        target = device; // inherit global device if entry not specified
      }
      switch (target) {
        case 'mobile':
          return isMobileDevice;
        case 'desktop':
          return !isMobileDevice;
        default:
          return true;
      }
    }).toList();
  }
}

class AdEntry {
  final String id;
  final String url;
  final String link;
  final String device; // mobile/desktop/all
  final int? repeatCount; // null => infinite

  const AdEntry({
    required this.id,
    required this.url,
    required this.link,
    required this.device,
    required this.repeatCount,
  });

  bool get isVideo {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mkv');
  }
}
