<?php
$baseUrl = 'https://dreamland-single-counting.ngrok-free.dev/bank_sampah_api';

$endpoints = [
    'users/index.php',
    'transactions/index.php',
    'waste_categories/index.php',
    'drop_points/index.php',
];

foreach ($endpoints as $ep) {
    $ch = curl_init("$baseUrl/$ep");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Accept: application/json',
        'ngrok-skip-browser-warning: true'
    ]);
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    echo "[$ep] HTTP $code => " . substr($res, 0, 100) . "\n";
}
