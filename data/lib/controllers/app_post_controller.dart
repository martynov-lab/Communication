import 'dart:io';

import 'package:data/utils/app_response.dart';
import 'package:conduit/conduit.dart';
import 'package:data/models/post.dart';
import 'package:data/models/author.dart';
import 'package:data/utils/app_utils.dart';

class AppPostController extends ResourceController {
  final ManagedContext managedContext;

  AppPostController(this.managedContext);

  @Operation.post()
  Future<Response> reatePost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.body() Post post,
  ) async {
    try {
      if (post.content == null ||
          post.content?.isEmpty == true ||
          post.name == null ||
          post.name?.isEmpty == true) {
        return AppResponse.badRequest(
            message: 'The name and content fields are mandatory');
      }
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
      qCreatePost.insert();

      return AppResponse.ok(message: 'Posts  successfully created ');
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when creating posts ');
    }
  }

  @Operation.get("id")
  Future<Response> getPost(
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

      // post.backing.removeProperty("author");

      return AppResponse.ok(
        body: post.backing.contents,
        message: 'Posts fetched  successfully',
      );
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when fetching post by id');
    }
  }

  @Operation.get()
  Future<Response> getPosts(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
  ) async {
    try {
      final id = AppUtils.getIdFromHeader(header);
      final qGetPosts = Query<Post>(managedContext)
        ..where((post) => post.author?.id).equalTo(id);
      final List<Post> posts = await qGetPosts.fetch();
      if (posts.isEmpty) {
        return Response.notFound();
      } else {
        return Response.ok(posts);
      }
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when getting posts');
    }
  }

  @Operation.delete("id")
  Future<Response> deletePost(
    @Bind.header(HttpHeaders.authorizationHeader) String header,
    @Bind.path("id") int id,
  ) async {
    try {
      final currentAuthotId = AppUtils.getIdFromHeader(header);
      final post = await managedContext.fetchObjectWithID<Post>(id);
      if (post == null) {
        return AppResponse.ok(message: 'This post was not found');
      }
      if (post.author?.id != currentAuthotId) {
        return AppResponse.ok(message: 'No access to the post');
      }
      final qDeletePost = Query<Post>(managedContext)
        ..where((post) => post.id).equalTo(id);

      await qDeletePost.delete();

      return AppResponse.ok(
        message: 'Post successfully deleted',
      );
    } catch (error) {
      return AppResponse.serverError(error,
          message: 'Error when deleting post');
    }
  }
}
