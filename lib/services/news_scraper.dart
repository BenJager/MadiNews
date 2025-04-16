import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart'; // Import pour Document et Element
import 'dart:developer' as developer;
import 'dart:async';

class NewsScraper {
  static const Duration requestTimeout = Duration(seconds: 15);
  static const Duration parsingTimeout = Duration(seconds: 5);

  Future<List<Map<String, String>>> scrapeAntillaMartinique() async {
    final List<Map<String, String>> articles = [];
    const String baseUrl = 'https://antilla-martinique.com';

    try {
      final response = await _makeRequest(baseUrl);
      final document = await _parseResponse(response);
      articles.addAll(_extractArticles(document, baseUrl));
    } on TimeoutException catch (e) {
      developer.log('Timeout: $e');
      return [];
    } catch (e) {
      developer.log('Error: $e');
      rethrow;
    }

    return articles;
  }

  Future<http.Response> _makeRequest(String baseUrl) async {
    try {
      return await http.get(
        Uri.parse('$baseUrl/category/actualite/'),
        headers: {'User-Agent': 'Mozilla/5.0'},
      ).timeout(requestTimeout);
    } on TimeoutException {
      developer.log('Request timeout');
      rethrow;
    }
  }

  Future<Document> _parseResponse(http.Response response) async {
    try {
      return await Future(() => parse(response.body))
          .timeout(parsingTimeout);
    } on TimeoutException {
      developer.log('Parsing timeout');
      rethrow;
    }
  }

  List<Map<String, String>> _extractArticles(Document document, String baseUrl) {
    return document.querySelectorAll('article.l-post').map((article) {
      return _extractArticleData(article, baseUrl);
    }).where((article) => article['title'] != null && article['url'] != null)
      .toList();
  }

  Map<String, String> _extractArticleData(Element article, String baseUrl) {
    final titleElement = article.querySelector('h2.is-title.post-title a');
    final imageContainer = article.querySelector('span.img.bg-cover');
    
    return {
      'title': titleElement?.text.trim() ?? 'Sans titre',
      'url': titleElement?.attributes['href'] ?? '',
      'imageUrl': imageContainer?.attributes['data-bgsrc'] ?? 
                 imageContainer?.attributes['data-bgset']?.split(' ').first ?? '',
      'summary': article.querySelector('div.excerpt p')?.text.trim() ?? '',
      'source': 'Antilla Martinique',
      'publishedAt': article.querySelector('time.post-date')?.text.trim() ?? '',
      'category': article.querySelector('a.category.term-color-2')?.text.trim() ?? 'Actualité',
    };
  }
}