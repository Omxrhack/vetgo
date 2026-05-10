class VetStatsVm {
  const VetStatsVm({
    this.specialty,
    this.yearsExperience,
    this.avgRating,
    this.ratingCount = 0,
    this.completedAppointments = 0,
    this.uniquePets = 0,
    this.postsCount = 0,
  });

  final String? specialty;
  final int? yearsExperience;
  final double? avgRating;
  final int ratingCount;
  final int completedAppointments;
  final int uniquePets;
  final int postsCount;

  factory VetStatsVm.fromJson(Map<String, dynamic> j) => VetStatsVm(
        specialty: j['specialty'] as String?,
        yearsExperience: (j['years_experience'] as num?)?.toInt(),
        avgRating: (j['avg_rating'] as num?)?.toDouble(),
        ratingCount: (j['rating_count'] as num?)?.toInt() ?? 0,
        completedAppointments: (j['completed_appointments'] as num?)?.toInt() ?? 0,
        uniquePets: (j['unique_pets'] as num?)?.toInt() ?? 0,
        postsCount: (j['posts_count'] as num?)?.toInt() ?? 0,
      );
}

class PublicProfileVm {
  const PublicProfileVm({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    this.bio,
    this.location,
    required this.role,
    required this.followersCount,
    required this.followingCount,
    required this.isFollowing,
    this.vet,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String role;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final VetStatsVm? vet;

  bool get isVet => role == 'vet';

  factory PublicProfileVm.fromJson(Map<String, dynamic> j) => PublicProfileVm(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        bio: j['bio'] as String?,
        location: j['location'] as String?,
        role: j['role'] as String? ?? 'client',
        followersCount: (j['followers_count'] as num?)?.toInt() ?? 0,
        followingCount: (j['following_count'] as num?)?.toInt() ?? 0,
        isFollowing: j['is_following'] as bool? ?? false,
        vet: j['vet'] is Map<String, dynamic>
            ? VetStatsVm.fromJson(j['vet'] as Map<String, dynamic>)
            : null,
      );

  PublicProfileVm copyWith({bool? isFollowing, int? followersCount}) => PublicProfileVm(
        id: id,
        fullName: fullName,
        avatarUrl: avatarUrl,
        bio: bio,
        location: location,
        role: role,
        followersCount: followersCount ?? this.followersCount,
        followingCount: followingCount,
        isFollowing: isFollowing ?? this.isFollowing,
        vet: vet,
      );
}

class PostAuthorVm {
  const PostAuthorVm({required this.id, required this.fullName, this.avatarUrl});

  final String id;
  final String fullName;
  final String? avatarUrl;

  factory PostAuthorVm.fromJson(Map<String, dynamic> j) => PostAuthorVm(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
      );
}

class PostVm {
  const PostVm({
    required this.id,
    required this.body,
    required this.imageUrls,
    required this.createdAt,
    required this.author,
    this.likeCount = 0,
    this.commentCount = 0,
    this.viewerHasLiked = false,
    this.repostCount = 0,
    this.viewerHasReposted = false,
  });

  final String id;
  final String body;
  final List<String> imageUrls;
  final DateTime createdAt;
  final PostAuthorVm author;

  final int likeCount;
  final int commentCount;
  final bool viewerHasLiked;
  final int repostCount;
  final bool viewerHasReposted;

  factory PostVm.fromJson(Map<String, dynamic> j) => PostVm(
        id: j['id'] as String,
        body: j['body'] as String? ?? '',
        imageUrls: (j['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        author: PostAuthorVm.fromJson(
          j['author'] is Map<String, dynamic>
              ? j['author'] as Map<String, dynamic>
              : <String, dynamic>{},
        ),
        likeCount: (j['like_count'] as num?)?.toInt() ?? 0,
        commentCount: (j['comment_count'] as num?)?.toInt() ?? 0,
        viewerHasLiked: j['viewer_has_liked'] as bool? ?? false,
        repostCount: (j['repost_count'] as num?)?.toInt() ?? 0,
        viewerHasReposted: j['viewer_has_reposted'] as bool? ?? false,
      );

  PostVm copyWith({
    String? id,
    String? body,
    List<String>? imageUrls,
    DateTime? createdAt,
    PostAuthorVm? author,
    int? likeCount,
    int? commentCount,
    bool? viewerHasLiked,
    int? repostCount,
    bool? viewerHasReposted,
  }) {
    return PostVm(
      id: id ?? this.id,
      body: body ?? this.body,
      imageUrls: imageUrls ?? this.imageUrls,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      viewerHasLiked: viewerHasLiked ?? this.viewerHasLiked,
      repostCount: repostCount ?? this.repostCount,
      viewerHasReposted: viewerHasReposted ?? this.viewerHasReposted,
    );
  }
}

/// Comentario en un post (API social).
class PostCommentVm {
  const PostCommentVm({
    required this.id,
    required this.body,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String body;
  final DateTime createdAt;
  final PostAuthorVm author;

  factory PostCommentVm.fromJson(Map<String, dynamic> j) => PostCommentVm(
        id: j['id'] as String,
        body: j['body'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        author: PostAuthorVm.fromJson(
          j['author'] is Map<String, dynamic>
              ? j['author'] as Map<String, dynamic>
              : <String, dynamic>{},
        ),
      );
}

/// Entrada del feed unificado (post original o repost).
sealed class FeedEntryVm {
  const FeedEntryVm();

  DateTime get feedAt;

  /// Post que muestra fotos / contenido principal en la tarjeta.
  PostVm get displayPost;

  factory FeedEntryVm.fromJson(Map<String, dynamic> j) {
    final kind = j['feed_kind'] as String?;
    final createdAt =
        DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now();

    if (kind == 'repost') {
      final postMap = j['post'];
      if (postMap is! Map<String, dynamic>) {
        throw FormatException('repost sin post');
      }
      return FeedRepostEntryVm(
        feedAt: createdAt,
        repostId: j['repost_id'] as String,
        quoteBody: j['quote_body'] as String?,
        reposter: PostAuthorVm.fromJson(
          j['reposter'] is Map<String, dynamic>
              ? j['reposter'] as Map<String, dynamic>
              : <String, dynamic>{},
        ),
        originalPost: PostVm.fromJson(postMap),
      );
    }

    final nested = j['post'];
    if (nested is Map<String, dynamic>) {
      return FeedPostEntryVm(
        feedAt: createdAt,
        post: PostVm.fromJson(nested),
      );
    }

    return FeedPostEntryVm(
      feedAt: createdAt,
      post: PostVm.fromJson(j),
    );
  }
}

final class FeedPostEntryVm extends FeedEntryVm {
  const FeedPostEntryVm({required this.feedAt, required this.post});

  @override
  final DateTime feedAt;
  final PostVm post;

  @override
  PostVm get displayPost => post;
}

final class FeedRepostEntryVm extends FeedEntryVm {
  const FeedRepostEntryVm({
    required this.feedAt,
    required this.repostId,
    this.quoteBody,
    required this.reposter,
    required this.originalPost,
  });

  @override
  final DateTime feedAt;
  final String repostId;
  final String? quoteBody;
  final PostAuthorVm reposter;
  final PostVm originalPost;

  @override
  PostVm get displayPost => originalPost;
}

class ReviewerVm {
  const ReviewerVm({required this.id, required this.fullName, this.avatarUrl});

  final String id;
  final String fullName;
  final String? avatarUrl;

  factory ReviewerVm.fromJson(Map<String, dynamic> j) => ReviewerVm(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
      );
}

class SuggestedProfileVm {
  const SuggestedProfileVm({
    required this.id,
    required this.fullName,
    this.avatarUrl,
    required this.role,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;
  final String role;

  bool get isVet => role == 'vet';

  factory SuggestedProfileVm.fromJson(Map<String, dynamic> j) => SuggestedProfileVm(
        id: j['id'] as String,
        fullName: j['full_name'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        role: j['role'] as String? ?? 'client',
      );
}

class ReviewVm {
  const ReviewVm({
    required this.id,
    required this.rating,
    this.comment,
    required this.createdAt,
    required this.reviewer,
  });

  final String id;
  final int rating;
  final String? comment;
  final DateTime createdAt;
  final ReviewerVm reviewer;

  factory ReviewVm.fromJson(Map<String, dynamic> j) => ReviewVm(
        id: j['id'] as String,
        rating: (j['rating'] as num).toInt(),
        comment: j['comment'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        reviewer: ReviewerVm.fromJson(
          j['reviewer'] is Map<String, dynamic>
              ? j['reviewer'] as Map<String, dynamic>
              : <String, dynamic>{},
        ),
      );
}

// ─── Filtros de feed ───────────────────────────────────────────────────────────

/// Feed social (inicio): muestra reposts de otras personas; oculta los reposts
/// hechos por [viewerUserId] (no repetir la propia acción de republicar).
List<FeedEntryVm> filterHomeFeedForViewer(
  List<FeedEntryVm> entries,
  String? viewerUserId,
) {
  if (viewerUserId == null || viewerUserId.isEmpty) return entries;
  return entries.where((e) {
    if (e is FeedPostEntryVm) return true;
    if (e is FeedRepostEntryVm) return e.reposter.id != viewerUserId;
    return true;
  }).toList();
}

/// Pestaña Feed del perfil: solo publicaciones propias del autor, sin filas de repost.
List<FeedEntryVm> filterProfileFeedPosts(List<FeedEntryVm> entries) {
  return List<FeedEntryVm>.from(entries.whereType<FeedPostEntryVm>());
}
