<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    $id = $_GET['id'] ?? null;
    $status = $_GET['status'] ?? null;
    $nasabahId = $_GET['nasabah_id'] ?? null;
    $petugasId = $_GET['petugas_id'] ?? null;

    if ($id) {
        $stmt = $conn->prepare("SELECT t.*, u.full_name as nasabah_name FROM transactions t JOIN users u ON t.nasabah_id = u.id WHERE t.id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $res = $stmt->get_result();
        if ($tx = $res->fetch_assoc()) {
            $itemStmt = $conn->prepare("SELECT * FROM transaction_items WHERE transaction_id = ?");
            $itemStmt->bind_param("s", $id);
            $itemStmt->execute();
            $itemsRes = $itemStmt->get_result();
            $tx['items'] = $itemsRes->fetch_all(MYSQLI_ASSOC);
            echo json_encode(['success' => true, 'data' => $tx]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Transaksi tidak ditemukan']);
        }
        exit();
    }

    $where = [];
    $params = [];
    $types = '';

    if ($status) {
        if (strpos($status, ',') !== false) {
            $where[] = "FIND_IN_SET(t.status, ?) > 0";
        } else {
            $where[] = "t.status = ?";
        }
        $types .= 's';
        $params[] = $status;
    }
    if ($nasabahId) {
        $where[] = "t.nasabah_id = ?";
        $types .= 's';
        $params[] = $nasabahId;
    }
    if ($petugasId) {
        $where[] = "(t.petugas_id = ? OR t.petugas_id IS NULL OR t.petugas_id = '')";
        $types .= 's';
        $params[] = $petugasId;
    }

    $sql = "SELECT t.*, u.full_name as nasabah_name, p.full_name as petugas_name 
            FROM transactions t 
            LEFT JOIN users u ON t.nasabah_id = u.id 
            LEFT JOIN users p ON t.petugas_id = p.id";

    if (!empty($where)) {
        $sql .= " WHERE " . implode(" AND ", $where);
    }
    $sql .= " ORDER BY t.created_at DESC";

    if (!empty($params)) {
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$params);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        $result = $conn->query($sql);
    }

    $transactions = [];
    while ($row = $result->fetch_assoc()) {
        $txId = $row['id'];
        $itemStmt = $conn->prepare("SELECT ti.*, wc.name as category_name FROM transaction_items ti LEFT JOIN waste_categories wc ON ti.waste_category_id = wc.id WHERE ti.transaction_id = ?");
        $itemStmt->bind_param("s", $txId);
        $itemStmt->execute();
        $itemsRes = $itemStmt->get_result();
        $rawItems = $itemsRes->fetch_all(MYSQLI_ASSOC);
        $items = [];
        foreach ($rawItems as $item) {
            if (isset($item['estimated_weight'])) {
                $item['estimated_weight'] = (float)$item['estimated_weight'];
            }
            if (isset($item['actual_weight'])) {
                $item['actual_weight'] = (float)$item['actual_weight'];
            }
            $items[] = $item;
        }
        $row['items'] = $items;

        $row['total_est_points'] = (int)$row['total_est_points'];
        $row['total_actual_points'] = (int)$row['total_actual_points'];
        $transactions[] = $row;
    }

    echo json_encode(['success' => true, 'data' => $transactions]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? ('TRX-' . rand(1000, 9999));
    $nasabahId = $data['nasabah_id'] ?? '';
    $petugasId = $data['petugas_id'] ?? null;
    $dropPointId = $data['drop_point_id'] ?? null;
    $type = $data['type'] ?? 'pickup';
    $status = $data['status'] ?? 'menunggu';
    $pickupDate = $data['pickup_date'] ?? date('Y-m-d');
    $estPoints = (int)($data['total_est_points'] ?? 0);

    $stmt = $conn->prepare("INSERT INTO transactions (id, nasabah_id, petugas_id, drop_point_id, type, status, pickup_date, total_est_points) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssssssi", $id, $nasabahId, $petugasId, $dropPointId, $type, $status, $pickupDate, $estPoints);
    
    if ($stmt->execute()) {
        if (!empty($data['items']) && is_array($data['items'])) {
            foreach ($data['items'] as $item) {
                $itemId = 'TI-' . rand(100, 999);
                $catId = (int)($item['waste_category_id'] ?? 1);
                $estWeight = (float)($item['estimated_weight'] ?? 0);
                $itemStmt = $conn->prepare("INSERT INTO transaction_items (id, transaction_id, waste_category_id, estimated_weight) VALUES (?, ?, ?, ?)");
                $itemStmt->bind_param("ssid", $itemId, $id, $catId, $estWeight);
                $itemStmt->execute();
            }
        }
        echo json_encode(['success' => true, 'message' => 'Transaksi berhasil dibuat', 'id' => $id]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal membuat transaksi: ' . $conn->error]);
    }
    exit();
}

if ($method === 'PUT') {
    $id = $_GET['id'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID Transaksi wajib diisi']);
        exit();
    }
    file_put_contents('put_log.txt', print_r($data, true) . PHP_EOL, FILE_APPEND);

    $updates = [];
    $types = '';
    $values = [];

    if (isset($data['status'])) {
        $updates[] = "status = ?";
        $types .= 's';
        $values[] = $data['status'];
    }
    if (isset($data['petugas_id'])) {
        $updates[] = "petugas_id = ?";
        $types .= 's';
        $values[] = $data['petugas_id'];
    }
    if (isset($data['total_actual_points'])) {
        $updates[] = "total_actual_points = ?";
        $types .= 'i';
        $values[] = (int)$data['total_actual_points'];
    }
    if (isset($data['total_est_points'])) {
        $updates[] = "total_est_points = ?";
        $types .= 'i';
        $values[] = (int)$data['total_est_points'];
    }

    if (!empty($updates)) {
        $sql = "UPDATE transactions SET " . implode(', ', $updates) . " WHERE id = ?";
        $types .= 's';
        $values[] = $id;

        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$values);
        $stmt->execute();
    }

    // Process items & weight updates
    if (!empty($data['items']) && is_array($data['items'])) {
        $calculatedPoints = 0;
        foreach ($data['items'] as $item) {
            $itemId = $item['id'] ?? null;
            $weight = (float)($item['actual_weight'] ?? $item['estimated_weight'] ?? 0);
            $catId = (int)($item['waste_category_id'] ?? 1);

            $catRes = $conn->query("SELECT point_per_kg FROM waste_categories WHERE id = $catId");
            $pointPerKg = 2000;
            if ($catRow = $catRes->fetch_assoc()) {
                $pointPerKg = (int)$catRow['point_per_kg'];
            }
            $itemPoints = (int)round($weight * $pointPerKg);
            $calculatedPoints += $itemPoints;

            if ($itemId) {
                $itemStmt = $conn->prepare("UPDATE transaction_items SET estimated_weight = ?, actual_weight = ?, final_points = ?, waste_category_id = ? WHERE id = ?");
                $itemStmt->bind_param("ddiis", $weight, $weight, $itemPoints, $catId, $itemId);
                if (!$itemStmt->execute()) {
                    file_put_contents('put_log.txt', "UPDATE ERROR: " . $itemStmt->error . PHP_EOL, FILE_APPEND);
                }

                if ($itemStmt->affected_rows === 0) {
                    $insertStmt = $conn->prepare("INSERT INTO transaction_items (id, transaction_id, waste_category_id, estimated_weight, actual_weight, final_points) VALUES (?, ?, ?, ?, ?, ?)");
                    $insertStmt->bind_param("ssiddi", $itemId, $id, $catId, $weight, $weight, $itemPoints);
                    if (!$insertStmt->execute()) {
                        file_put_contents('put_log.txt', "INSERT ERROR: " . $insertStmt->error . PHP_EOL, FILE_APPEND);
                    }
                }
            }
        }
        if ($calculatedPoints > 0) {
            $conn->query("UPDATE transactions SET total_est_points = $calculatedPoints, total_actual_points = $calculatedPoints WHERE id = '$id'");
        }
    }

    // Update user point_balance if status becomes dikonfirmasi/terverifikasi/selesai
    if (isset($data['status']) && in_array($data['status'], ['dikonfirmasi', 'selesai', 'terverifikasi'])) {
        $txRes = $conn->query("SELECT nasabah_id, total_est_points, total_actual_points FROM transactions WHERE id = '$id'");
        if ($txRow = $txRes->fetch_assoc()) {
            $points = $txRow['total_actual_points'] > 0 ? (int)$txRow['total_actual_points'] : (int)$txRow['total_est_points'];
            $nasabahId = $txRow['nasabah_id'];
            if ($points > 0 && !empty($nasabahId)) {
                $conn->query("UPDATE users SET point_balance = point_balance + $points WHERE id = '$nasabahId'");
            }
        }
    }

    echo json_encode(['success' => true, 'message' => 'Transaksi berhasil diperbarui']);
    exit();
}
