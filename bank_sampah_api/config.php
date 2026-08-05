<?php
require_once __DIR__ . '/db.php';

echo json_encode([
    'success' => true,
    'message' => 'API Bank Sampah Aktif & Terhubung ke MySQL XAMPP',
    'database' => $db
]);
