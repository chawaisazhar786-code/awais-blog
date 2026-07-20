import 'package:supabase_flutter/supabase_flutter.dart';

class CommentService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    return await client
        .from('comments')
        .select('*, comment_images(*), profiles!user_id(name, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
  }

  Future<Map<String, dynamic>> createComment(Map<String, dynamic> comment) async {
    return await client.from('comments').insert(comment).select().single();
  }

  Future<void> updateComment(String id, Map<String, dynamic> updates) async {
    await client.from('comments').update(updates).eq('id', id);
  }

  Future<void> deleteComment(String id) async {
    await client.from('comments').delete().eq('id', id);
  }

  Future<void> addCommentImage(Map<String, dynamic> image) async {
    await client.from('comment_images').insert(image);
  }

  Future<void> deleteCommentImage(String id) async {
    await client.from('comment_images').delete().eq('id', id);
  }
}