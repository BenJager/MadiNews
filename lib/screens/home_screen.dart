import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:news_app2/models/article.dart';
import 'package:news_app2/services/news_service.dart';
import 'package:news_app2/services/news_scraper.dart';
import 'package:news_app2/widgets/article_widget.dart';
import 'package:news_app2/widgets/search_bar.dart';
import 'package:news_app2/screens/article_detail_screen.dart';
import 'package:news_app2/screens/favorites_screen.dart';
import 'package:news_app2/providers/favorites_provider.dart';
import 'package:news_app2/providers/theme_notifier.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NewsService _newsService = NewsService();
  final NewsScraper _newsScraper = NewsScraper();
  List<Map<String, String>> _scrapedNews = [];
  final ScrollController _scrollController = ScrollController();
  final _articles = <Article>[];
  
  final _categories = const {
    'Général': 'general',
    'Finance': 'business',
    'Sport': 'sports',
    'Technologie': 'technology',
  };

  String _searchQuery = '';
  String _currentCategory = 'general';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _isScraping = false;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialArticles();
    _loadScrapedNews();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialArticles() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final articles = await _fetchArticles(page: 1);
      if (!mounted) return;
      
      setState(() {
        _articles.clear();
        _articles.addAll(articles);
        _isRefreshing = false;
        _hasMore = articles.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      _showError(e.toString());
    }
  }

  Future<void> _loadArticles() async {
    if (!mounted) return;
    
    setState(() {
      _isRefreshing = true;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final newArticles = _searchQuery.isEmpty
          ? await _newsService.fetchTopHeadlines(
              category: _currentCategory, 
              page: _currentPage)
          : await _newsService.searchNews(_searchQuery, page: _currentPage);

      if (!mounted) return;
      
      setState(() {
        _articles.clear();
        _articles.addAll(newArticles);
        _isRefreshing = false;
        _hasMore = newArticles.isNotEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isRefreshing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadMoreArticles() async {
    if (_isLoadingMore || !_hasMore) return;
    
    setState(() => _isLoadingMore = true);

    try {
      final newArticles = await _fetchArticles(page: _currentPage + 1);
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
        if (newArticles.isEmpty) {
          _hasMore = false;
        } else {
          _articles.addAll(newArticles);
          _currentPage++;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
      _showError(e.toString());
    }
  }
  
  Future<List<Article>> _fetchArticles({required int page}) async {
    return _searchQuery.isEmpty
        ? await _newsService.fetchTopHeadlines(
            category: _currentCategory,
            page: page,
          )
        : await _newsService.searchNews(_searchQuery, page: page);
  }

  Future<void> _loadScrapedNews() async {
    if (!mounted) return;
    setState(() => _isScraping = true);
    try {
      final scrapedNews = await _newsScraper.scrapeAntillaMartinique();
      if (!mounted) return;
      setState(() {
        _scrapedNews = scrapedNews;
        _isScraping = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScraping = false);
      _showError('Erreur de scraping: ${e.toString()}');
    }
  }

  void _scrollListener() {
    final metrics = _scrollController.position;
    if (metrics.pixels >= metrics.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        metrics.outOfRange == false) {
      _loadMoreArticles();
    }
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $error')),
    );
    debugPrint('Error: $error');
  }

  void _searchArticles(String query) {
    _searchQuery = query;
    _loadArticles();
  }

  void _changeCategory(String category) {
    setState(() => _currentCategory = category);
    _loadArticles();
  }

  void _navigateToArticleDetail(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

void _navigateToScrapedArticle(Map<String, String> article) {
  final controller = WebViewController()
    ..loadRequest(Uri.parse(article['url'] ?? 'about:blank'))
    ..setJavaScriptMode(JavaScriptMode.unrestricted);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: Text(article['title'] ?? 'Article'),
          actions: [
            Consumer<FavoritesProvider>(
              builder: (context, provider, _) {
                final articleModel = Article.fromScraped(article);
                return IconButton(
                  icon: Icon(
                    provider.isFavorite(articleModel)
                      ? Icons.favorite
                      : Icons.favorite_border,
                    color: Colors.red,
                  ),
                  onPressed: () => provider.toggleFavorite(articleModel),
                );
              },
            ),
          ],
        ),
        body: WebViewWidget(controller: controller),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: _buildAppBar(),
      body: _currentIndex == 0 ? _buildNewsPage() : _buildScrapingPage(),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      width: 280,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 160,
            child: DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black45,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Consumer<ThemeNotifier>(
            builder: (context, themeNotifier, child) {
              return SwitchListTile(
                title: const Text('Mode Sombre'),
                value: themeNotifier.themeMode == ThemeMode.dark,
                onChanged: themeNotifier.toggleTheme,
                secondary: Icon(
                  themeNotifier.themeMode == ThemeMode.dark
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: Theme.of(context).iconTheme.color,
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.favorite,
                color: Theme.of(context).iconTheme.color),
            title: const Text('Favoris'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return _currentIndex == 0
        ? AppBar(
            centerTitle: true,
            title: Image.asset(
              'lib/assets/images/colibri.png',
              height: 63,
              fit: BoxFit.contain,
            ),
            actions: [
              IconButton(
                onPressed: _isRefreshing ? null : _loadArticles,
                icon: _isRefreshing
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                    )
                    : const Icon(Icons.refresh),
                tooltip: 'Rafraîchir',
              ),
            ],
          )
        : AppBar(
            centerTitle: true,
            title: Image.asset(
              'lib/assets/images/colibri.png',
              height: 63,
              fit: BoxFit.contain,
            ),
            actions: [
              IconButton(
                icon: _isScraping
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Icon(Icons.refresh),
                onPressed: _isScraping ? null : _loadScrapedNews,
              ),
            ],
          );
  }

  Widget _buildBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.blue.withOpacity(0.6),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Actualités'),
        BottomNavigationBarItem(
            icon: Icon(Icons.newspaper_rounded), label: 'Locale'),
      ],
    );
  }

  Widget _buildNewsPage() {
    return Column(
      children: [
        SearchBarWidget(onSearch: _searchArticles),
        _buildCategoryChips(),
        Expanded(child: _buildArticleList()),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _categories.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: ChoiceChip(
              label: Text(
                entry.key,
                style: TextStyle(
                  color: _currentCategory == entry.value 
                      ? Colors.white 
                      : Colors.blue,
                ),
              ),
              selected: _currentCategory == entry.value,
              onSelected: (selected) {
                if (selected) _changeCategory(entry.value);
              },
              selectedColor: Colors.blue,
              backgroundColor: Colors.blue[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(
                  color: Colors.blue,
                  width: 1.5,
                ),
              ),
              labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildArticleList() {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _articles.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _articles.length) {
          return _buildLoaderItem();
        }
        final article = _articles[index];
        return ArticleWidget(
          article: article,
          onTap: () => _navigateToArticleDetail(article),
          isFavorite: Provider.of<FavoritesProvider>(context).isFavorite(article),
          onFavoriteToggle: () => Provider.of<FavoritesProvider>(context, listen: false)
              .toggleFavorite(article),
        );
      },
    );
  }

Widget _buildScrapingPage() {
  return RefreshIndicator(
    onRefresh: _loadScrapedNews,
    child: _scrapedNews.isEmpty && !_isScraping
        ? const Center(child: Text('Aucun article disponible'))
        : ListView.builder(
            itemCount: _scrapedNews.length,
            itemBuilder: (context, index) {
              final scrapedData = _scrapedNews[index];
              final articleModel = Article.fromScraped(scrapedData);
              final favoritesProvider = Provider.of<FavoritesProvider>(context);
              
              return ArticleWidget(
                article: articleModel,
                onTap: () => _navigateToScrapedArticle(scrapedData),
                isFavorite: favoritesProvider.isFavorite(articleModel),
                onFavoriteToggle: () => favoritesProvider.toggleFavorite(articleModel),
              );
            },
          ),
  );
}
  Widget _buildLoaderItem() {
    return SizedBox(
      height: 100,
      child: Center(
        child: _isLoadingMore
            ? const CircularProgressIndicator()
            : !_hasMore ? const Text('Fin des articles') : const SizedBox(),
      ),
    );
  }
}