<?php
require_once __DIR__ . '/../db.php';

$usersCount = $conn->query("SELECT COUNT(*) as total FROM users WHERE role='nasabah'")->fetch_assoc()['total'] ?? 0;
$transCount = $conn->query("SELECT COUNT(*) as total FROM transactions")->fetch_assoc()['total'] ?? 0;
$pendingTrans = $conn->query("SELECT COUNT(*) as total FROM transactions WHERE status='menunggu'")->fetch_assoc()['total'] ?? 0;
$dropPointsCount = $conn->query("SELECT COUNT(*) as total FROM drop_points")->fetch_assoc()['total'] ?? 0;

echo json_encode([
    'success' => true,
    'data' => [
        'total_nasabah' => (int)$usersCount,
        'total_transaksi' => (int)$transCount,
        'transaksi_menunggu' => (int)$pendingTrans,
        'total_drop_points' => (int)$dropPointsCount,
    ]
]);
