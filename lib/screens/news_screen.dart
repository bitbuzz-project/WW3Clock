import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../utils/colors.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NewsProvider>().loadNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Global News Feed'),
        backgroundColor: AppColors.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<NewsProvider>().loadNews(),
          ),
        ],
      ),
      body: Consumer<NewsProvider>(
        builder: (context, newsProvider, child) {
          if (newsProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading latest news...'),
                ],
              ),
            );
          }

          if (newsProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${newsProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => newsProvider.loadNews(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final newsItems = newsProvider.newsItems;
          if (newsItems.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.newspaper, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No news available'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => newsProvider.loadNews(),
            child: Column(
              children: [
                // Stats header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: AppColors.cardBackground,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Articles',
                        newsItems.length.toString(),
                        Icons.article,
                      ),
                      _buildStatItem(
                        'High Threat',
                        newsProvider.highThreatNews.length.toString(),
                        Icons.warning,
                      ),
                      _buildStatItem(
                        'Recent',
                        newsProvider.recentNews.length.toString(),
                        Icons.access_time,
                      ),
                    ],
                  ),
                ),
                
                // News list
                Expanded(
                  child: ListView.builder(
                    itemCount: newsItems.length,
                    itemBuilder: (context, index) {
                      return NewsCard(newsItem: newsItems[index]);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}