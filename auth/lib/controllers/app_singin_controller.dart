import 'package:auth/models/response_model.dart';
import 'package:auth/utils/app_env.dart';
import 'package:auth/utils/app_response.dart';
import 'package:conduit_core/conduit_core.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

import '../models/user.dart';

class AppSingInController extends ResourceController {
  final ManagedContext managedContext;

  AppSingInController(this.managedContext);
  @Operation.post()
  Future<Response> singIn(@Bind.body() User user) async {
    if (user.password == null || user.email == null) {
      return Response.badRequest(
          body: AppResponseModel(
              message: "The password and email fields are required"));
    }

    try {
      final Query<User> qFindUser = Query<User>(managedContext)
        ..where((table) => table.email).equalTo(user.email)
        ..returningProperties((table) => [
              table.id,
              table.salt,
              table.hashPassword,
            ]);
      final User? findUser = await qFindUser.fetchOne();
      if (findUser == null) {
        throw QueryException.conflict("User not found", []);
      }
      final String requestHashPassword =
          generatePasswordHash(user.password ?? '', findUser.salt ?? '');
      if (requestHashPassword == findUser.hashPassword) {
        await _updateTokens(findUser.id ?? -1, managedContext);
        final User? newUser =
            await managedContext.fetchObjectWithID<User>(findUser.id);
        return AppResponse.ok(
          body: newUser?.backing.contents,
          message: "Autharization success",
        );
      } else {
        throw QueryException.conflict("Invalid password", []);
      }
    } catch (error) {
      return AppResponse.serverError(error, message: 'Authorization error');
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
