<?php

class JwtHelper {
    private static $secret_key = 'bank_sampah_secret_key_2026';

    private static function base64UrlEncode($text) {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($text));
    }

    public static function generateToken($payload) {
        $header = json_encode(['typ' => 'JWT', 'alg' => 'HS256']);

        $base64UrlHeader = self::base64UrlEncode($header);
        $base64UrlPayload = self::base64UrlEncode(json_encode($payload));

        $signature = hash_hmac('sha256', $base64UrlHeader . "." . $base64UrlPayload, self::$secret_key, true);
        $base64UrlSignature = self::base64UrlEncode($signature);

        return $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;
    }

    public static function validateToken($token) {
        $tokenParts = explode('.', $token);

        if (count($tokenParts) != 3) {
            return false;
        }

        $header = $tokenParts[0];
        $payload = $tokenParts[1];
        $signature_provided = $tokenParts[2];

        $signature = hash_hmac('sha256', $header . "." . $payload, self::$secret_key, true);
        $base64UrlSignature = self::base64UrlEncode($signature);

        if ($base64UrlSignature === $signature_provided) {
            $decoded_payload = json_decode(base64_decode(str_replace(['-', '_'], ['+', '/'], $payload)), true);

            if (isset($decoded_payload['exp']) && $decoded_payload['exp'] < time()) {
                return false;
            }
            return $decoded_payload;
        }

        return false;
    }

    public static function getBearerToken() {
        $headers = null;
        if (isset($_SERVER['Authorization'])) {
            $headers = trim($_SERVER["Authorization"]);
        } else if (isset($_SERVER['HTTP_AUTHORIZATION'])) {
            $headers = trim($_SERVER["HTTP_AUTHORIZATION"]);
        } elseif (function_exists('apache_request_headers')) {
            $requestHeaders = apache_request_headers();
            $requestHeaders = array_combine(array_map('ucwords', array_keys($requestHeaders)), array_values($requestHeaders));
            if (isset($requestHeaders['Authorization'])) {
                $headers = trim($requestHeaders['Authorization']);
            }
        }

        if (!empty($headers)) {
            if (preg_match('/Bearer\s(\S+)/', $headers, $matches)) {
                return $matches[1];
            }
        }
        return null;
    }
}
?>
