<?php
require_once __DIR__ . '/../db.php';

$input = json_decode(file_get_contents('php://input'), true);

$email = $input['email'] ?? '';
$password = $input['password'] ?? '';

if (empty($email) || empty($password)) {
    echo json_encode(['success' => false, 'message' => 'Email dan password wajib diisi']);
    exit();
}

$hashed_pass = hash('sha256', $password);

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ? AND (password = ? OR password = ?)");
$stmt->bind_param("sss", $email, $password, $hashed_pass);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    unset($row['password']);
    $row['point_balance'] = (int) $row['point_balance'];
    $row['is_active'] = (int) ($row['is_active'] ?? 1);

    echo json_encode([
        'success' => true,
        'message' => 'Login berhasil',
        'data' => $row
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Email atau password salah'
    ]);
}
