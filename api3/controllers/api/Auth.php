<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Auth extends BaseApiController
{
    /**
     * Yeni Kullanıcı Kaydı
     */
    public function register()
    {
        $json = $this->getRequestJson();

        $username = trim($json['username'] ?? '');
        $email    = trim($json['email'] ?? '');
        $password = $json['password'] ?? '';
        $fullName = trim($json['full_name'] ?? '');
        $bio      = trim($json['bio'] ?? '');
        $avatar   = trim($json['avatar'] ?? '');

        if (empty($username) || strlen($username) < 3) {
            return $this->jsonError('Kullanıcı adı en az 3 karakter olmalıdır.', 422);
        }
        if (empty($email) || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            return $this->jsonError('Geçerli bir e-posta adresi giriniz.', 422);
        }
        if (empty($password) || strlen($password) < 6) {
            return $this->jsonError('Şifre en az 6 karakter olmalıdır.', 422);
        }

        // Benzersizlik kontrolü
        $exists = $this->db->group_start()
            ->where('username', $username)
            ->or_where('email', $email)
            ->group_end()
            ->get('users')
            ->row_array();

        if ($exists) {
            return $this->jsonError('Bu kullanıcı adı veya e-posta zaten kullanımda.', 422);
        }

        if (empty($avatar)) {
            $avatar = 'https://api.dicebear.com/7.x/bottts/png?seed=' . urlencode($username);
        }

        $userData = [
            'username'      => $username,
            'email'         => $email,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'full_name'     => !empty($fullName) ? $fullName : $username,
            'bio'           => $bio,
            'avatar'        => $avatar,
        ];

        $this->db->insert('users', $userData);
        $userId = $this->db->insert_id();

        $user = $this->db->get_where('users', ['id' => $userId])->row_array();
        unset($user['password_hash']);

        $token = $this->generateToken(['user_id' => $userId, 'username' => $user['username']]);

        return $this->jsonSuccess([
            'token' => $token,
            'user'  => $user,
        ], 'Kayıt başarılı', 201);
    }

    /**
     * Kullanıcı Girişi
     */
    public function login()
    {
        $json = $this->getRequestJson();

        $login = trim($json['login'] ?? $json['email'] ?? $json['username'] ?? '');
        $password = $json['password'] ?? '';

        if (empty($login) || empty($password)) {
            return $this->jsonError('Kullanıcı adı/e-posta ve şifre gereklidir.', 400);
        }

        $user = $this->db->group_start()
            ->where('email', $login)
            ->or_where('username', $login)
            ->group_end()
            ->get('users')
            ->row_array();

        if (!$user || !password_verify($password, $user['password_hash'])) {
            return $this->jsonError('Geçersiz kullanıcı adı veya şifre.', 401);
        }

        unset($user['password_hash']);
        $token = $this->generateToken(['user_id' => $user['id'], 'username' => $user['username']]);

        return $this->jsonSuccess([
            'token' => $token,
            'user'  => $user,
        ], 'Giriş başarılı');
    }

    /**
     * Profil Detayı (Kendi veya Hedef Kullanıcı)
     */
    public function profile($userId = null)
    {
        $currentUser = $this->getAuthUser();
        $targetId = $userId ? (int)$userId : ($currentUser['id'] ?? null);

        if (!$targetId) {
            return $this->jsonError('Kullanıcı bulunamadı veya oturum açılmamış.', 401);
        }

        $user = $this->db->get_where('users', ['id' => $targetId])->row_array();
        if (!$user) {
            return $this->jsonError('Kullanıcı bulunamadı.', 404);
        }
        unset($user['password_hash']);

        // İstatistikler
        $followersCount = $this->db->where('following_id', $targetId)->count_all_results('follows');
        $followingCount = $this->db->where('follower_id', $targetId)->count_all_results('follows');

        $watchedMoviesCount = $this->db->where('user_id', $targetId)
            ->where('media_type', 'movie')
            ->where('status', 'watched')
            ->count_all_results('watchlist');

        $watchedShowsCount = $this->db->where('user_id', $targetId)
            ->where('media_type', 'tv')
            ->where('status', 'watched')
            ->count_all_results('watchlist');

        $postsCount = $this->db->where('user_id', $targetId)->count_all_results('posts');

        $isFollowing = false;
        if ($currentUser && $currentUser['id'] != $targetId) {
            $isFollowing = $this->db->where('follower_id', $currentUser['id'])
                ->where('following_id', $targetId)
                ->count_all_results('follows') > 0;
        }

        $user['stats'] = [
            'followers'      => (int)$followersCount,
            'following'      => (int)$followingCount,
            'watched_movies' => (int)$watchedMoviesCount,
            'watched_shows'  => (int)$watchedShowsCount,
            'posts_count'    => (int)$postsCount,
            'is_following'   => (bool)$isFollowing,
        ];

        return $this->jsonSuccess($user, 'Profil getirildi');
    }

    /**
     * Kendi Profilini Güncelleme
     */
    public function updateProfile()
    {
        $user = $this->requireAuth();
        $json = $this->getRequestJson();

        $updateData = [];
        if (isset($json['full_name'])) $updateData['full_name'] = trim($json['full_name']);
        if (isset($json['bio']))       $updateData['bio']       = trim($json['bio']);
        if (isset($json['avatar']))    $updateData['avatar']    = trim($json['avatar']);

        if (!empty($updateData)) {
            $this->db->where('id', $user['id'])->update('users', $updateData);
        }

        $updated = $this->db->get_where('users', ['id' => $user['id']])->row_array();
        unset($updated['password_hash']);

        return $this->jsonSuccess($updated, 'Profil güncellendi');
    }
}

