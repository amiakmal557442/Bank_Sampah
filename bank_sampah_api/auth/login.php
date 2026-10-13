<?php
require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/../jwt_helper.php';

$input = json_decode(file_get_contents('php://input'), true);

$email = $input['email'] ?? '';
$password = $input['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(['success' => false, 'message' => 'Email dan password wajib diisi']);
    exit();
}

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    if (password_verify($password, $row['password'])) {

        $payload = [
            'id' => $row['id'],
            'role' => $row['role'],
            'email' => $row['email'],
            'exp' => time() + (86400 * 30)
        ];
        $token = JwtHelper::generateToken($payload);

        unset($row['password']);
        $row['point_balance'] = (int) $row['point_balance'];
        $row['is_active'] = (int) ($row['is_active'] ?? 1);

        echo json_encode([
            'success' => true,
            'message' => 'Login berhasil',
            'token' => $token,
            'data' => $row
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'Email atau password salah'
        ]);
    }
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Email atau password salah'
    ]);
}
