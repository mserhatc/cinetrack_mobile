<?php
defined('BASEPATH') OR exit('No direct script access allowed');

class BaseApiController extends CI_Controller
{
    protected static $jwtSecret = 'cinetrack_super_secure_secret_key_2026_flutter_ci4';
    protected static $apiKey = 'cinetrack_sec_api_key_2026_x89a';

    public function __construct()
    {
        parent::__construct();
        $this->load->database();

        // 1. CORS Başlıkları
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Headers: Origin, X-Requested-With, Content-Type, Accept, Authorization, X-API-KEY, x-api-key');
        header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');

        // Preflight OPTIONS isteğini 200 OK ile hemen sonlandır
        if (strtoupper($this->input->server('REQUEST_METHOD')) === 'OPTIONS') {
            http_response_code(200);
            exit();
        }

        // 2. Global X-API-KEY Doğrulaması
        $this->validateApiKey();
    }

    /**
     * X-API-KEY doğrulaması
     */
    protected function validateApiKey()
    {
        $apiKey = $this->input->get_request_header('X-API-KEY', TRUE);
        if (empty($apiKey)) {
            $apiKey = $this->input->get_request_header('x-api-key', TRUE);
        }
        if (empty($apiKey) && isset($_SERVER['HTTP_X_API_KEY'])) {
            $apiKey = $_SERVER['HTTP_X_API_KEY'];
        }
        if (empty($apiKey) && isset($_SERVER['X_API_KEY'])) {
            $apiKey = $_SERVER['X_API_KEY'];
        }
        if (empty($apiKey)) {
            $apiKey = $this->input->get('api_key');
        }

        if (empty($apiKey) || !hash_equals(self::$apiKey, trim($apiKey))) {
            $this->jsonError('Geçersiz veya eksik API Anahtarı (X-API-KEY).', 401, [
                'apiKey' => 'İstek başlığında geçerli bir X-API-KEY bulunamadı.'
            ]);
        }
    }

    /**
     * JSON gövdesini dizi olarak okuma
     */
    protected function getRequestJson(): array
    {
        $raw = file_get_contents('php://input');
        $json = json_decode($raw, true);
        if (is_array($json)) {
            return $json;
        }
        $post = $this->input->post();
        return is_array($post) ? $post : [];
    }

    /**
     * Bearer token üzerinden kullanıcıyı çözme
     */
    protected function getAuthUser(): ?array
    {
        $authHeader = $this->input->get_request_header('Authorization', TRUE);
        if (empty($authHeader) || !preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
            return null;
        }

        $token = $matches[1];
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            return null;
        }

        [$encoded, $signature] = $parts;
        $expectedSignature = hash_hmac('sha256', $encoded, self::$jwtSecret);
        if (!hash_equals($expectedSignature, $signature)) {
            return null;
        }

        $payload = json_decode(base64_decode($encoded), true);
        if (!$payload || !isset($payload['user_id']) || !isset($payload['exp']) || $payload['exp'] < time()) {
            return null;
        }

        $user = $this->db->get_where('users', ['id' => $payload['user_id']])->row_array();
        if ($user) {
            unset($user['password_hash']);
            return $user;
        }
        return null;
    }

    /**
     * Oturum zorunlu kılma (Korumalı Rotalar)
     */
    protected function requireAuth(): array
    {
        $user = $this->getAuthUser();
        if (!$user) {
            $this->jsonError('Oturum doğrulaması başarısız. Lütfen geçerli bir Bearer token sağlayın.', 401, [
                'authorization' => 'Authorization: Bearer <token> başlığı eksik veya biçimi geçersiz.'
            ]);
        }
        return $user;
    }

    /**
     * HMAC-SHA256 imzalı JWT-benzeri token üretme
     */
    protected function generateToken(array $payload): string
    {
        $payload['exp'] = time() + (86400 * 30); // 30 gün geçerli
        $encoded = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $encoded, self::$jwtSecret);
        return $encoded . '.' . $signature;
    }

    /**
     * Standart JSON Başarılı Yanıtı
     */
    protected function jsonSuccess($data = [], string $message = 'Success', int $statusCode = 200)
    {
        $this->output
            ->set_status_header($statusCode)
            ->set_content_type('application/json', 'utf-8')
            ->set_output(json_encode([
                'status'  => true,
                'message' => $message,
                'data'    => $data,
            ]))
            ->_display();
        exit();
    }

    /**
     * Standart JSON Hata Yanıtı
     */
    protected function jsonError(string $message = 'Error', int $statusCode = 400, $errors = null)
    {
        $this->output
            ->set_status_header($statusCode)
            ->set_content_type('application/json', 'utf-8')
            ->set_output(json_encode([
                'status'  => false,
                'message' => $message,
                'errors'  => $errors,
            ]))
            ->_display();
        exit();
    }
}

