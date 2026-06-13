import 'package:flutter/widgets.dart';
import 'package:mymeds_app/l10n/app_localizations.dart';
import 'package:mymeds_app/services/talkback_service.dart';

mixin TalkbackScreenMixin<T extends StatefulWidget> on State<T> {
  final _talkback = TalkbackService();
  String? _lastSpoken;

  void speakOnLoad(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (text != _lastSpoken) {
        _lastSpoken = text;
        await _setLanguageFromLocale();
        await _talkback.speak(text);
      }
    });
  }

  void speakText(String text) {
    _setLanguageFromLocale().then((_) => _talkback.speak(text));
  }

  void stopTalkback() {
    _talkback.stop();
  }

  Future<void> _setLanguageFromLocale() async {
    try {
      final locale = AppLocalizations.of(context)?.localeName;
      if (locale != null) {
        await _talkback.setLanguage(locale);
      }
    } catch (_) {}
  }
}
