<?php
$url = 'http://localhost/bank_sampah_api/transactions/index.php?nasabah_id=USR-001';
$result = file_get_contents($url);
echo "Result:\n$result\n";
