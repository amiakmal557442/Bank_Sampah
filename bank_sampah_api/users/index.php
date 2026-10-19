<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

// Ensure profile_picture column exists
$checkCol = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_picture'");
if ($checkCol && $checkCol->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email");
}

// Convert any empty string phone_number to NULL to avoid duplicate key conflicts in UNIQUE column
$conn->query("UPDATE users SET phone_number = NULL WHERE phone_number = ''");

if ($method === 'GET') {
    $role = $_GET['role'] ?? null;
    $id = $_GET['id'] ?? null;

    if ($id) {
        $stmt = $conn->prepare("SELECT id, phone_number, email, full_name, role, address, default_setor_method, point_balance, is_active, profile_picture, created_at FROM users WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        $result = $stmt->get_result();
    } elseif ($role) {
        $mappedRole = ($role === 'staf_kantor') ? 'staf' : $role;
        $stmt = $conn->prepare("SELECT id, phone_number, email, full_name, role, address, default_setor_method, point_balance, is_active, profile_picture, created_at FROM users WHERE role = ?");
        $stmt->bind_param("s", $mappedRole);
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
    $rawInput = file_get_contents('php://input');
    $data = json_decode($rawInput, true);

    if (!$data || !is_array($data)) {
        echo json_encode(['success' => false, 'message' => 'Format payload JSON tidak valid']);
        exit();
    }

    $id = !empty($data['id']) ? trim($data['id']) : ('user-' . time() . rand(100, 999));

    // Normalize phone number: empty string or whitespace becomes NULL to prevent UNIQUE duplicate key conflict
    $phone = isset($data['phone_number']) ? trim($data['phone_number']) : null;
    if ($phone === '') {
        $phone = null;
    }

    // Normalize email: lowercase & trimmed. If empty string, set to NULL
    $email = isset($data['email']) ? strtolower(trim($data['email'])) : null;
    if ($email === '') {
        $email = null;
    }

    $passwordRaw = $data['password'] ?? '123456';
    $password = hash('sha256', $passwordRaw);
    $name = trim($data['full_name'] ?? '');

    $role = $data['role'] ?? 'nasabah';
    if ($role === 'staf_kantor') {
        $role = 'staf';
    }
    if (!in_array($role, ['nasabah', 'petugas', 'admin', 'staf'])) {
        $role = 'nasabah';
    }

    $address = isset($data['address']) ? trim($data['address']) : '';
    $profile_picture = !empty($data['profile_picture']) ? $data['profile_picture'] : null;
    $default_setor_method = !empty($data['default_setor_method']) ? $data['default_setor_method'] : ($role === 'petugas' ? 'pickup' : 'drop_in');
    $point_balance = isset($data['point_balance']) ? (int) $data['point_balance'] : 0;
    $is_active = isset($data['is_active']) ? (int) $data['is_active'] : 1;

    try {
        $stmt = $conn->prepare("INSERT INTO users (id, phone_number, email, password, full_name, role, address, profile_picture, default_setor_method, point_balance, is_active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("sssssssssii", $id, $phone, $email, $password, $name, $role, $address, $profile_picture, $default_setor_method, $point_balance, $is_active);

        if ($stmt->execute()) {
            echo json_encode([
                'success' => true,
                'message' => 'User berhasil dibuat',
                'data' => [
                    'id' => $id,
                    'full_name' => $name,
                    'email' => $email,
                    'role' => $role
                ]
            ]);
        } else {
            echo json_encode(['success' => false, 'message' => 'Gagal membuat user: ' . $stmt->error]);
        }
    } catch (Throwable $e) {
        $msg = $e->getMessage();
        if (strpos($msg, 'Duplicate entry') !== false) {
            if (strpos($msg, 'email') !== false) {
                $msg = 'Email sudah terdaftar pada akun lain';
            } elseif (strpos($msg, 'phone_number') !== false) {
                $msg = 'Nomor HP sudah terdaftar pada akun lain';
            } else {
                $msg = 'Data akun sudah ada (duplikat): ' . $msg;
            }
        }
        echo json_encode(['success' => false, 'message' => $msg]);
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

    if (isset($data['full_name'])) {
        $updates[] = "full_name = ?";
        $types .= 's';
        $values[] = trim($data['full_name']);
    }

    if (array_key_exists('phone_number', $data)) {
        $phoneVal = trim($data['phone_number'] ?? '');
        $updates[] = "phone_number = ?";
        $types .= 's';
        $values[] = ($phoneVal === '') ? null : $phoneVal;
    }

    if (array_key_exists('email', $data)) {
        $emailVal = strtolower(trim($data['email'] ?? ''));
        $updates[] = "email = ?";
        $types .= 's';
        $values[] = ($emailVal === '') ? null : $emailVal;
    }

    if (isset($data['role'])) {
        $roleVal = $data['role'];
        if ($roleVal === 'staf_kantor') $roleVal = 'staf';
        if (!in_array($roleVal, ['nasabah', 'petugas', 'admin', 'staf'])) $roleVal = 'nasabah';
        $updates[] = "role = ?";
        $types .= 's';
        $values[] = $roleVal;
    }

    if (isset($data['address'])) {
        $updates[] = "address = ?";
        $types .= 's';
        $values[] = trim($data['address']);
    }

    if (isset($data['password']) && !empty($data['password'])) {
        $updates[] = "password = ?";
        $types .= 's';
        $values[] = hash('sha256', $data['password']);
    }

    if (isset($data['default_setor_method'])) {
        $updates[] = "default_setor_method = ?";
        $types .= 's';
        $values[] = $data['default_setor_method'];
    }

    if (isset($data['profile_picture'])) {
        $updates[] = "profile_picture = ?";
        $types .= 's';
        $values[] = $data['profile_picture'];
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

    try {
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$values);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'User berhasil diperbarui']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Gagal memperbarui user: ' . $stmt->error]);
        }
    } catch (Throwable $e) {
        $msg = $e->getMessage();
        if (strpos($msg, 'Duplicate entry') !== false) {
            if (strpos($msg, 'email') !== false) {
                $msg = 'Email sudah terdaftar pada akun lain';
            } elseif (strpos($msg, 'phone_number') !== false) {
                $msg = 'Nomor HP sudah terdaftar pada akun lain';
            }
        }
        echo json_encode(['success' => false, 'message' => $msg]);
    }
    exit();
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if ($id) {
        try {
            $stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
            $stmt->bind_param("s", $id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'User berhasil dihapus']);
        } catch (Throwable $e) {
            echo json_encode(['success' => false, 'message' => 'Gagal menghapus user: ' . $e->getMessage()]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'ID wajib diisi']);
    }
    exit();
}
