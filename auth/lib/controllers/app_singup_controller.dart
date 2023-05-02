import 'package:auth/models/response_model.dart';
import 'package:auth/utils/app_env.dart';
import 'package:auth/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../models/user.dart';

class AppSingUpController extends ResourceController {
  final ManagedContext managedContext;

  AppSingUpController(this.managedContext);
  @Operation.post()
  Future<Response> singUp(@Bind.body() User user) async {
    if (user.password == null ||
        user.surname == null ||
        user.email == null ||
        user.firstname == null) {
      return Response.badRequest(
          body: AppResponseModel(
              message: "The password, email and username fields are required"));
    }
    final salt = generateRandomSalt();
    final hashPassword = generatePasswordHash(user.password ?? '', salt);

    try {
      late final int id;
      await managedContext.transaction((transaction) async {
        final qCreateUser = Query<User>(transaction)
          ..values.username = user.username
          ..values.email = user.email
          ..values.firstname = user.firstname
          ..values.surname = user.surname
          ..values.patronymic = user.patronymic
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();
        id = createdUser.asMap()["id"];
        await _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return AppResponse.ok(
          body: userData?.backing.contents, message: "Successful registration");
    } catch (error) {
      return AppResponse.serverError(error, message: 'Registranion error');
    }
  }

  Future<void> _updateTokens(int id, ManagedContext transaction) async {
    final Map<String, dynamic> tokens = _getTokens(id);
    final qUpdateTokens = Query<User>(transaction)
      ..where((user) => user.id).equalTo(id)
      ..values.accessToken = tokens["access"]
      ..values.refreshToken = tokens["refresh"];
    await qUpdateTokens.updateOne();
  }

  Map<String, dynamic> _getTokens(int id) {
    final key = AppEnv.secretKey;
    final accessClaimSet =
        JwtClaim(maxAge: Duration(hours: 6), otherClaims: {"id": id});
    final refreshClaimSet =
        JwtClaim(maxAge: Duration(hours: 24), otherClaims: {"id": id});
    final tokens = <String, dynamic>{};
    tokens["access"] = issueJwtHS256(accessClaimSet, key);
    tokens["refresh"] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
