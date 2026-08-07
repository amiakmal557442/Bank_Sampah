<?php
$data = ['status' => 'selesai', 'total_actual_points' => 8000, 'items' => [['id' => 'ITI-1234567890123000-1', 'waste_category_id' => 1, 'actual_weight' => 2.0]]];
$options = ['http' => ['header' => 'Content-Type: application/json', 'method' => 'PUT', 'content' => json_encode($data)]];
$context = stream_context_create($options);
$result = file_get_contents('http://localhost/bank_sampah_api/transactions/index.php?id=TRX-1786100158065', false, $context);
echo $result;
