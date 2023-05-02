import 'dart:io';

import 'package:conduit_core/conduit_core.dart';
import 'package:data/utils/app_response.dart';
import 'package:data/models/post.dart';
import 'package:data/models/author.dart';
import 'package:data/utils/app_utils.dart';

class AppRoomController extends ResourceController {
  final ManagedContext managedContext;

  AppRoomController(this.managedContext);

  @Operation.post("create")
  Future<Response> createRoom(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Post post,
  ) async {
    if (post.content == null ||
        post.content?.isEmpty == true ||
        post.name == null ||
        post.name?.isEmpty == true) {
      return AppResponse.badRequest(
          message: 'The name and content fields are mandatory');
    }
    try {
      final id = AppUtils.getIdFromHeader(header);
      final author = await managedContext.fetchObjectWithID<Author>(id);
      if (author == null) {
        final qCreateAuthor = Query<Author>(managedContext)..values.id = id;
        qCreateAuthor.insert();
      }
      final int sizePost = post.content?.length ?? 0;
      final qCreatePost = Query<Post>(managedContext)
        ..values.author?.id = id
        ..values.name = post.name
        ..values.preContent =
            post.content?.substring(0, sizePost <= 20 ? sizePost : 20)
        ..values.content = post.content;
      await qCreatePost.insert();
      return AppResponse.ok(message: 'Posts  successfully created ');
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when creating posts ');
    }
  }

  @Operation.get("id")
  Future<Response> getRoom(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
  ) async {
    try {
      final currentAuthotId = AppUtils.getIdFromHeader(header);
      final qGetPost = Query<Post>(managedContext)
        ..where((post) => post.id).equalTo(id)
        ..where((post) => post.author?.id).equalTo(currentAuthotId)
        ..returningProperties((post) => [
              post.id,
              post.name,
              post.content,
            ]);
      final post = await qGetPost.fetchOne();
      if (post == null) {
        return AppResponse.ok(message: 'This post was not found');
      }
      return AppResponse.ok(
          body: post.backing.contents, message: 'Posts fetched  successfully');
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when fetching post by id');
    }
  }

  @Operation.get()
  Future<Response> getRooms(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.query("fetchLimit") int fetchLimit,
    @Bind.query("offset") int offset,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qGetPosts = Query<Post>(managedContext)
        ..where((x) => x.author?.id).equalTo(id)
        ..fetchLimit = fetchLimit
        ..offset = offset;
      final List<Post> posts = await qGetPosts.fetch();
      if (posts.isEmpty) return AppResponse.ok(message: "Посты не найдены");
      return Response.ok(posts);
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка получения постов");
    }
  }

  @Operation.delete("id")
  Future<Response> deleteRoom(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
  ) async {
    try {
      final currentAuthorId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.ok(message: "Пост не найден");
      }
      if (post.author?.id != currentAuthorId) {
        return AppResponse.ok(message: "Нет доступа к посту");
      }
      final qDeletePost = Query<Post>(managedContext)
        ..where((x) => x.id).equalTo(id);
      await qDeletePost.delete();
      return AppResponse.ok(message: "Успешное удаление поста");
    } catch (error) {
      return AppResponse.serverError(error, message: "Ошибка удаления поста");
    }
  }
}
