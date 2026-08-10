<?php
require_once __DIR__ . '/../db.php';

// Pastikan tabel audit_logs ada
$conn->query("
    CREATE TABLE IF NOT EXISTS audit_logs (
        id INT AUTO_INCREMENT PRIMARY KEY,
        time VARCHAR(50),
        user_name VARCHAR(100),
        role VARCHAR(50),
        module VARCHAR(100),
        action VARCHAR(255),
        ip_address VARCHAR(50),
        status VARCHAR(50)
    )
");

$method = $_SERVER['REQUEST_METHOD'] ?? (isset($_SERVER['HTTP_METHOD']) ? $_SERVER['HTTP_METHOD'] : 'GET');

if ($method === 'GET') {
    $modul = $_GET['modul'] ?? 'Semua Modul';
    $query = $_GET['query'] ?? '';

    $sql = "SELECT * FROM audit_logs WHERE 1=1";
    $params = [];
    $types = "";

    if ($modul !== 'Semua Modul') {
        $sql .= " AND module = ?";
        $params[] = $modul;
        $types .= "s";
    }

    if (!empty($query)) {
        $sql .= " AND (user_name LIKE ? OR action LIKE ?)";
        $params[] = "%$query%";
        $params[] = "%$query%";
        $types .= "ss";
    }

    $sql .= " ORDER BY id DESC";

    $stmt = $conn->prepare($sql);
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    $stmt->execute();
    $result = $stmt->get_result();

    $logs = [];
    while ($row = $result->fetch_assoc()) {
        $logs[] = $row;
    }

    echo json_encode(['success' => true, 'data' => $logs]);

} elseif ($method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $time = $input['time'] ?? '';
    $user_name = $input['user_name'] ?? '';
    $role = $input['role'] ?? '';
    $module = $input['module'] ?? '';
    $action = $input['action'] ?? '';
    $ip_address = $input['ip_address'] ?? '';
    $status = $input['status'] ?? '';

    if (empty($time) || empty($user_name) || empty($module) || empty($action)) {
        echo json_encode(['success' => false, 'message' => 'Data tidak lengkap']);
        exit();
    }

    $stmt = $conn->prepare("INSERT INTO audit_logs (time, user_name, role, module, action, ip_address, status) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssssss", $time, $user_name, $role, $module, $action, $ip_address, $status);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Audit log berhasil disimpan', 'id' => $stmt->insert_id]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal menyimpan audit log']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}
