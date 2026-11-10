<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use Config\Database;

class AuthFilter implements FilterInterface
{
    /**
     * Authenticate requests with Bearer JWT token
     */
    public function before(RequestInterface $request, $arguments = null)
    {
        // Allow CORS preflight requests
        if (strtoupper($request->getMethod()) === 'OPTIONS') {
            return;
        }

        $authHeader = $request->getHeaderLine('Authorization');
        if (empty($authHeader) || !preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Oturum doğrulaması başarısız. Lütfen geçerli bir Bearer token sağlayın.',
                'errors'  => [
                    'authorization' => 'Authorization: Bearer <token> başlığı eksik veya biçimi geçersiz.'
                ]
            ]);
        }

        $token = $matches[1];
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Geçersiz token formatı.',
                'errors'  => ['token' => 'Token yapısı bozuk.']
            ]);
        }

        [$encoded, $signature] = $parts;
        $jwtSecret = env('JWT_SECRET', 'cinetrack_super_secure_secret_key_2026_flutter_ci4');
        $expectedSignature = hash_hmac('sha256', $encoded, $jwtSecret);

        if (!hash_equals($expectedSignature, $signature)) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Token imzası geçersiz.',
                'errors'  => ['token' => 'Token imzası doğrulanamadı.']
            ]);
        }

        $payload = json_decode(base64_decode($encoded), true);
        if (!$payload || !isset($payload['user_id']) || !isset($payload['exp']) || $payload['exp'] < time()) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Token süresi dolmuş veya geçersiz.',
                'errors'  => ['token' => 'Lütfen tekrar giriş yapın.']
            ]);
        }

        $db = Database::connect();
        $user = $db->table('users')->where('id', $payload['user_id'])->get()->getRowArray();
        if (!$user) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Token ile ilişkili kullanıcı bulunamadı.',
                'errors'  => ['user' => 'Kullanıcı hesabı mevcut değil.']
            ]);
        }

        unset($user['password_hash']);

        // Attach validated user to the request object for controllers to use
        $request->authUser = $user;
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // No action needed after controller execution
    }
}

