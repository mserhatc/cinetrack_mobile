<?php

namespace App\Controllers\Api;

class FeedController extends BaseApiController
{
    /**
     * Ana Sayfa Akışı: Kullanıcıların paylaştığı replikler, posterler ve yorumlar
     */
    public function index()
    {
        $currentUser = $this->getAuthUser();
        $db = \Config\Database::connect();

        $page = (int)($this->request->getGet('page') ?? 1);
        $limit = (int)($this->request->getGet('limit') ?? 20);
        $offset = ($page - 1) * $limit;

        // Kullanıcının takip ettiği kişilerin paylaşımları öncelikli listelenir
        $followingIds = [];
        if ($currentUser) {
            $follows = $db->table('follows')
                ->select('following_id')
                ->where('follower_id', $currentUser['id'])
                ->get()
                ->getResultArray();
            $followingIds = array_column($follows, 'following_id');
        }

        $builder = $db->table('posts p')
            ->select('p.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = p.user_id');

        // Takip edilenlerin paylaşımlarını en başa al, ardından diğerlerini getir
        if (!empty($followingIds)) {
            $escapedIds = implode(',', array_map('intval', $followingIds));
            $builder->orderBy("CASE WHEN p.user_id IN ($escapedIds) THEN 1 ELSE 0 END", 'DESC', false);
        }

        $builder->orderBy('p.id', 'DESC')
            ->limit($limit, $offset);

        $posts = $builder->get()->getResultArray();

        // Her post için beğeni durumu
        foreach ($posts as &$post) {
            $post['is_liked'] = false;
            if ($currentUser) {
                $liked = $db->table('post_likes')
                    ->where('post_id', $post['id'])
                    ->where('user_id', $currentUser['id'])
                    ->countAllResults();
                $post['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($posts, 'Akış getirildi');
    }

    /**
     * Belirli bir kullanıcının paylaşımları (Profil / Ben sekmesi)
     */
    public function userPosts($userId = null)
    {
        $currentUser = $this->getAuthUser();
        $targetId = $userId ?: ($currentUser['id'] ?? null);

        if (!$targetId) {
            return $this->jsonError('Kullanıcı belirtilmedi.', 400);
        }

        $db = \Config\Database::connect();
        $posts = $db->table('posts p')
            ->select('p.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.user_id', $targetId)
            ->orderBy('p.id', 'DESC')
            ->get()
            ->getResultArray();

        foreach ($posts as &$post) {
            $post['is_liked'] = false;
            if ($currentUser) {
                $liked = $db->table('post_likes')
                    ->where('post_id', $post['id'])
                    ->where('user_id', $currentUser['id'])
                    ->countAllResults();
                $post['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($posts, 'Kullanıcı paylaşımları getirildi');
    }

    /**
     * Yeni Paylaşım Oluşturma: Replik veya Film/Dizi Posteri + Yorum
     */
    public function create()
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Paylaşım yapmak için giriş yapmalısınız.', 401);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();

        // post_type: quote, review, general
        $postType = $json['post_type'] ?? 'general';
        $content = trim($json['content'] ?? '');
        $quoteText = trim($json['quote_text'] ?? '');

        if ($postType === 'quote' && empty($quoteText) && empty($content)) {
            return $this->jsonError('Lütfen bir replik veya açıklama giriniz.', 422);
        }

        if ($postType === 'review' && empty($content)) {
            return $this->jsonError('Lütfen film/dizi hakkındaki yorumunuzu giriniz.', 422);
        }

        $data = [
            'user_id'     => $user['id'],
            'post_type'   => $postType,
            'tmdb_id'     => !empty($json['tmdb_id']) ? (int)$json['tmdb_id'] : null,
            'media_type'  => in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie',
            'title'       => trim($json['title'] ?? ''),
            'poster_path' => trim($json['poster_path'] ?? ''),
            'quote_text'  => $quoteText ?: null,
            'content'     => $content,
            'rating'      => isset($json['rating']) && $json['rating'] !== '' ? (float)$json['rating'] : null,
            'likes_count' => 0,
            'comments_count' => 0,
        ];

        $db = \Config\Database::connect();
        $db->table('posts')->insert($data);
        $postId = $db->insertID();

        // Eğer puan verilmişse ve tmdb_id varsa, watchlist veya media_reviews tablosuna da izlendi olarak işleyelim
        if ($data['tmdb_id'] && $data['rating'] !== null) {
            $existing = $db->table('watchlist')
                ->where('user_id', $user['id'])
                ->where('tmdb_id', $data['tmdb_id'])
                ->where('media_type', $data['media_type'])
                ->get()
                ->getRowArray();

            if ($existing) {
                $db->table('watchlist')->where('id', $existing['id'])->update([
                    'status' => 'watched',
                    'rating' => $data['rating'],
                ]);
            } else {
                $db->table('watchlist')->insert([
                    'user_id'     => $user['id'],
                    'tmdb_id'     => $data['tmdb_id'],
                    'media_type'  => $data['media_type'],
                    'title'       => $data['title'],
                    'poster_path' => $data['poster_path'],
                    'status'      => 'watched',
                    'rating'      => $data['rating'],
                ]);
            }
        }

        $createdPost = $db->table('posts p')
            ->select('p.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.id', $postId)
            ->get()
            ->getRowArray();

        $createdPost['is_liked'] = false;

        return $this->jsonSuccess($createdPost, 'Paylaşım yapıldı', 201);
    }

    /**
     * Beğeni Toggle (Like/Unlike)
     */
    public function toggleLike($postId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Yetkisiz erişim.', 401);
        }

        $db = \Config\Database::connect();
        $existing = $db->table('post_likes')
            ->where('post_id', $postId)
            ->where('user_id', $user['id'])
            ->get()
            ->getRowArray();

        if ($existing) {
            // Beğeniyi kaldır
            $db->table('post_likes')->where('id', $existing['id'])->delete();
            $db->table('posts')->where('id', $postId)->decrement('likes_count', 1);
            $liked = false;
        } else {
            // Beğen
            $db->table('post_likes')->insert([
                'post_id' => $postId,
                'user_id' => $user['id'],
            ]);
            $db->table('posts')->where('id', $postId)->increment('likes_count', 1);
            $liked = true;
        }

        $post = $db->table('posts')->select('likes_count')->where('id', $postId)->get()->getRowArray();

        return $this->jsonSuccess([
            'is_liked'    => $liked,
            'likes_count' => (int)($post['likes_count'] ?? 0),
        ], $liked ? 'Post beğenildi' : 'Beğeni kaldırıldı');
    }

    /**
     * Posta yorum ekle
     */
    public function addComment($postId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Yorum yapmak için giriş yapmalısınız.', 401);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();
        $comment = trim($json['comment'] ?? '');

        if (empty($comment)) {
            return $this->jsonError('Yorum boş olamaz.', 422);
        }

        $db = \Config\Database::connect();
        $db->table('post_comments')->insert([
            'post_id' => $postId,
            'user_id' => $user['id'],
            'comment' => $comment,
        ]);
        $commentId = $db->insertID();
        $db->table('posts')->where('id', $postId)->increment('comments_count', 1);
        $created = $db->table('post_comments c')
            ->select('c.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.id', $commentId)
            ->get()
            ->getRowArray();

        $created['likes_count'] = 0;
        $created['is_liked'] = false;

        return $this->jsonSuccess($created, 'Yorum eklendi', 201);
    }

    /**
     * Post yorumlarını listele
     */
    public function getComments($postId)
    {
        $currentUser = $this->getAuthUser();
        $db = \Config\Database::connect();
        $comments = $db->table('post_comments c')
            ->select('c.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.post_id', $postId)
            ->orderBy('c.created_at', 'ASC')
            ->get()
            ->getResultArray();

        foreach ($comments as &$c) {
            $c['is_liked'] = false;
            $c['likes_count'] = (int)($c['likes_count'] ?? 0);
            if ($currentUser) {
                $liked = $db->table('comment_likes')
                    ->where('comment_id', $c['id'])
                    ->where('user_id', $currentUser['id'])
                    ->countAllResults();
                $c['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($comments, 'Yorumlar getirildi');
    }

    /**
     * Yorum Düzenle
     */
    public function updateComment($commentId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        $db = \Config\Database::connect();
        $comment = $db->table('post_comments')->where('id', $commentId)->get()->getRowArray();
        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        if ($comment['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi yorumunuzu düzenleyebilirsiniz.', 403);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();
        $newText = trim($json['comment'] ?? '');
        if (empty($newText)) {
            return $this->jsonError('Yorum boş olamaz.', 422);
        }

        $db->table('post_comments')->where('id', $commentId)->update(['comment' => $newText]);

        $updated = $db->table('post_comments c')
            ->select('c.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.id', $commentId)
            ->get()
            ->getRowArray();

        $isLiked = $db->table('comment_likes')
            ->where('comment_id', $commentId)
            ->where('user_id', $user['id'])
            ->countAllResults() > 0;
        $updated['is_liked'] = $isLiked;
        $updated['likes_count'] = (int)($updated['likes_count'] ?? 0);

        return $this->jsonSuccess($updated, 'Yorum güncellendi');
    }

    /**
     * Yorum Sil
     */
    public function deleteComment($commentId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        $db = \Config\Database::connect();
        $comment = $db->table('post_comments')->where('id', $commentId)->get()->getRowArray();
        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        $post = $db->table('posts')->where('id', $comment['post_id'])->get()->getRowArray();
        $isPostOwner = ($post && $post['user_id'] == $user['id']);
        $isCommentOwner = ($comment['user_id'] == $user['id']);

        if (!$isCommentOwner && !$isPostOwner) {
            return $this->jsonError('Bu yorumu silme yetkiniz yok.', 403);
        }

        $db->table('comment_likes')->where('comment_id', $commentId)->delete();
        $db->table('post_comments')->where('id', $commentId)->delete();
        $db->table('posts')->where('id', $comment['post_id'])->decrement('comments_count', 1);

        $remaining = $db->table('post_comments')->where('post_id', $comment['post_id'])->countAllResults();

        return $this->jsonSuccess([
            'id'             => (int)$commentId,
            'post_id'        => (int)$comment['post_id'],
            'comments_count' => $remaining,
        ], 'Yorum silindi');
    }

    /**
     * Yorum Beğeni Toggle (Like/Unlike)
     */
    public function toggleCommentLike($commentId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Yorum beğenmek için giriş yapmalısınız.', 401);
        }

        $db = \Config\Database::connect();
        $comment = $db->table('post_comments')->where('id', $commentId)->get()->getRowArray();
        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        $existing = $db->table('comment_likes')
            ->where('comment_id', $commentId)
            ->where('user_id', $user['id'])
            ->get()
            ->getRowArray();

        if ($existing) {
            $db->table('comment_likes')->where('id', $existing['id'])->delete();
            $db->table('post_comments')->where('id', $commentId)->decrement('likes_count', 1);
            $liked = false;
        } else {
            $db->table('comment_likes')->insert([
                'comment_id' => $commentId,
                'user_id'    => $user['id'],
            ]);
            $db->table('post_comments')->where('id', $commentId)->increment('likes_count', 1);
            $liked = true;
        }

        $c = $db->table('post_comments')->select('likes_count')->where('id', $commentId)->get()->getRowArray();

        return $this->jsonSuccess([
            'comment_id'  => (int)$commentId,
            'is_liked'    => $liked,
            'likes_count' => (int)($c['likes_count'] ?? 0),
        ], $liked ? 'Yorum beğenildi' : 'Yorum beğenisi geri alındı');
    }

    /**
     * Post Düzenle
     */
    public function updatePost($postId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        $db = \Config\Database::connect();
        $post = $db->table('posts')->where('id', $postId)->get()->getRowArray();
        if (!$post) {
            return $this->jsonError('Paylaşım bulunamadı.', 404);
        }

        if ($post['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi paylaşımlarınızı düzenleyebilirsiniz.', 403);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();
        $updateData = [];

        if (array_key_exists('content', $json)) {
            $updateData['content'] = trim($json['content']);
        }
        if (array_key_exists('quote_text', $json)) {
            $updateData['quote_text'] = trim($json['quote_text']);
        }
        if (isset($json['rating']) && $json['rating'] !== '') {
            $updateData['rating'] = (float)$json['rating'];
        }

        if (!empty($updateData)) {
            $db->table('posts')->where('id', $postId)->update($updateData);
        }

        $updated = $db->table('posts p')
            ->select('p.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.id', $postId)
            ->get()
            ->getRowArray();

        $liked = $db->table('post_likes')
            ->where('post_id', $postId)
            ->where('user_id', $user['id'])
            ->countAllResults();
        $updated['is_liked'] = ($liked > 0);

        return $this->jsonSuccess($updated, 'Paylaşım güncellendi');
    }

    /**
     * Post Sil
     */
    public function deletePost($postId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        $db = \Config\Database::connect();
        $post = $db->table('posts')->where('id', $postId)->get()->getRowArray();
        if (!$post) {
            return $this->jsonError('Paylaşım bulunamadı.', 404);
        }

        if ($post['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi paylaşımlarınızı silebilirsiniz.', 403);
        }

        // Yorumların beğenilerini temizle
        $comments = $db->table('post_comments')->select('id')->where('post_id', $postId)->get()->getResultArray();
        if (!empty($comments)) {
            $cIds = array_column($comments, 'id');
            $db->table('comment_likes')->whereIn('comment_id', $cIds)->delete();
        }

        // Post beğenilerini ve yorumlarını sil
        $db->table('post_likes')->where('post_id', $postId)->delete();
        $db->table('post_comments')->where('post_id', $postId)->delete();
        $db->table('posts')->where('id', $postId)->delete();

        return $this->jsonSuccess(['id' => (int)$postId], 'Paylaşım silindi');
    }
}

