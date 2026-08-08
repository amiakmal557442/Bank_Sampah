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
    $id = 'WD-' . time() . '-' . rand(100, 999);
    $nasabahId = $data['nasabah_id'] ?? '';
    $points = (int)($data['points_deducted'] ?? 0);
    $methodName = $data['method'] ?? 'Transfer Bank';
    $details = $data['account_details'] ?? '';

    $conn->begin_transaction();
    try {
        // Cek saldo poin dulu
        $stmt_check = $conn->prepare("SELECT point_balance FROM users WHERE id = ?");
        $stmt_check->bind_param("s", $nasabahId);
        $stmt_check->execute();
        $res_check = $stmt_check->get_result();
        $user_data = $res_check->fetch_assoc();
        
        if (!$user_data || $user_data['point_balance'] < $points) {
            throw new Exception("Poin tidak cukup");
        }

        $stmt = $conn->prepare("INSERT INTO withdrawals (id, nasabah_id, points_deducted, method, account_details, status) VALUES (?, ?, ?, ?, ?, 'pending')");
        $stmt->bind_param("ssiss", $id, $nasabahId, $points, $methodName, $details);
        $stmt->execute();

        // JANGAN potong poin di sini, biarkan status pending.
        
        $conn->commit();
        echo json_encode(['success' => true, 'message' => 'Penarikan berhasil diajukan']);
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => 'Gagal: ' . $e->getMessage()]);
    }
    exit();
}

if ($method === 'PUT') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? '';
    $status = $data['status'] ?? ''; // 'approved' or 'rejected'
    
    if (!$id || !$status) {
        echo json_encode(['success' => false, 'message' => 'Data tidak lengkap']);
        exit();
    }

    $conn->begin_transaction();
    try {
        // get withdrawal info
        $stmt = $conn->prepare("SELECT nasabah_id, points_deducted, status FROM withdrawals WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
        $wd = $result->fetch_assoc();
        
        if ($wd && $wd['status'] === 'pending') {
            
            if ($status === 'approved') {
                // Potong poin karena sudah disetujui
                $stmt_check = $conn->prepare("SELECT point_balance FROM users WHERE id = ?");
                $stmt_check->bind_param("s", $wd['nasabah_id']);
                $stmt_check->execute();
                $res_check = $stmt_check->get_result();
                $user_data = $res_check->fetch_assoc();
                
                if (!$user_data || $user_data['point_balance'] < $wd['points_deducted']) {
                    throw new Exception("Poin user tidak cukup untuk disetujui");
                }
                
                $stmt3 = $conn->prepare("UPDATE users SET point_balance = point_balance - ? WHERE id = ?");
                $stmt3->bind_param("is", $wd['points_deducted'], $wd['nasabah_id']);
                $stmt3->execute();
            }

            $stmt2 = $conn->prepare("UPDATE withdrawals SET status = ? WHERE id = ?");
            $stmt2->bind_param("ss", $status, $id);
            $stmt2->execute();
            
            $conn->commit();
            echo json_encode(['success' => true, 'message' => 'Status berhasil diubah']);
        } else {
            throw new Exception("Penarikan tidak ditemukan atau sudah diproses");
        }
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit();
}
