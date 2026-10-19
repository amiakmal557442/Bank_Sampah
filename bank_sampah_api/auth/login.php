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

$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();
$result = $stmt->get_result();

if ($row = $result->fetch_assoc()) {
    $dbPass = $row['password'] ?? '';
    $isValid = ($dbPass === $password) 
            || ($dbPass === $hashed_pass) 
            || (password_verify($password, $dbPass));

    if ($isValid) {
        unset($row['password']);
        $row['point_balance'] = (int) $row['point_balance'];
        $row['is_active'] = (int) ($row['is_active'] ?? 1);

        $updateOnline = $conn->prepare("UPDATE users SET is_online = 1 WHERE id = ?");
        $updateOnline->bind_param("s", $row['id']);
        $updateOnline->execute();

        echo json_encode([
            'success' => true,
            'message' => 'Login berhasil',
            'data' => $row
        ]);
        exit();
    }
}

echo json_encode([
    'success' => false,
    'message' => 'Email atau password salah'
]);
