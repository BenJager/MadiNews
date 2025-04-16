import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news_app2/models/article.dart';

class NewsService {
  static const String _apiKey = '6cf72224845c4ac0ba6631405de92c77';
  static const String _baseUrl = 'https://newsapi.org/v2';
  static const int _pageSize = 10; // Nombre d'articles par page

 Future<List<Article>> fetchTopHeadlines({
  String category = 'general',
  required int page, // Paramètre obligatoire
  int pageSize = 10,
}) async {
  final response = await http.get(
    Uri.parse(
      '$_baseUrl/top-headlines?country=us&category=$category&pageSize=$pageSize&page=$page&apiKey=$_apiKey',
    ),
  );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> articles = json['articles'];
      return articles.map((article) => Article.fromJson(article)).toList();
    } else {
      throw Exception('Failed to load headlines');
    }
  }

  Future<List<Article>> searchNews(
    String query, {
    required int page,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/everything?q=$query&pageSize=$_pageSize&page=$page&apiKey=$_apiKey',
      ),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> articles = json['articles'];
      return articles.map((article) => Article.fromJson(article)).toList();
    } else {
      throw Exception('Failed to search news');
    }
  }
}