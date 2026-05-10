// Tags estables para pares Heroine en el flujo Social.
//
// Cada publicación tiene un postId único asignado en base de datos al crearse; ese id
// relaciona la fila del post con el usuario autor (author_id / equivalente).

String vetgoSocialPostHeroTag(String postId) => 'vetgo-social-post-$postId';

/// Carrusel «Personas que quizás conozcas»: una Hero por usuario (sin post asociado).
String vetgoSocialProfileHeroTag(String userId) => 'vetgo-social-profile-$userId';

/// Avatar del autor → cabecera del perfil cuando entras desde **esta** tarjeta de post.
/// Solo usa el [postId] del backend (único por fila; identifica de forma inequívoca el contexto).
String vetgoSocialAuthorAvatarFlightTag(String postId) =>
    'vetgo-social-author-post-$postId';

const String vetgoSocialComposeHeroTag = 'vetgo-social-compose';

String vetgoSocialRepostHeroTag(String originalPostId) =>
    'vetgo-social-repost-$originalPostId';
