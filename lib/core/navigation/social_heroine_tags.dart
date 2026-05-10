/// Tags estables para pares [Heroine] en el flujo Social.
String vetgoSocialPostHeroTag(String postId) => 'vetgo-social-post-$postId';

String vetgoSocialProfileHeroTag(String userId) => 'vetgo-social-profile-$userId';

/// Avatar del autor en una tarjeta de post del feed: único por post (el mismo autor puede
/// aparecer varias veces en pantalla con tags distintos).
String vetgoSocialProfileHeroTagForPost(String authorId, String postId) =>
    'vetgo-social-profile-$authorId-post-$postId';

const String vetgoSocialComposeHeroTag = 'vetgo-social-compose';

String vetgoSocialRepostHeroTag(String originalPostId) =>
    'vetgo-social-repost-$originalPostId';
