<?php

namespace App\Filters;

use CodeIgniter\Filters\FilterInterface;
use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;

class ApiKeyFilter implements FilterInterface
{
    /**
     * Do normal validations before controller runs
     */
    public function before(RequestInterface $request, $arguments = null)
    {
        // Allow CORS preflight requests
        if (strtoupper($request->getMethod()) === 'OPTIONS') {
            return;
        }

        $expectedKey = env('APP_API_KEY', 'cinetrack_sec_api_key_2026_x89a');

        // Look for X-API-KEY header (case-insensitive check)
        $apiKey = $request->getHeaderLine('X-API-KEY');
        if (empty($apiKey)) {
            $apiKey = $request->getHeaderLine('x-api-key');
        }

        if (empty($apiKey) || !hash_equals($expectedKey, trim($apiKey))) {
            $response = service('response');
            return $response->setStatusCode(401)->setJSON([
                'status'  => false,
                'message' => 'Geçersiz veya eksik API Anahtarı (X-API-KEY).',
                'errors'  => [
                    'apiKey' => 'İstek başlığında geçerli bir X-API-KEY bulunamadı.'
                ]
            ]);
        }
    }

    public function after(RequestInterface $request, ResponseInterface $response, $arguments = null)
    {
        // No action needed after controller execution
    }
}

