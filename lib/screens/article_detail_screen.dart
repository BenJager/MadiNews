import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import 'package:news_app2/models/article.dart';
import 'package:news_app2/providers/favorites_provider.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final WebViewController _controller;
  late final FlutterTts _flutterTts;
  bool _isSpeaking = false;
  String _speechText = '';
  String _currentLanguage = 'fr-FR';

  final Map<String, String> _supportedLanguages = {
    'Français': 'fr-FR',
    'English': 'en-US',
    'Español': 'es-ES',
    'Deutsch': 'de-DE',
    'Italiano': 'it-IT',
  };

  @override
  void initState() {
    super.initState();
    _initTts();
    _initWebView();
    _prepareSpeechText();
    _autoDetectLanguage();
  }

  void _initTts() {
    _flutterTts = FlutterTts();
    
    _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
    _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur TTS: $msg")),
      );
    });
  }

  void _autoDetectLanguage() {
    final text = widget.article.title + (widget.article.description ?? '');
    
    if (_containsEnglish(text)) {
      _currentLanguage = 'en-US';
    } else if (_containsFrench(text)) {
      _currentLanguage = 'fr-FR';
    } else if (_containsSpanish(text)) {
      _currentLanguage = 'es-ES';
    }
  }

  bool _containsEnglish(String text) {
    return RegExp(r'\b(the|and|to|of|a|in|that|it|is|was)\b', caseSensitive: false)
        .hasMatch(text);
  }

  bool _containsFrench(String text) {
    return RegExp(r'\b(le|la|les|un|une|des|et|est|pas)\b')
        .hasMatch(text);
  }

  bool _containsSpanish(String text) {
    return RegExp(r'\b(el|la|los|las|un|una|y|es|no)\b')
        .hasMatch(text);
  }

  void _initWebView() {
    _controller = WebViewController()
      ..loadRequest(Uri.parse(widget.article.url ?? 'about:blank'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  void _prepareSpeechText() {
    _speechText = '${widget.article.title}. ${widget.article.description ?? ''}';
  }

  Future<void> _speak() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      return;
    }
    
    if (_speechText.isEmpty) return;
    
    try {
      final languages = await _flutterTts.getLanguages;
      if (!languages.contains(_currentLanguage)) {
        _currentLanguage = 'en-US';
      }

      await _flutterTts.setLanguage(_currentLanguage);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.speak(_speechText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lecture: $e")),
      );
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.title),
        actions: [
          // Bouton favori
          Consumer<FavoritesProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isFavorite(widget.article)
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: Colors.red,
                ),
                onPressed: () => provider.toggleFavorite(widget.article),
              );
            },
          ),
          // Bouton lecture vocale
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_off : Icons.volume_up),
            onPressed: _speak,
          ),
          // Menu langue
          _buildLanguageMenu(),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }

  Widget _buildLanguageMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      onSelected: (languageCode) async {
        setState(() => _currentLanguage = languageCode);
        if (_isSpeaking) {
          await _flutterTts.stop();
          await _speak();
        }
      },
      itemBuilder: (context) {
        return _supportedLanguages.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.value,
            child: Text(entry.key),
          );
        }).toList();
      },
    );
  }
}