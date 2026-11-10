<?php

namespace App\Controllers\Api;

class UserController extends BaseApiController
{
    /**
     * Takip Et / Takipten Çık (Toggle)
     */
    public function toggleFollow($targetUserId)
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        if ($user['id'] == $targetUserId) {
            return $this->jsonError('Kendinizi takip edemezsiniz.', 400);
        }

        $db = \Config\Database::connect();
        $existing = $db->table('follows')
            ->where('follower_id', $user['id'])
            ->where('following_id', $targetUserId)
            ->get()
            ->getRowArray();

        if ($existing) {
            $db->table('follows')->where('id', $existing['id'])->delete();
            $following = false;
        } else {
            $db->table('follows')->insert([
                'follower_id'  => $user['id'],
                'following_id' => $targetUserId,
            ]);
            $following = true;
        }

        $followersCount = $db->table('follows')->where('following_id', $targetUserId)->countAllResults();

        return $this->jsonSuccess([
            'is_following'    => $following,
            'followers_count' => $followersCount,
        ], $following ? 'Takip edildi' : 'Takipten çıkıldı');
    }

    /**
     * Kullanıcının Takipçileri
     */
    public function getFollowers($userId)
    {
        $db = \Config\Database::connect();
        $followers = $db->table('follows f')
            ->select('u.id, u.username, u.full_name, u.avatar, u.bio, f.created_at as followed_at')
            ->join('users u', 'u.id = f.follower_id')
            ->where('f.following_id', $userId)
            ->orderBy('f.created_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($followers, 'Takipçiler listesi');
    }

    /**
     * Kullanıcının Takip Ettikleri
     */
    public function getFollowing($userId)
    {
        $db = \Config\Database::connect();
        $following = $db->table('follows f')
            ->select('u.id, u.username, u.full_name, u.avatar, u.bio, f.created_at as followed_at')
            ->join('users u', 'u.id = f.following_id')
            ->where('f.follower_id', $userId)
            ->orderBy('f.created_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($following, 'Takip edilenler listesi');
    }

    /**
     * Kullanıcının İzlediği Filmler
     */
    public function getWatchedMovies($userId)
    {
        $db = \Config\Database::connect();
        $movies = $db->table('watchlist')
            ->where('user_id', $userId)
            ->where('media_type', 'movie')
            ->where('status', 'watched')
            ->orderBy('updated_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($movies, 'İzlenen filmler listesi');
    }

    /**
     * Kullanıcının İzlediği Diziler
     */
    public function getWatchedShows($userId)
    {
        $db = \Config\Database::connect();
        $shows = $db->table('watchlist')
            ->where('user_id', $userId)
            ->where('media_type', 'tv')
            ->where('status', 'watched')
            ->orderBy('updated_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($shows, 'İzlenen diziler listesi');
    }

    /**
     * Kullanıcının İzleme Listesi (Plan to watch)
     */
    public function getWatchlist($userId)
    {
        $db = \Config\Database::connect();
        $list = $db->table('watchlist')
            ->where('user_id', $userId)
            ->where('status', 'plan_to_watch')
            ->orderBy('updated_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($list, 'İzleme listesi');
    }
}

