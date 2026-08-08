<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

// Auto-migration: Tambah kolom profile_picture jika belum ada
$checkCol = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_picture'");
if ($checkCol && $checkCol->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email");
}

if ($method === 'GET') {
    $role = $_GET['role'] ?? null;
    $id = $_GET['id'] ?? null;

    if ($id) {
        $stmt = $conn->prepare("SELECT id, phone_number, email, full_name, role, address, default_setor_method, point_balance, is_active, profile_picture, created_at FROM users WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
    } elseif ($role) {
        $stmt = $conn->prepare("SELECT id, phone_number, email, full_name, role, address, default_setor_method, point_balance, is_active, profile_picture, created_at FROM users WHERE role = ?");
        $stmt->bind_param("s", $role);
        $stmt->execute();
        $result = $stmt->get_result();
    } else {
        $result = $conn->query("SELECT id, phone_number, email, full_name, role, address, default_setor_method, point_balance, is_active, profile_picture, created_at FROM users");
    }
    
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $row['point_balance'] = (int) $row['point_balance'];
        $row['is_active'] = (int) ($row['is_active'] ?? 1);
        $users[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $users]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? ('USR-' . time());
    $phone = $data['phone_number'] ?? null;
    $email = $data['email'] ?? null;
    $password = hash('sha256', $data['password'] ?? '123456');
    $name = $data['full_name'] ?? '';
    $role = $data['role'] ?? 'nasabah';
    $address = $data['address'] ?? null;
    $profile_picture = $data['profile_picture'] ?? null;

    $stmt = $conn->prepare("INSERT INTO users (id, phone_number, email, password, full_name, role, address, profile_picture) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("ssssssss", $id, $phone, $email, $password, $name, $role, $address, $profile_picture);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'User berhasil dibuat']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal membuat user: ' . $conn->error]);
    }
    exit();
}

if ($method === 'PUT') {
    $id = $_GET['id'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);
    if (!$id) {
        echo json_encode(['success' => false, 'message' => 'ID User wajib diisi']);
        exit();
    }

    $updates = [];
    $types = '';
    $values = [];

    foreach (['full_name', 'phone_number', 'email', 'address', 'role', 'default_setor_method', 'profile_picture'] as $field) {
        if (isset($data[$field])) {
            $updates[] = "$field = ?";
            $types .= 's';
            $values[] = $data[$field];
        }
    }
    if (isset($data['point_balance'])) {
        $updates[] = "point_balance = ?";
        $types .= 'i';
        $values[] = (int) $data['point_balance'];
    }
    if (isset($data['is_active'])) {
        $updates[] = "is_active = ?";
        $types .= 'i';
        $values[] = (int) $data['is_active'];
    }

    if (empty($updates)) {
        echo json_encode(['success' => true, 'message' => 'Tidak ada perubahan']);
        exit();
    }

    $sql = "UPDATE users SET " . implode(', ', $updates) . " WHERE id = ?";
    $types .= 's';
    $values[] = $id;

    $stmt = $conn->prepare($sql);
    $stmt->bind_param($types, ...$values);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'User berhasil diperbarui']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal memperbarui user']);
    }
    exit();
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if ($id) {
        $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'User berhasil dihapus']);
    } else {
        echo json_encode(['success' => false, 'message' => 'ID wajib diisi']);
    }
    exit();
}
