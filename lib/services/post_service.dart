import 'package:supabase_flutter/supabase_flutter.dart';

class PostService {
  final SupabaseClient client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchPosts({
    int limit = 10,
    int offset = 0,
    String? searchQuery,
  }) async {
    final response = await client
        .from('posts')
        .select('*, post_images(*), profiles!user_id(name, avatar_url), comments(count)')
        .filter(
      'title',
      'ilike',
      '%${searchQuery ?? ''}%',
    )
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    print('Posts response: $response');
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> fetchPostById(String id) async {
    return await client
        .from('posts')
        .select('*, post_images(*), profiles!user_id(name, avatar_url), comments(count)')
        .eq('id', id)
        .single();
  }

  Future<Map<String, dynamic>> createPost(Map<String, dynamic> post) async {
    return await client.from('posts').insert(post).select().single();
  }

  Future<void> updatePost(String id, Map<String, dynamic> updates) async {
    await client.from('posts').update(updates).eq('id', id);
  }

  Future<void> deletePost(String id) async {
    await client.from('posts').delete().eq('id', id);
  }

  Future<void> addPostImage(Map<String, dynamic> image) async {
    await client.from('post_images').insert(image);
  }

  Future<void> deletePostImage(String id) async {
    await client.from('post_images').delete().eq('id', id);
  }
}