<?php

namespace App\Controllers\Api;

class AuthController extends BaseApiController
{
    public function register()
    {
        $json = $this->request->getJSON(true) ?? $this->request->getPost();

        $rules = [
            'username' => 'required|min_length[3]|max_length[50]|is_unique[users.username]',
            'email'    => 'required|valid_email|is_unique[users.email]',
            'password' => 'required|min_length[6]',
        ];

        if (!$this->validateData($json, $rules)) {
            return $this->jsonError('Doğrulama hatası', 422, $this->validator->getErrors());
        }

        $db = \Config\Database::connect();
        $userData = [
            'username'      => trim($json['username']),
            'email'         => trim($json['email']),
            'password_hash' => password_hash($json['password'], PASSWORD_DEFAULT),
            'full_name'     => $json['full_name'] ?? $json['username'],
            'bio'           => $json['bio'] ?? '',
            'avatar'        => $json['avatar'] ?? 'https://api.dicebear.com/7.x/bottts/png?seed=' . urlencode($json['username']),
        ];

        $db->table('users')->insert($userData);
        $userId = $db->insertID();

        $user = $db->table('users')->where('id', $userId)->get()->getRowArray();
        unset($user['password_hash']);

        $token = $this->generateToken(['user_id' => $userId, 'username' => $user['username']]);

        return $this->jsonSuccess([
            'token' => $token,
            'user'  => $user,
        ], 'Kayıt başarılı', 201);
    }

    public function login()
    {
        $json = $this->request->getJSON(true) ?? $this->request->getPost();

        $login = trim($json['login'] ?? $json['email'] ?? $json['username'] ?? '');
        $password = $json['password'] ?? '';

        if (empty($login) || empty($password)) {
            return $this->jsonError('Kullanıcı adı/e-posta ve şifre gereklidir.', 400);
        }

        $db = \Config\Database::connect();
        $user = $db->table('users')
            ->groupStart()
                ->where('email', $login)
                ->orWhere('username', $login)
            ->groupEnd()
            ->get()
            ->getRowArray();

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

    public function profile($userId = null)
    {
        $currentUser = $this->getAuthUser();
        $targetId = $userId ?: ($currentUser['id'] ?? null);

        if (!$targetId) {
            return $this->jsonError('Kullanıcı bulunamadı veya oturum açılmamış.', 401);
        }

        $db = \Config\Database::connect();
        $user = $db->table('users')->where('id', $targetId)->get()->getRowArray();
        if (!$user) {
            return $this->jsonError('Kullanıcı bulunamadı.', 404);
        }
        unset($user['password_hash']);

        // İstatistikler: Takipçi, Takip edilen, İzlenen Film, İzlenen Dizi
        $followersCount = $db->table('follows')->where('following_id', $targetId)->countAllResults();
        $followingCount = $db->table('follows')->where('follower_id', $targetId)->countAllResults();
        
        $watchedMoviesCount = $db->table('watchlist')
            ->where('user_id', $targetId)
            ->where('media_type', 'movie')
            ->where('status', 'watched')
            ->countAllResults();

        $watchedShowsCount = $db->table('watchlist')
            ->where('user_id', $targetId)
            ->where('media_type', 'tv')
            ->where('status', 'watched')
            ->countAllResults();

        $postsCount = $db->table('posts')->where('user_id', $targetId)->countAllResults();

        $isFollowing = false;
        if ($currentUser && $currentUser['id'] != $targetId) {
            $isFollowing = $db->table('follows')
                ->where('follower_id', $currentUser['id'])
                ->where('following_id', $targetId)
                ->countAllResults() > 0;
        }

        $user['stats'] = [
            'followers'      => $followersCount,
            'following'      => $followingCount,
            'watched_movies' => $watchedMoviesCount,
            'watched_shows'  => $watchedShowsCount,
            'posts_count'    => $postsCount,
            'is_following'   => $isFollowing,
        ];

        return $this->jsonSuccess($user, 'Profil getirildi');
    }

    public function updateProfile()
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Yetkisiz erişim.', 401);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();
        $db = \Config\Database::connect();

        $updateData = [];
        if (isset($json['full_name'])) $updateData['full_name'] = trim($json['full_name']);
        if (isset($json['bio'])) $updateData['bio'] = trim($json['bio']);
        if (isset($json['avatar'])) $updateData['avatar'] = trim($json['avatar']);

        if (!empty($updateData)) {
            $db->table('users')->where('id', $user['id'])->update($updateData);
        }

        $updated = $db->table('users')->where('id', $user['id'])->get()->getRowArray();
        unset($updated['password_hash']);

        return $this->jsonSuccess($updated, 'Profil güncellendi');
    }
}

