<?php

namespace App\Controllers\Api;

class TmdbController extends BaseApiController
{
    private string $baseUrl = 'https://api.themoviedb.org/3';
    private string $readAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxYTcyMmM5ZGExNWVmY2JlZjZjYWQwMjRmZDkzZGFlMiIsIm5iZiI6MTU1ODExNjYyOS4yODYsInN1YiI6IjVjZGVmOTE1MGUwYTI2NjZkN2NiZGYxNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.Ap8gi7SrPmY_sBvJHXnKmbBVAJPe7njl-Nm6Y3qCcKs';
    private string $apiKey = '1a722c9da15efcbef6cad024fd93dae2';

    private function fetchFromTmdb(string $endpoint, array $queryParams = []): ?array
    {
        $lang = $this->request->getGet('language') ?? 'tr-TR';
        $queryParams['language'] = $lang;

        $url = $this->baseUrl . $endpoint . '?' . http_build_query($queryParams);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_HTTPHEADER, [
            'Authorization: Bearer ' . $this->readAccessToken,
            'Content-Type: application/json;charset=utf-8',
            'Accept: application/json',
        ]);

        $response = curl_exec($ch);
        $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $err = curl_error($ch);
        curl_close($ch);

        if ($err || $httpCode >= 400 || !$response) {
            // Fallback with api_key query param if bearer token has any network/header quirk
            $fallbackUrl = $this->baseUrl . $endpoint . '?' . http_build_query(array_merge($queryParams, ['api_key' => $this->apiKey]));
            $ch = curl_init($fallbackUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 15);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            $response = curl_exec($ch);
            curl_close($ch);
        }

        return json_decode($response, true);
    }

    /**
     * Trend içerikler (Filmler ve Diziler)
     */
    public function trending()
    {
        $timeWindow = $this->request->getGet('time_window') ?? 'week';
        $data = $this->fetchFromTmdb("/trending/all/{$timeWindow}");
        return $this->respond($data ?: ['results' => []]);
    }

    /**
     * Film veya Dizi arama (Yeni post paylaşırken veya keşfette)
     */
    public function search()
    {
        $query = $this->request->getGet('query');
        if (empty($query)) {
            return $this->respond(['results' => []]);
        }

        $page = (int)($this->request->getGet('page') ?? 1);
        $data = $this->fetchFromTmdb('/search/multi', ['query' => $query, 'page' => $page]);

        // Sadece movie ve tv olanları filtreleyelim
        if (isset($data['results']) && is_array($data['results'])) {
            $data['results'] = array_values(array_filter($data['results'], function($item) {
                return isset($item['media_type']) && in_array($item['media_type'], ['movie', 'tv']);
            }));
        }

        return $this->respond($data ?: ['results' => []]);
    }

    /**
     * Popüler Filmler
     */
    public function popularMovies()
    {
        $page = (int)($this->request->getGet('page') ?? 1);
        $data = $this->fetchFromTmdb('/movie/popular', ['page' => $page]);
        return $this->respond($data ?: ['results' => []]);
    }

    /**
     * Popüler Diziler
     */
    public function popularTv()
    {
        $page = (int)($this->request->getGet('page') ?? 1);
        $data = $this->fetchFromTmdb('/tv/popular', ['page' => $page]);
        return $this->respond($data ?: ['results' => []]);
    }

    /**
     * Film Detayı
     */
    public function movieDetails($id)
    {
        $data = $this->fetchFromTmdb("/movie/{$id}", [
            'append_to_response' => 'credits,recommendations,videos',
        ]);

        if (!$data || isset($data['success']) && $data['success'] === false) {
            return $this->jsonError('Film bulunamadı', 404);
        }

        // Kullanıcının bu filme verdiği puan ve watchlist durumu var mı?
        $currentUser = $this->getAuthUser();
        $userStatus = null;
        if ($currentUser) {
            $db = \Config\Database::connect();
            $watch = $db->table('watchlist')
                ->where('user_id', $currentUser['id'])
                ->where('tmdb_id', $id)
                ->where('media_type', 'movie')
                ->get()
                ->getRowArray();
            $userStatus = $watch;
        }

        $data['user_status'] = $userStatus;
        return $this->respond($data);
    }

    /**
     * Dizi Detayı
     */
    public function tvDetails($id)
    {
        $data = $this->fetchFromTmdb("/tv/{$id}", [
            'append_to_response' => 'credits,recommendations,videos',
        ]);

        if (!$data || isset($data['success']) && $data['success'] === false) {
            return $this->jsonError('Dizi bulunamadı', 404);
        }

        $currentUser = $this->getAuthUser();
        $userStatus = null;
        if ($currentUser) {
            $db = \Config\Database::connect();
            $watch = $db->table('watchlist')
                ->where('user_id', $currentUser['id'])
                ->where('tmdb_id', $id)
                ->where('media_type', 'tv')
                ->get()
                ->getRowArray();
            $userStatus = $watch;
        }

        $data['user_status'] = $userStatus;
        return $this->respond($data);
    }
}

