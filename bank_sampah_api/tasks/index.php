<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $petugasId = $_GET['petugas_id'] ?? null;
    $status = $_GET['status'] ?? 'menunggu';

    $sql = "SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address FROM transactions t JOIN users u ON t.nasabah_id = u.id WHERE t.status = ?";
    if ($petugasId) {
        $sql .= " AND (t.petugas_id = '$petugasId' OR t.petugas_id IS NULL)";
    }

    $result = $conn->query($sql);
    $tasks = [];
    while ($row = $result->fetch_assoc()) {
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
