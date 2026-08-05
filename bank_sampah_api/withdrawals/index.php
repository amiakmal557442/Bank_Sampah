<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $sql = "SELECT w.*, u.full_name as nasabah_name FROM withdrawals w JOIN users u ON w.nasabah_id = u.id ORDER BY w.created_at DESC";
    $result = $conn->query($sql);
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $row['points_deducted'] = (int)$row['points_deducted'];
        $data[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = 'WD-' . rand(1000, 9999);
    $nasabahId = $data['nasabah_id'] ?? '';
    $points = (int)($data['points_deducted'] ?? 0);
    $methodName = $data['method'] ?? 'Transfer Bank';
    $details = $data['account_details'] ?? '';

    $stmt = $conn->prepare("INSERT INTO withdrawals (id, nasabah_id, points_deducted, method, account_details) VALUES (?, ?, ?, ?, ?)");
    $stmt->bind_param("ssiss", $id, $nasabahId, $points, $methodName, $details);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Penarikan berhasil diajukan']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal mengajukan penarikan']);
    }
    exit();
}
