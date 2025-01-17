import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:gazelle_core/gazelle_core.dart';
import 'gazelle_jwt_consts.dart';

/// A plugin for JSON Web Token (JWT) authentication in Gazelle.
/// Example Usage:
///
/// ```dart
/// final app = GazelleApp();
/// await app.registerPlugin(GazelleJwtPlugin("supersecret"));
///
/// app
///   ..post(
///     "/login",
///    (request) async {
///       return GazelleResponse(
///        statusCode: 200,
///         body: app.getPlugin<GazelleJwtPlugin>().sign({"test": "123"}),
///       );
///    },
///  )
///  ..get(
///  "/hello_world",
///  (request) async {
///  return GazelleResponse(
///     statusCode: 200,
///	body: "Hello, World!",
///  );
/// },
///   preRequestHooks: [app.getPlugin<GazelleJwtPlugin>().authenticationHook],
/// );
///
/// await app.start();
/// ```
class GazelleJwtPlugin implements GazellePlugin {
  /// The secret used for JWT signing and verification.
  final JWTKey _secret;

  /// The secret key derived from the secret.
  late final JWTKey _secretKey;

  /// Constructs a GazelleJwtPlugin instance with the provided [secret].
  GazelleJwtPlugin(this._secret);

  @override
  Future<void> initialize(GazelleContext context) async {
    _secretKey = _secret;
  }

  /// Signs a JWT with the provided [payload].
  String sign(Map<String, dynamic> payload) => JWT(payload).sign(_secretKey);

  /// Verifies and decodes a JWT token.
  JWT? verify(String token) => JWT.tryVerify(token, _secretKey);

  /// Returns a pre-request hook for JWT authentication.
  ///
  /// If [shareWithChildRoutes] is true, the hook will be shared with child routes.
  GazellePreRequestHook getAuthenticationHook({
    bool shareWithChildRoutes = true,
  }) =>
      GazellePreRequestHook(
        (request, response) async {
          final authHeader = request.headers[authHeaderName]?.first;
          if (authHeader == null) {
            return (
              request,
              response.copyWith(
                statusCode: 401,
                body: missingAuthHeaderMessage,
              )
            );
          }

          if (!authHeader.startsWith(bearerSchema)) {
            return (
              request,
              response.copyWith(
                statusCode: 401,
                body: badBearerSchemaMessage,
              )
            );
          }

          final token = authHeader.replaceAll(bearerSchema, "");
          final jwt = verify(token);
          if (jwt == null) {
            return (
              request,
              response.copyWith(
                statusCode: 401,
                body: invalidTokenMessage,
              )
            );
          }

          return (
            request.copyWith(metadata: {
              ...request.metadata,
              jwtKeyword: jwt,
            }),
            response,
          );
        },
        shareWithChildRoutes: shareWithChildRoutes,
      );

  /// Shortcut to get the authentication hook with default settings.
  GazellePreRequestHook get authenticationHook => getAuthenticationHook();
}
