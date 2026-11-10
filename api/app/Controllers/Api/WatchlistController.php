<?php

namespace App\Controllers\Api;

class WatchlistController extends BaseApiController
{
    /**
     * İzleme listesine ekle / kaldır / izlendi yap
     */
    public function setStatus()
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Bu işlem için giriş yapmalısınız.', 401);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();

        $tmdbId = (int)($json['tmdb_id'] ?? 0);
        $mediaType = in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie';
        $status = $json['status'] ?? 'plan_to_watch'; // 'plan_to_watch', 'watched', 'remove'
        $title = trim($json['title'] ?? '');
        $posterPath = trim($json['poster_path'] ?? '');
        $rating = isset($json['rating']) && $json['rating'] !== '' ? (float)$json['rating'] : null;

        if (!$tmdbId) {
            return $this->jsonError('TMDB ID zorunludur.', 422);
        }

        $db = \Config\Database::connect();
        $table = $db->table('watchlist');

        $existing = $table->where('user_id', $user['id'])
            ->where('tmdb_id', $tmdbId)
            ->where('media_type', $mediaType)
            ->get()
            ->getRowArray();

        if ($status === 'remove') {
            if ($existing) {
                $table->where('id', $existing['id'])->delete();
            }
            return $this->jsonSuccess(['status' => null], 'Listeden kaldırıldı');
        }

        if ($existing) {
            $updateData = ['status' => $status];
            if ($rating !== null) {
                $updateData['rating'] = $rating;
            }
            if ($posterPath) {
                $updateData['poster_path'] = $posterPath;
            }
            if ($title) {
                $updateData['title'] = $title;
            }
            $table->where('id', $existing['id'])->update($updateData);
        } else {
            $table->insert([
                'user_id'     => $user['id'],
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'status'      => $status,
                'rating'      => $rating,
            ]);
        }

        $item = $table->where('user_id', $user['id'])
            ->where('tmdb_id', $tmdbId)
            ->where('media_type', $mediaType)
            ->get()
            ->getRowArray();

        return $this->jsonSuccess($item, 'Durum güncellendi');
    }

    /**
     * Film veya diziye puan ver ve yorum yap
     */
    public function rateAndReview()
    {
        $user = $this->getAuthUser();
        if (!$user) {
            return $this->jsonError('Puan vermek için giriş yapmalısınız.', 401);
        }

        $json = $this->request->getJSON(true) ?? $this->request->getPost();

        $tmdbId = (int)($json['tmdb_id'] ?? 0);
        $mediaType = in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie';
        $rating = (float)($json['rating'] ?? 0);
        $reviewText = trim($json['review_text'] ?? '');
        $title = trim($json['title'] ?? '');
        $posterPath = trim($json['poster_path'] ?? '');

        if (!$tmdbId || $rating <= 0 || $rating > 10) {
            return $this->jsonError('Geçerli bir TMDB ID ve 1-10 arası puan gereklidir.', 422);
        }

        $db = \Config\Database::connect();

        // 1. media_reviews tablosuna ekle / güncelle
        $existingReview = $db->table('media_reviews')
            ->where('user_id', $user['id'])
            ->where('tmdb_id', $tmdbId)
            ->where('media_type', $mediaType)
            ->get()
            ->getRowArray();

        if ($existingReview) {
            $db->table('media_reviews')->where('id', $existingReview['id'])->update([
                'rating'      => $rating,
                'review_text' => $reviewText,
            ]);
        } else {
            $db->table('media_reviews')->insert([
                'user_id'     => $user['id'],
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'rating'      => $rating,
                'review_text' => $reviewText,
            ]);
        }

        // 2. Watchlist'te de 'watched' ve rating olarak güncelle
        $existingWatch = $db->table('watchlist')
            ->where('user_id', $user['id'])
            ->where('tmdb_id', $tmdbId)
            ->where('media_type', $mediaType)
            ->get()
            ->getRowArray();

        if ($existingWatch) {
            $db->table('watchlist')->where('id', $existingWatch['id'])->update([
                'status' => 'watched',
                'rating' => $rating,
            ]);
        } else {
            $db->table('watchlist')->insert([
                'user_id'     => $user['id'],
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'status'      => 'watched',
                'rating'      => $rating,
            ]);
        }

        // 3. Eğer yorum varsa, otomatik olarak feed (posts) akışına da review postu ekleyelim!
        if (!empty($reviewText)) {
            $db->table('posts')->insert([
                'user_id'     => $user['id'],
                'post_type'   => 'review',
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'content'     => $reviewText,
                'rating'      => $rating,
            ]);
        }

        return $this->jsonSuccess([
            'rating'      => $rating,
            'review_text' => $reviewText,
        ], 'Puan ve yorum kaydedildi');
    }

    /**
     * Bir yapım için topluluk yorumlarını getir
     */
    public function getReviews($tmdbId, $mediaType = 'movie')
    {
        $db = \Config\Database::connect();
        $reviews = $db->table('media_reviews r')
            ->select('r.*, u.username, u.full_name, u.avatar')
            ->join('users u', 'u.id = r.user_id')
            ->where('r.tmdb_id', (int)$tmdbId)
            ->where('r.media_type', $mediaType)
            ->orderBy('r.created_at', 'DESC')
            ->get()
            ->getResultArray();

        return $this->jsonSuccess($reviews, 'Yorumlar getirildi');
    }
}

