<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class Tmdb extends BaseApiController
{
    private $baseUrl = 'https://api.themoviedb.org/3';
    private $readAccessToken = 'eyJhbGciOiJIUzI1NiJ9.eyJhdWQiOiIxYTcyMmM5ZGExNWVmY2JlZjZjYWQwMjRmZDkzZGFlMiIsIm5iZiI6MTU1ODExNjYyOS4yODYsInN1YiI6IjVjZGVmOTE1MGUwYTI2NjZkN2NiZGYxNCIsInNjb3BlcyI6WyJhcGlfcmVhZCJdLCJ2ZXJzaW9uIjoxfQ.Ap8gi7SrPmY_sBvJHXnKmbBVAJPe7njl-Nm6Y3qCcKs';
    private $tmdbApiKey = '1a722c9da15efcbef6cad024fd93dae2';

    private function fetchFromTmdb($endpoint, $queryParams = [])
    {
        $lang = $this->input->get('language') ?: 'tr-TR';
        $queryParams['language'] = $lang;

        $url = $this->baseUrl . $endpoint . '?' . http_build_query($queryParams);

        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_TIMEOUT, 15);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) CineTrackApp/1.0');
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
            $fallbackUrl = $this->baseUrl . $endpoint . '?' . http_build_query(array_merge($queryParams, ['api_key' => $this->tmdbApiKey]));
            $ch = curl_init($fallbackUrl);
            curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
            curl_setopt($ch, CURLOPT_TIMEOUT, 15);
            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
            curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) CineTrackApp/1.0');
            $response = curl_exec($ch);
            curl_close($ch);
        }

        return json_decode($response, true);
    }

    private function outputTmdbJson($data)
    {
        $payload = is_array($data) ? $data : ['results' => []];
        $payload['status'] = true;
        $payload['data'] = $payload;

        $this->output
            ->set_status_header(200)
            ->set_content_type('application/json', 'utf-8')
            ->set_output(json_encode($payload))
            ->_display();
        exit();
    }

    public function trending()
    {
        $timeWindow = $this->input->get('time_window') ?: 'week';
        $data = $this->fetchFromTmdb("/trending/all/{$timeWindow}");
        return $this->outputTmdbJson($data ?: ['results' => []]);
    }

    public function search()
    {
        $query = $this->input->get('query');
        if (empty($query)) {
            return $this->outputTmdbJson(['results' => []]);
        }

        $page = (int)($this->input->get('page') ?: 1);
        $data = $this->fetchFromTmdb('/search/multi', ['query' => $query, 'page' => $page]);

        if (isset($data['results']) && is_array($data['results'])) {
            $data['results'] = array_values(array_filter($data['results'], function($item) {
                return isset($item['media_type']) && in_array($item['media_type'], ['movie', 'tv']);
            }));
        }

        return $this->outputTmdbJson($data ?: ['results' => []]);
    }

    public function popularMovies()
    {
        $page = (int)($this->input->get('page') ?: 1);
        $data = $this->fetchFromTmdb('/movie/popular', ['page' => $page]);
        return $this->outputTmdbJson($data ?: ['results' => []]);
    }

    public function popularTv()
    {
        $page = (int)($this->input->get('page') ?: 1);
        $data = $this->fetchFromTmdb('/tv/popular', ['page' => $page]);
        return $this->outputTmdbJson($data ?: ['results' => []]);
    }

    public function movieDetails($id)
    {
        $data = $this->fetchFromTmdb("/movie/{$id}", [
            'append_to_response' => 'credits,recommendations,videos',
        ]);

        if (!$data || (isset($data['success']) && $data['success'] === false)) {
            return $this->jsonError('Film bulunamadı', 404);
        }

        $currentUser = $this->getAuthUser();
        $userStatus = null;
        if ($currentUser) {
            $watch = $this->db->get_where('watchlist', [
                'user_id'    => $currentUser['id'],
                'tmdb_id'    => (int)$id,
                'media_type' => 'movie',
            ])->row_array();
            $userStatus = $watch;
        }

        $data['user_status'] = $userStatus;
        return $this->output
            ->set_status_header(200)
            ->set_content_type('application/json', 'utf-8')
            ->set_output(json_encode($data))
            ->_display();
        exit();
    }

    public function tvDetails($id)
    {
        $data = $this->fetchFromTmdb("/tv/{$id}", [
            'append_to_response' => 'credits,recommendations,videos',
        ]);

        if (!$data || (isset($data['success']) && $data['success'] === false)) {
            return $this->jsonError('Dizi bulunamadı', 404);
        }

        $currentUser = $this->getAuthUser();
        $userStatus = null;
        if ($currentUser) {
            $watch = $this->db->get_where('watchlist', [
                'user_id'    => $currentUser['id'],
                'tmdb_id'    => (int)$id,
                'media_type' => 'tv',
            ])->row_array();
            $userStatus = $watch;
        }

        $data['user_status'] = $userStatus;
        return $this->output
            ->set_status_header(200)
            ->set_content_type('application/json', 'utf-8')
            ->set_output(json_encode($data))
            ->_display();
        exit();
    }
}
