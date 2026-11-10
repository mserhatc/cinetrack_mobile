<?php

namespace App\Controllers\Api;

use CodeIgniter\RESTful\ResourceController;
use CodeIgniter\HTTP\ResponseInterface;

class BaseApiController extends ResourceController
{
    protected static $jwtSecret = 'cinetrack_super_secure_secret_key_2026_flutter_ci4';

    protected function getJwtSecret(): string
    {
        return env('JWT_SECRET', self::$jwtSecret);
    }

    /**
     * Generate simple JWT-like bearer token
     */
    protected function generateToken(array $payload): string
    {
        $payload['exp'] = time() + (86400 * 30); // 30 days
        $encoded = base64_encode(json_encode($payload));
        $signature = hash_hmac('sha256', $encoded, $this->getJwtSecret());
        return $encoded . '.' . $signature;
    }

    /**
     * Validate token from Authorization header or return null
     */
    protected function getAuthUser(): ?array
    {
        // If AuthFilter already resolved the user, return it
        if (!empty($this->request->authUser)) {
            return $this->request->authUser;
        }

        $authHeader = $this->request->getHeaderLine('Authorization');
        if (empty($authHeader) || !preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
            return null;
        }

        $token = $matches[1];
        $parts = explode('.', $token);
        if (count($parts) !== 2) {
            return null;
        }

        [$encoded, $signature] = $parts;
        $expectedSignature = hash_hmac('sha256', $encoded, $this->getJwtSecret());
        if (!hash_equals($expectedSignature, $signature)) {
            return null;
        }

        $payload = json_decode(base64_decode($encoded), true);
        if (!$payload || !isset($payload['user_id']) || $payload['exp'] < time()) {
            return null;
        }

        $db = \Config\Database::connect();
        $user = $db->table('users')->where('id', $payload['user_id'])->get()->getRowArray();
        if ($user) {
            unset($user['password_hash']);
        }
        return $user ?: null;
    }

    protected function jsonSuccess($data = [], string $message = 'Success', int $statusCode = 200)
    {
        return $this->respond([
            'status'  => true,
            'message' => $message,
            'data'    => $data,
        ], $statusCode);
    }

    protected function jsonError(string $message = 'Error', int $statusCode = 400, $errors = null)
    {
        return $this->respond([
            'status'  => false,
            'message' => $message,
            'errors'  => $errors,
        ], $statusCode);
    }
}

