import 'dart:io';

import 'package:auth/models/user.dart';
import 'package:auth/utils/app_constants.dart';
import 'package:auth/utils/app_response.dart';
import 'package:auth/utils/app_utils.dart';
import 'package:conduit/conduit.dart';

class AppUserController extends ResourceController {
  final ManagedContext managedContext;

  AppUserController(this.managedContext);
  @Operation.get()
  Future<Response> getProfile(
      @Bind.header(HttpHeaders.authorizationHeader) String header) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final user = await managedContext.fetchObjectWithID<User>(id);
      user?.removePropertiesFromBackingMap([
        AppConstants.accessToken,
        AppConstants.refreshToken,
      ]);
      return AppResponse.ok(
        message: 'User profile successfully received ',
        body: user?.backing.contents,
      );
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when getting user profile ');
    }
  }

  @Operation.post()
  Future<Response> updateProfile(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() User user,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final fUser = await managedContext.fetchObjectWithID<User>(id);
      final qUserUpdate = Query<User>(managedContext)
        ..where((user) => user.id).equalTo(id)
        ..values.username = user.username ?? fUser?.username
        ..values.email = user.email ?? fUser?.email;
      await qUserUpdate.updateOne();
      final uUser = await managedContext.fetchObjectWithID(id);
      uUser?.removePropertiesFromBackingMap([
        AppConstants.accessToken,
        AppConstants.refreshToken,
      ]);
      return AppResponse.ok(
        message: 'The user has been successfully updated',
        body: uUser?.backing.contents,
      );
    } catch (error) {
      return AppResponse.serverError(error, message: "Error updating data");
    }
  }

  @Operation.put()
  Future<Response> updatePassword() async {
    try {
      return AppResponse.ok(message: 'UpdatePassword ');
    } catch (error) {
      return AppResponse.serverError(error);
    }
  }
}
