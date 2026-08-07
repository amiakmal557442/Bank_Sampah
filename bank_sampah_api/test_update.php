<?php
$url = 'http://localhost/bank_sampah_api/transactions/index.php?id=TRX-TEST-001';
$data = [
    'status' => 'selesai',
    'total_actual_points' => 7500,
    'items' => [
        [
            'id' => 'ITI-' . microtime(true) * 10000,
            'waste_category_id' => 1,
            'estimated_weight' => 0,
            'actual_weight' => 2.5,
            'final_points' => 5000
        ],
        [
            'id' => 'ITI-' . (microtime(true) * 10000 + 1),
            'waste_category_id' => 2,
            'estimated_weight' => 0,
            'actual_weight' => 1.5,
            'final_points' => 2500
        ]
    ]
];

$options = [
    'http' => [
        'header'  => "Content-type: application/json\r\n",
        'method'  => 'PUT',
        'content' => json_encode($data)
    ]
];
$context  = stream_context_create($options);
$result = file_get_contents($url, false, $context);
echo "Result:\n$result\n";
