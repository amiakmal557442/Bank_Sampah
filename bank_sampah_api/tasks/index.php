<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $petugasId = $_GET['petugas_id'] ?? null;
    $statusParam = $_GET['status'] ?? 'dikonfirmasi';
    $typeParam = $_GET['type'] ?? null;

    $whereClauses = ["FIND_IN_SET(t.status, ?) > 0"];
    $types = "s";
    $params = [$statusParam];

    if ($petugasId) {
        $whereClauses[] = "(t.petugas_id = ? OR t.petugas_id IS NULL OR t.petugas_id = '')";
        $types .= "s";
        $params[] = $petugasId;
    }

    if ($typeParam) {
        $whereClauses[] = "t.type = ?";
        $types .= "s";
        $params[] = $typeParam;
    }

    $whereSql = implode(" AND ", $whereClauses);

    $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name, u.phone_number, u.address as nasabah_address, dp.name as drop_point_name, dp.address as drop_point_address, GROUP_CONCAT(DISTINCT wc.name SEPARATOR ', ') as jenis_sampah FROM transactions t JOIN users u ON t.nasabah_id = u.id LEFT JOIN drop_points dp ON t.drop_point_id = dp.id LEFT JOIN transaction_items ti ON t.id = ti.transaction_id LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id WHERE $whereSql GROUP BY t.id ORDER BY t.created_at DESC");
    $stmt->bind_param($types, ...$params);

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
    $action = $_GET['action'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);

    if ($action === 'claim' && $id && isset($data['petugas_id'])) {
        $petugasId = $data['petugas_id'];
        
        // 1. Cek apakah sudah diklaim orang lain
        $stmtCheck = $conn->prepare("
            SELECT t.petugas_id, u.full_name as nama_petugas 
            FROM transactions t 
            LEFT JOIN users u ON t.petugas_id = u.id 
            WHERE t.id = ?
        ");
        $stmtCheck->bind_param("s", $id);
        $stmtCheck->execute();
        $resCheck = $stmtCheck->get_result();
        
        if ($resCheck->num_rows > 0) {
            $row = $resCheck->fetch_assoc();
            $existingPetugasId = $row['petugas_id'];
            
            if ($existingPetugasId !== null && $existingPetugasId !== '' && $existingPetugasId !== $petugasId) {
                // Sudah diambil orang lain
                $namaPetugas = $row['nama_petugas'] ?? 'Lainnya';
                echo json_encode([
                    'success' => false, 
                    'message' => "Tugas sudah diambil oleh petugas $namaPetugas"
                ]);
                exit();
            }
        }
        
        // 2. Jika belum, claim tugas ini (set petugas_id dan status = 'menuju_lokasi')
        $stmt = $conn->prepare("UPDATE transactions SET petugas_id = ?, status = 'menuju_lokasi' WHERE id = ?");
        $stmt->bind_param("ss", $petugasId, $id);
        $stmt->execute();
        
        if ($stmt->affected_rows > 0 || $existingPetugasId === $petugasId) {
             echo json_encode([
                 'success' => true, 
                 'message' => 'Tugas berhasil diklaim'
             ]);
        } else {
             echo json_encode([
                 'success' => false, 
                 'message' => 'Gagal mengklaim tugas'
             ]);
        }
        exit();
    } else if ($id && isset($data['status'])) {
        $stmt = $conn->prepare("UPDATE transactions SET status = ? WHERE id = ?");
        $stmt->bind_param("ss", $data['status'], $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Status tugas diperbarui']);
    }
    exit();
}
