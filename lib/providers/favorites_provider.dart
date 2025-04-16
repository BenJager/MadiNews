import 'package:flutter/material.dart';
import 'package:news_app2/models/article.dart';

class FavoritesProvider extends ChangeNotifier {
  final List<Article> _favorites = [];

  List<Article> get favorites => _favorites;

  bool isFavorite(Article article) {
    return _favorites.any((fav) => fav.url == article.url && fav.isScraped == article.isScraped);
  }

  void toggleFavorite(Article article) {
    final isExisting = _favorites.any((a) => 
      a.url == article.url && a.isScraped == article.isScraped);
    
    if (isExisting) {
      _favorites.removeWhere((a) => 
        a.url == article.url && a.isScraped == article.isScraped);
    } else {
      _favorites.add(article);
    }
    notifyListeners();
  }

  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }
}