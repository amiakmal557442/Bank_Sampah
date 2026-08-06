<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $petugasId = $_GET['petugas_id'] ?? null;
    $statusParam = $_GET['status'] ?? 'dikonfirmasi';

    if ($petugasId) {
        $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address, dp.name as drop_point_name, dp.address as drop_point_address, GROUP_CONCAT(DISTINCT wc.name SEPARATOR ', ') as jenis_sampah FROM transactions t JOIN users u ON t.nasabah_id = u.id LEFT JOIN drop_points dp ON t.drop_point_id = dp.id LEFT JOIN transaction_items ti ON t.id = ti.transaction_id LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id WHERE FIND_IN_SET(t.status, ?) > 0 AND (t.petugas_id = ? OR t.petugas_id IS NULL OR t.petugas_id = '') GROUP BY t.id ORDER BY t.created_at DESC");
        $stmt->bind_param("ss", $statusParam, $petugasId);
    } else {
        $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address, dp.name as drop_point_name, dp.address as drop_point_address, GROUP_CONCAT(DISTINCT wc.name SEPARATOR ', ') as jenis_sampah FROM transactions t JOIN users u ON t.nasabah_id = u.id LEFT JOIN drop_points dp ON t.drop_point_id = dp.id LEFT JOIN transaction_items ti ON t.id = ti.transaction_id LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id WHERE FIND_IN_SET(t.status, ?) > 0 GROUP BY t.id ORDER BY t.created_at DESC");
        $stmt->bind_param("s", $statusParam);
    }

    $stmt->execute();
    $result = $stmt->get_result();

    $tasks = [];
    while ($row = $result->fetch_assoc()) {
        $row['total_est_points'] = (int) ($row['total_est_points'] ?? 0);
        $row['total_actual_points'] = (int) ($row['total_actual_points'] ?? 0);
        
        $txId = $row['id'];
        $itemStmt = $conn->prepare("SELECT ti.*, wc.name as category_name, wc.point_per_kg FROM transaction_items ti JOIN waste_categories wc ON ti.waste_category_id = wc.id WHERE ti.transaction_id = ?");
        $itemStmt->bind_param("s", $txId);
        $itemStmt->execute();
        $itemResult = $itemStmt->get_result();
        $items = [];
        $catNames = [];
        while ($itemRow = $itemResult->fetch_assoc()) {
            $items[] = $itemRow;
            if (!empty($itemRow['category_name']) && !in_array($itemRow['category_name'], $catNames)) {
                $catNames[] = $itemRow['category_name'];
            }
        }
        $row['items'] = $items;
        if (!empty($catNames)) {
            $row['jenis_sampah'] = implode(', ', $catNames);
        } else if (empty($row['jenis_sampah'])) {
            $row['jenis_sampah'] = 'Belum ditentukan';
        }

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
