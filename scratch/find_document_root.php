<?php
$ch = curl_init('http://localhost/bank_sampah_api/test_info.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$res = curl_exec($ch);
curl_close($ch);
echo "Result: $res\n";
