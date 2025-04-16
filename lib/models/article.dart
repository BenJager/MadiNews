class Article {
  final String? author;
  final String title;
  final String? description;
  final String? url;
  final String? urlToImage;
  final String publishedAt;
  final String? content;
  final String? sourceName;
  final bool isScraped; // Nouveau champ pour identifier les articles scrapés
  final String? category; // Nouveau champ pour la catégorie (utile pour les articles scrapés)

  Article({
    required this.author,
    required this.title,
    required this.description,
    required this.url,
    required this.urlToImage,
    required this.publishedAt,
    required this.content,
    required this.sourceName,
    this.isScraped = false, // Par défaut false pour les articles API
    this.category, // Optionnel pour les articles API
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      author: json['author'],
      title: json['title'] ?? 'No title',
      description: json['description'],
      url: json['url'],
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'] ?? '',
      content: json['content'],
      sourceName: json['source']['name'],
      // isScraped reste false par défaut pour les articles API
    );
  }

  factory Article.fromScraped(Map<String, String> scraped) {
    return Article(
      author: null, // Pas d'auteur pour les articles scrapés
      title: scraped['title'] ?? 'Sans titre',
      description: scraped['summary'],
      url: scraped['url'],
      urlToImage: scraped['imageUrl'],
      publishedAt: scraped['publishedAt'] ?? '',
      content: scraped['summary'], // On réutilise le summary comme content
      sourceName: scraped['source'] ?? 'Source inconnue',
      isScraped: true, // Marqué comme article scrapé
      category: scraped['category'], // Catégorie des articles scrapés
    );
  }

  // Méthode pour convertir en Map (utile pour le stockage)
  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'title': title,
      'description': description,
      'url': url,
      'urlToImage': urlToImage,
      'publishedAt': publishedAt,
      'content': content,
      'sourceName': sourceName,
      'isScraped': isScraped,
      'category': category,
    };
  }

  // Optionnel: méthode pour créer à partir d'une Map (pour le chargement)
  factory Article.fromMap(Map<String, dynamic> map) {
    return Article(
      author: map['author'],
      title: map['title'],
      description: map['description'],
      url: map['url'],
      urlToImage: map['urlToImage'],
      publishedAt: map['publishedAt'],
      content: map['content'],
      sourceName: map['sourceName'],
      isScraped: map['isScraped'] ?? false,
      category: map['category'],
    );
  }
}