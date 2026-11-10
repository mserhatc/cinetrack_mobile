<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Feed extends BaseApiController
{
    /**
     * Ana Sayfa Akışı: Takip edilenlerin paylaşımları öncelikli
     */
    public function index()
    {
        $currentUser = $this->getAuthUser();

        $page = (int)($this->input->get('page') ?: 1);
        $limit = (int)($this->input->get('limit') ?: 20);
        $offset = ($page - 1) * $limit;

        // Kullanıcının takip ettiği kişilerin id'leri
        $followingIds = [];
        if ($currentUser) {
            $follows = $this->db->select('following_id')
                ->where('follower_id', $currentUser['id'])
                ->get('follows')
                ->result_array();
            $followingIds = array_column($follows, 'following_id');
        }

        $this->db->select('p.*, u.username, u.full_name, u.avatar')
            ->from('posts p')
            ->join('users u', 'u.id = p.user_id');

        if (!empty($followingIds)) {
            $escapedIds = implode(',', array_map('intval', $followingIds));
            $this->db->order_by("CASE WHEN p.user_id IN ($escapedIds) THEN 1 ELSE 0 END", 'DESC', FALSE);
        }

        $this->db->order_by('p.id', 'DESC')
            ->limit($limit, $offset);

        $posts = $this->db->get()->result_array();

        // Beğeni durumu kontrolü
        foreach ($posts as &$post) {
            $post['is_liked'] = false;
            if ($currentUser) {
                $liked = $this->db->where('post_id', $post['id'])
                    ->where('user_id', $currentUser['id'])
                    ->count_all_results('post_likes');
                $post['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($posts, 'Akış getirildi');
    }

    /**
     * Belirli bir kullanıcının paylaşımları
     */
    public function userPosts($userId = null)
    {
        $currentUser = $this->getAuthUser();
        $targetId = $userId ? (int)$userId : ($currentUser['id'] ?? null);

        if (!$targetId) {
            return $this->jsonError('Kullanıcı belirtilmedi.', 400);
        }

        $posts = $this->db->select('p.*, u.username, u.full_name, u.avatar')
            ->from('posts p')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.user_id', $targetId)
            ->order_by('p.id', 'DESC')
            ->get()
            ->result_array();

        foreach ($posts as &$post) {
            $post['is_liked'] = false;
            if ($currentUser) {
                $liked = $this->db->where('post_id', $post['id'])
                    ->where('user_id', $currentUser['id'])
                    ->count_all_results('post_likes');
                $post['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($posts, 'Kullanıcı paylaşımları getirildi');
    }

    /**
     * Yeni Paylaşım Oluşturma
     */
    public function create()
    {
        $user = $this->requireAuth();
        $json = $this->getRequestJson();

        $postType  = $json['post_type'] ?? 'general';
        $content   = trim($json['content'] ?? '');
        $quoteText = trim($json['quote_text'] ?? '');

        if ($postType === 'quote' && empty($quoteText) && empty($content)) {
            return $this->jsonError('Lütfen bir replik veya açıklama giriniz.', 422);
        }

        if ($postType === 'review' && empty($content)) {
            return $this->jsonError('Lütfen film/dizi hakkındaki yorumunuzu giriniz.', 422);
        }

        $data = [
            'user_id'        => $user['id'],
            'post_type'      => $postType,
            'tmdb_id'        => !empty($json['tmdb_id']) ? (int)$json['tmdb_id'] : null,
            'media_type'     => in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie',
            'title'          => trim($json['title'] ?? ''),
            'poster_path'    => trim($json['poster_path'] ?? ''),
            'quote_text'     => $quoteText ?: null,
            'content'        => $content,
            'rating'         => isset($json['rating']) && $json['rating'] !== '' ? (float)$json['rating'] : null,
            'likes_count'    => 0,
            'comments_count' => 0,
        ];

        $this->db->insert('posts', $data);
        $postId = $this->db->insert_id();

        // Watchlist izlendi kaydı senkronizasyonu
        if ($data['tmdb_id'] && $data['rating'] !== null) {
            $existing = $this->db->get_where('watchlist', [
                'user_id'    => $user['id'],
                'tmdb_id'    => $data['tmdb_id'],
                'media_type' => $data['media_type'],
            ])->row_array();

            if ($existing) {
                $this->db->where('id', $existing['id'])->update('watchlist', [
                    'status' => 'watched',
                    'rating' => $data['rating'],
                ]);
            } else {
                $this->db->insert('watchlist', [
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

        $createdPost = $this->db->select('p.*, u.username, u.full_name, u.avatar')
            ->from('posts p')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.id', $postId)
            ->get()
            ->row_array();

        $createdPost['is_liked'] = false;

        return $this->jsonSuccess($createdPost, 'Paylaşım yapıldı', 201);
    }

    /**
     * RESTful Post İşleyicisi (/api/feed/post/:id - PUT/DELETE)
     */
    public function post($postId)
    {
        $method = strtoupper($this->input->server('REQUEST_METHOD'));
        if ($method === 'PUT') {
            return $this->updatePost($postId);
        } elseif ($method === 'DELETE') {
            return $this->deletePost($postId);
        }
        return $this->jsonError('Method not allowed', 405);
    }

    /**
     * Post Düzenle
     */
    public function updatePost($postId)
    {
        $user = $this->requireAuth();
        $post = $this->db->get_where('posts', ['id' => $postId])->row_array();

        if (!$post) {
            return $this->jsonError('Paylaşım bulunamadı.', 404);
        }

        if ($post['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi paylaşımlarınızı düzenleyebilirsiniz.', 403);
        }

        $json = $this->getRequestJson();
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
            $this->db->where('id', $postId)->update('posts', $updateData);
        }

        $updated = $this->db->select('p.*, u.username, u.full_name, u.avatar')
            ->from('posts p')
            ->join('users u', 'u.id = p.user_id')
            ->where('p.id', $postId)
            ->get()
            ->row_array();

        $liked = $this->db->where('post_id', $postId)
            ->where('user_id', $user['id'])
            ->count_all_results('post_likes');
        $updated['is_liked'] = ($liked > 0);

        return $this->jsonSuccess($updated, 'Paylaşım güncellendi');
    }

    /**
     * Post Sil
     */
    public function deletePost($postId)
    {
        $user = $this->requireAuth();
        $post = $this->db->get_where('posts', ['id' => $postId])->row_array();

        if (!$post) {
            return $this->jsonError('Paylaşım bulunamadı.', 404);
        }

        if ($post['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi paylaşımlarınızı silebilirsiniz.', 403);
        }

        // İlgili yorumların beğenilerini temizle
        $comments = $this->db->select('id')->where('post_id', $postId)->get('post_comments')->result_array();
        if (!empty($comments)) {
            $cIds = array_column($comments, 'id');
            $this->db->where_in('comment_id', $cIds)->delete('comment_likes');
        }

        $this->db->where('post_id', $postId)->delete('post_likes');
        $this->db->where('post_id', $postId)->delete('post_comments');
        $this->db->where('id', $postId)->delete('posts');

        return $this->jsonSuccess(['id' => (int)$postId], 'Paylaşım silindi');
    }

    /**
     * Post Beğeni Toggle
     */
    public function toggleLike($postId)
    {
        $user = $this->requireAuth();

        $existing = $this->db->get_where('post_likes', [
            'post_id' => $postId,
            'user_id' => $user['id'],
        ])->row_array();

        if ($existing) {
            $this->db->where('id', $existing['id'])->delete('post_likes');
            $this->db->set('likes_count', 'GREATEST(likes_count - 1, 0)', FALSE)->where('id', $postId)->update('posts');
            $liked = false;
        } else {
            $this->db->insert('post_likes', [
                'post_id' => $postId,
                'user_id' => $user['id'],
            ]);
            $this->db->set('likes_count', 'likes_count + 1', FALSE)->where('id', $postId)->update('posts');
            $liked = true;
        }

        $post = $this->db->select('likes_count')->where('id', $postId)->get('posts')->row_array();

        return $this->jsonSuccess([
            'is_liked'    => $liked,
            'likes_count' => (int)($post['likes_count'] ?? 0),
        ], $liked ? 'Post beğenildi' : 'Beğeni kaldırıldı');
    }

    /**
     * Post Yorumlarını Getir
     */
    public function getComments($postId)
    {
        $currentUser = $this->getAuthUser();

        $comments = $this->db->select('c.*, u.username, u.full_name, u.avatar')
            ->from('post_comments c')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.post_id', $postId)
            ->order_by('c.created_at', 'ASC')
            ->get()
            ->result_array();

        foreach ($comments as &$c) {
            $c['is_liked'] = false;
            $c['likes_count'] = (int)($c['likes_count'] ?? 0);
            if ($currentUser) {
                $liked = $this->db->where('comment_id', $c['id'])
                    ->where('user_id', $currentUser['id'])
                    ->count_all_results('comment_likes');
                $c['is_liked'] = ($liked > 0);
            }
        }

        return $this->jsonSuccess($comments, 'Yorumlar getirildi');
    }

    /**
     * RESTful Comment Yönlendiricisi (/api/feed/comment/:param)
     */
    public function comment($param)
    {
        $method = strtoupper($this->input->server('REQUEST_METHOD'));
        if ($method === 'PUT') {
            return $this->updateComment($param);
        } elseif ($method === 'DELETE') {
            return $this->deleteComment($param);
        } else {
            // POST /api/feed/comment/:postId
            return $this->addComment($param);
        }
    }

    /**
     * Posta Yorum Ekle
     */
    public function addComment($postId)
    {
        $user = $this->requireAuth();
        $json = $this->getRequestJson();
        $comment = trim($json['comment'] ?? '');

        if (empty($comment)) {
            return $this->jsonError('Yorum boş olamaz.', 422);
        }

        $this->db->insert('post_comments', [
            'post_id' => $postId,
            'user_id' => $user['id'],
            'comment' => $comment,
        ]);
        $commentId = $this->db->insert_id();

        $this->db->set('comments_count', 'comments_count + 1', FALSE)->where('id', $postId)->update('posts');

        $created = $this->db->select('c.*, u.username, u.full_name, u.avatar')
            ->from('post_comments c')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.id', $commentId)
            ->get()
            ->row_array();

        $created['likes_count'] = 0;
        $created['is_liked'] = false;

        return $this->jsonSuccess($created, 'Yorum eklendi', 201);
    }

    /**
     * Yorum Düzenle
     */
    public function updateComment($commentId)
    {
        $user = $this->requireAuth();
        $comment = $this->db->get_where('post_comments', ['id' => $commentId])->row_array();

        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        if ($comment['user_id'] != $user['id']) {
            return $this->jsonError('Yalnızca kendi yorumunuzu düzenleyebilirsiniz.', 403);
        }

        $json = $this->getRequestJson();
        $newText = trim($json['comment'] ?? '');
        if (empty($newText)) {
            return $this->jsonError('Yorum boş olamaz.', 422);
        }

        $this->db->where('id', $commentId)->update('post_comments', ['comment' => $newText]);

        $updated = $this->db->select('c.*, u.username, u.full_name, u.avatar')
            ->from('post_comments c')
            ->join('users u', 'u.id = c.user_id')
            ->where('c.id', $commentId)
            ->get()
            ->row_array();

        $isLiked = $this->db->where('comment_id', $commentId)
            ->where('user_id', $user['id'])
            ->count_all_results('comment_likes') > 0;

        $updated['is_liked'] = $isLiked;
        $updated['likes_count'] = (int)($updated['likes_count'] ?? 0);

        return $this->jsonSuccess($updated, 'Yorum güncellendi');
    }

    /**
     * Yorum Sil
     */
    public function deleteComment($commentId)
    {
        $user = $this->requireAuth();
        $comment = $this->db->get_where('post_comments', ['id' => $commentId])->row_array();

        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        $post = $this->db->get_where('posts', ['id' => $comment['post_id']])->row_array();
        $isPostOwner = ($post && $post['user_id'] == $user['id']);
        $isCommentOwner = ($comment['user_id'] == $user['id']);

        if (!$isCommentOwner && !$isPostOwner) {
            return $this->jsonError('Bu yorumu silme yetkiniz yok.', 403);
        }

        $this->db->where('comment_id', $commentId)->delete('comment_likes');
        $this->db->where('id', $commentId)->delete('post_comments');
        $this->db->set('comments_count', 'GREATEST(comments_count - 1, 0)', FALSE)->where('id', $comment['post_id'])->update('posts');

        $remaining = $this->db->where('post_id', $comment['post_id'])->count_all_results('post_comments');

        return $this->jsonSuccess([
            'id'             => (int)$commentId,
            'post_id'        => (int)$comment['post_id'],
            'comments_count' => (int)$remaining,
        ], 'Yorum silindi');
    }

    /**
     * Yorum Beğeni Toggle
     */
    public function toggleCommentLike($commentId)
    {
        $user = $this->requireAuth();
        $comment = $this->db->get_where('post_comments', ['id' => $commentId])->row_array();

        if (!$comment) {
            return $this->jsonError('Yorum bulunamadı.', 404);
        }

        $existing = $this->db->get_where('comment_likes', [
            'comment_id' => $commentId,
            'user_id'    => $user['id'],
        ])->row_array();

        if ($existing) {
            $this->db->where('id', $existing['id'])->delete('comment_likes');
            $this->db->set('likes_count', 'GREATEST(likes_count - 1, 0)', FALSE)->where('id', $commentId)->update('post_comments');
            $liked = false;
        } else {
            $this->db->insert('comment_likes', [
                'comment_id' => $commentId,
                'user_id'    => $user['id'],
            ]);
            $this->db->set('likes_count', 'likes_count + 1', FALSE)->where('id', $commentId)->update('post_comments');
            $liked = true;
        }

        $c = $this->db->select('likes_count')->where('id', $commentId)->get('post_comments')->row_array();

        return $this->jsonSuccess([
            'comment_id'  => (int)$commentId,
            'is_liked'    => $liked,
            'likes_count' => (int)($c['likes_count'] ?? 0),
        ], $liked ? 'Yorum beğenildi' : 'Yorum beğenisi geri alındı');
    }
}

