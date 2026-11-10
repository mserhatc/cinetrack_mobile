<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Watchlist extends BaseApiController
{
    /**
     * İzleme Listesi Durumu Güncelle (plan_to_watch / watched / remove)
     */
    public function setStatus()
    {
        $user = $this->requireAuth();
        $json = $this->getRequestJson();

        $tmdbId     = (int)($json['tmdb_id'] ?? 0);
        $mediaType  = in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie';
        $status     = $json['status'] ?? 'plan_to_watch';
        $title      = trim($json['title'] ?? '');
        $posterPath = trim($json['poster_path'] ?? '');
        $rating     = isset($json['rating']) && $json['rating'] !== '' ? (float)$json['rating'] : null;

        if (!$tmdbId) {
            return $this->jsonError('TMDB ID zorunludur.', 422);
        }

        $existing = $this->db->get_where('watchlist', [
            'user_id'    => $user['id'],
            'tmdb_id'    => $tmdbId,
            'media_type' => $mediaType,
        ])->row_array();

        if ($status === 'remove') {
            if ($existing) {
                $this->db->where('id', $existing['id'])->delete('watchlist');
            }
            return $this->jsonSuccess(['status' => null], 'Listeden kaldırıldı');
        }

        if ($existing) {
            $updateData = ['status' => $status];
            if ($rating !== null) $updateData['rating'] = $rating;
            if ($posterPath)      $updateData['poster_path'] = $posterPath;
            if ($title)           $updateData['title'] = $title;
            $this->db->where('id', $existing['id'])->update('watchlist', $updateData);
        } else {
            $this->db->insert('watchlist', [
                'user_id'     => $user['id'],
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'status'      => $status,
                'rating'      => $rating,
            ]);
        }

        $item = $this->db->get_where('watchlist', [
            'user_id'    => $user['id'],
            'tmdb_id'    => $tmdbId,
            'media_type' => $mediaType,
        ])->row_array();

        return $this->jsonSuccess($item, 'Durum güncellendi');
    }

    /**
     * Film veya diziye puan ver ve yorum yap
     */
    public function rateAndReview()
    {
        $user = $this->requireAuth();
        $json = $this->getRequestJson();

        $tmdbId     = (int)($json['tmdb_id'] ?? 0);
        $mediaType  = in_array($json['media_type'] ?? '', ['movie', 'tv']) ? $json['media_type'] : 'movie';
        $rating     = (float)($json['rating'] ?? 0);
        $reviewText = trim($json['review_text'] ?? '');
        $title      = trim($json['title'] ?? '');
        $posterPath = trim($json['poster_path'] ?? '');

        if (!$tmdbId || $rating <= 0 || $rating > 10) {
            return $this->jsonError('Geçerli bir TMDB ID ve 1-10 arası puan gereklidir.', 422);
        }

        // 1. media_reviews tablosuna ekle / güncelle
        $existingReview = $this->db->get_where('media_reviews', [
            'user_id'    => $user['id'],
            'tmdb_id'    => $tmdbId,
            'media_type' => $mediaType,
        ])->row_array();

        if ($existingReview) {
            $this->db->where('id', $existingReview['id'])->update('media_reviews', [
                'rating'      => $rating,
                'review_text' => $reviewText,
            ]);
        } else {
            $this->db->insert('media_reviews', [
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
        $existingWatch = $this->db->get_where('watchlist', [
            'user_id'    => $user['id'],
            'tmdb_id'    => $tmdbId,
            'media_type' => $mediaType,
        ])->row_array();

        if ($existingWatch) {
            $this->db->where('id', $existingWatch['id'])->update('watchlist', [
                'status' => 'watched',
                'rating' => $rating,
            ]);
        } else {
            $this->db->insert('watchlist', [
                'user_id'     => $user['id'],
                'tmdb_id'     => $tmdbId,
                'media_type'  => $mediaType,
                'title'       => $title,
                'poster_path' => $posterPath,
                'status'      => 'watched',
                'rating'      => $rating,
            ]);
        }

        // 3. Eğer yorum varsa, posts akışına da ekle
        if (!empty($reviewText)) {
            $this->db->insert('posts', [
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
     * Topluluk yorumlarını getir
     */
    public function getReviews($tmdbId, $mediaType = 'movie')
    {
        $reviews = $this->db->select('r.*, u.username, u.full_name, u.avatar')
            ->from('media_reviews r')
            ->join('users u', 'u.id = r.user_id')
            ->where('r.tmdb_id', (int)$tmdbId)
            ->where('r.media_type', $mediaType)
            ->order_by('r.created_at', 'DESC')
            ->get()
            ->result_array();

        return $this->jsonSuccess($reviews, 'Yorumlar getirildi');
    }
}

