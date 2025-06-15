class NewsItem {
  final String id;
  final String title;
  final String description;
  final String url;
  final String source;
  final DateTime publishedAt;
  final double threatScore;
  final List<String> keywords;
  final String? imageUrl;

  NewsItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.source,
    required this.publishedAt,
    required this.threatScore,
    required this.keywords,
    this.imageUrl,
  });

  factory NewsItem.fromMap(Map<String, dynamic> map) {
    return NewsItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      url: map['url'] ?? '',
      source: map['source'] ?? '',
      publishedAt: DateTime.parse(map['publishedAt']),
      threatScore: map['threatScore']?.toDouble() ?? 0.0,
      keywords: List<String>.from(map['keywords'] ?? []),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'source': source,
      'publishedAt': publishedAt.toIso8601String(),
      'threatScore': threatScore,
      'keywords': keywords,
      'imageUrl': imageUrl,
    };
  }
}