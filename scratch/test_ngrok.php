<?php
$ch = curl_init('https://dreamland-single-counting.ngrok-free.dev/bank_sampah_api/auth/login.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'ngrok-skip-browser-warning: true'
]);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode([
    'email' => 'admin@banksampah.com',
    'password' => '123456'
]));

$res = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response: $res\n";
