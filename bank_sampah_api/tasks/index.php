<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $petugasId = $_GET['petugas_id'] ?? null;
    $status = $_GET['status'] ?? 'dikonfirmasi';

    if ($petugasId) {
        $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address, dp.name as drop_point_name, dp.address as drop_point_address FROM transactions t JOIN users u ON t.nasabah_id = u.id LEFT JOIN drop_points dp ON t.drop_point_id = dp.id WHERE t.status = ? AND (t.petugas_id = ? OR t.petugas_id IS NULL OR t.petugas_id = '') ORDER BY t.created_at DESC");
        $stmt->bind_param("ss", $status, $petugasId);
    } else {
        $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address, dp.name as drop_point_name, dp.address as drop_point_address FROM transactions t JOIN users u ON t.nasabah_id = u.id LEFT JOIN drop_points dp ON t.drop_point_id = dp.id WHERE t.status = ? ORDER BY t.created_at DESC");
        $stmt->bind_param("s", $status);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $tasks = [];
    while ($row = $result->fetch_assoc()) {
        $row['total_est_points'] = (int) ($row['total_est_points'] ?? 0);
        $row['total_actual_points'] = (int) ($row['total_actual_points'] ?? 0);
        $tasks[] = $row;
    }

    echo json_encode(['success' => true, 'data' => $tasks]);
    exit();
}

if ($method === 'PUT') {
    $id = $_GET['id'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);
    if ($id && isset($data['status'])) {
        $stmt = $conn->prepare("UPDATE transactions SET status = ? WHERE id = ?");
        $stmt->bind_param("ss", $data['status'], $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Status tugas diperbarui']);
    }
    exit();
}
