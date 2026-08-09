<?php
$ch = curl_init('http://localhost/bank_sampah_api/users/index.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 3);
$res = curl_exec($ch);
$err = curl_error($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Apache HTTP Code: $httpCode\n";
echo "Error: $err\n";
