import 'dart:io';

import 'package:auth/models/response_model.dart';
import 'package:auth/models/user.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit/conduit.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';

class AppAuthController extends ResourceController {
  final ManagedContext managedContext;

  AppAuthController(this.managedContext);
  @Operation.post()
  Future<Response> singIn(@Bind.body() User user) async {
    if (user.password == null || user.username == null) {
      return Response.badRequest(
          body: AppResponseModel(
              message: "The password and username fields are required"));
    }

    try {
      final Query<User> qFindUser = Query<User>(managedContext)
        ..where((table) => table.username).equalTo(user.username)
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
        return Response.ok(AppResponseModel(
          data: newUser?.backing.contents,
          message: "Autharization success",
        ));
      } else {
        throw QueryException.conflict("Invalid password", []);
      }
    } on QueryException catch (error) {
      return Response.serverError(
          body: AppResponseModel(message: error.message));
    }
  }

  @Operation.put()
  Future<Response> singUp(@Bind.body() User user) async {
    if (user.password == null || user.username == null || user.email == null) {
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
          ..values.salt = salt
          ..values.hashPassword = hashPassword;

        final createdUser = await qCreateUser.insert();
        id = createdUser.asMap()["id"];
        await _updateTokens(id, transaction);
      });
      final userData = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(
        AppResponseModel(
            data: userData?.backing.contents,
            message: "Successful registration"),
      );
    } on QueryException catch (error) {
      return Response.serverError(
          body: AppResponseModel(message: error.message));
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

  @Operation.post("refresh")
  Future<Response> refreshToken(
      @Bind.path("refresh") String refreshToken) async {
    try {
      final int id = AppUtils.getIdFromToken(refreshToken);
      await _updateTokens(id, managedContext);
      final User? user = await managedContext.fetchObjectWithID<User>(id);
      return Response.ok(AppResponseModel(
        data: user?.backing.contents,
        message: "Tokens updated successfully",
      ));
    } catch (error) {
      return Response.serverError(
          body: AppResponseModel(message: error.toString()));
    }
  }

  Map<String, dynamic> _getTokens(int id) {
    //TODO remove when release
    final key = Platform.environment["SECRET_KEY"] ?? "SECRET_KEY";
    final accessClaimSet =
        JwtClaim(maxAge: Duration(hours: 1), otherClaims: {"id": id});
    final refreshClaimSet = JwtClaim(otherClaims: {"id": id});
    final tokens = <String, dynamic>{};
    tokens["access"] = issueJwtHS256(accessClaimSet, key);
    tokens["refresh"] = issueJwtHS256(refreshClaimSet, key);
    return tokens;
  }
}
