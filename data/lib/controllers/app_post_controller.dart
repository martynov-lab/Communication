import 'package:data/utils/app_response.dart';
import 'package:conduit/conduit.dart';

class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);
  @Operation.get()
  Future<Response> getPosts() async {
    try {
      //
      return AppResponse.ok(message: 'Posts  successfully received ');
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when getting posts ');
    }
  }
}
