<?php
$url = 'http://localhost/bank_sampah_api/transactions/index.php';
$result = file_get_contents($url);
echo "Result:\n$result\n";
