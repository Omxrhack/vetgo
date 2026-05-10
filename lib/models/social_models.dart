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
  });

  final String id;
  final String body;
  final List<String> imageUrls;
  final DateTime createdAt;
  final PostAuthorVm author;

  factory PostVm.fromJson(Map<String, dynamic> j) => PostVm(
        id: j['id'] as String,
        body: j['body'] as String,
        imageUrls: (j['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        author: PostAuthorVm.fromJson(
          j['author'] is Map<String, dynamic>
              ? j['author'] as Map<String, dynamic>
              : <String, dynamic>{},
        ),
      );
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
