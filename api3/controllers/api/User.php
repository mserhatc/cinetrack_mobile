<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class User extends BaseApiController
{
    /**
     * Takip Et / Takipten Çık (Toggle)
     */
    public function toggleFollow($targetUserId)
    {
        $user = $this->requireAuth();

        if ($user['id'] == $targetUserId) {
            return $this->jsonError('Kendinizi takip edemezsiniz.', 400);
        }

        $existing = $this->db->get_where('follows', [
            'follower_id'  => $user['id'],
            'following_id' => $targetUserId,
        ])->row_array();

        if ($existing) {
            $this->db->where('id', $existing['id'])->delete('follows');
            $following = false;
        } else {
            $this->db->insert('follows', [
                'follower_id'  => $user['id'],
                'following_id' => $targetUserId,
            ]);
            $following = true;
        }

        $followersCount = $this->db->where('following_id', $targetUserId)->count_all_results('follows');

        return $this->jsonSuccess([
            'is_following'    => $following,
            'followers_count' => (int)$followersCount,
        ], $following ? 'Takip edildi' : 'Takipten çıkıldı');
    }

    /**
     * Kullanıcının Takipçileri
     */
    public function getFollowers($userId)
    {
        $followers = $this->db->select('u.id, u.username, u.full_name, u.avatar, u.bio, f.created_at as followed_at')
            ->from('follows f')
            ->join('users u', 'u.id = f.follower_id')
            ->where('f.following_id', (int)$userId)
            ->order_by('f.created_at', 'DESC')
            ->get()
            ->result_array();

        return $this->jsonSuccess($followers, 'Takipçiler listesi');
    }

    /**
     * Kullanıcının Takip Ettikleri
     */
    public function getFollowing($userId)
    {
        $following = $this->db->select('u.id, u.username, u.full_name, u.avatar, u.bio, f.created_at as followed_at')
            ->from('follows f')
            ->join('users u', 'u.id = f.following_id')
            ->where('f.follower_id', (int)$userId)
            ->order_by('f.created_at', 'DESC')
            ->get()
            ->result_array();

        return $this->jsonSuccess($following, 'Takip edilenler listesi');
    }

    /**
     * Kullanıcının İzlediği Filmler
     */
    public function getWatchedMovies($userId)
    {
        $movies = $this->db->where('user_id', (int)$userId)
            ->where('media_type', 'movie')
            ->where('status', 'watched')
            ->order_by('updated_at', 'DESC')
            ->get('watchlist')
            ->result_array();

        return $this->jsonSuccess($movies, 'İzlenen filmler listesi');
    }

    /**
     * Kullanıcının İzlediği Diziler
     */
    public function getWatchedShows($userId)
    {
        $shows = $this->db->where('user_id', (int)$userId)
            ->where('media_type', 'tv')
            ->where('status', 'watched')
            ->order_by('updated_at', 'DESC')
            ->get('watchlist')
            ->result_array();

        return $this->jsonSuccess($shows, 'İzlenen diziler listesi');
    }

    /**
     * Kullanıcının İzleme Listesi
     */
    public function getWatchlist($userId)
    {
        $list = $this->db->where('user_id', (int)$userId)
            ->where('status', 'plan_to_watch')
            ->order_by('updated_at', 'DESC')
            ->get('watchlist')
            ->result_array();

        return $this->jsonSuccess($list, 'İzleme listesi');
    }
}

