/// Tags estables para pares [Heroine] en el flujo Social.
String vetgoSocialPostHeroTag(String postId) => 'vetgo-social-post-$postId';

String vetgoSocialProfileHeroTag(String userId) => 'vetgo-social-profile-$userId';

const String vetgoSocialComposeHeroTag = 'vetgo-social-compose';

String vetgoSocialRepostHeroTag(String originalPostId) =>
    'vetgo-social-repost-$originalPostId';
