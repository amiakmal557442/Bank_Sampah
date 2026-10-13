<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../db.php';

$checkCol = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_picture'");
if ($checkCol && $checkCol->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email");
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

require_once __DIR__ . '/../jwt_helper.php';
$token = JwtHelper::getBearerToken();
if (!$token) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized: Token tidak ditemukan']);
    exit();
}
$decoded_token = JwtHelper::validateToken($token);
if (!$decoded_token) {
    http_response_code(401);
    echo json_encode(['success' => false, 'message' => 'Unauthorized: Token tidak valid']);
    exit();
}

$user_id = $_POST['user_id'] ?? null;

if ($decoded_token['role'] !== 'admin') {
    $user_id = $decoded_token['id'];
}

if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'ID User wajib dikirim']);
    exit();
}

if (!isset($_FILES['profile_picture']) || $_FILES['profile_picture']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(['success' => false, 'message' => 'File foto profil tidak ditemukan atau bermasalah']);
    exit();
}

$file = $_FILES['profile_picture'];
$tmp_name = $file['tmp_name'];

$finfo = finfo_open(FILEINFO_MIME_TYPE);
$mime_type = finfo_file($finfo, $tmp_name);
finfo_close($finfo);

$allowed_mimes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
if (!in_array($mime_type, $allowed_mimes)) {
    echo json_encode(['success' => false, 'message' => 'Format file palsu atau tidak didukung (harus gambar asli)']);
    exit();
}

$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
$allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
if (!in_array($ext, $allowedExts)) {
    echo json_encode(['success' => false, 'message' => 'Ekstensi file tidak didukung']);
    exit();
}

$uploadDir = __DIR__ . '/../uploads/profiles/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$filename = 'profile_' . preg_replace('/[^a-zA-Z0-9_\-]/', '_', $user_id) . '_' . time() . '.' . $ext;
$targetPath = $uploadDir . $filename;

if (move_uploaded_file($file['tmp_name'], $targetPath)) {

    $stmt = $conn->prepare("UPDATE users SET profile_picture = ? WHERE id = ?");
    $stmt->bind_param("ss", $filename, $user_id);
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Foto profil berhasil diunggah',
            'profile_picture' => $filename
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal memperbarui database: ' . $conn->error]);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Gagal menyimpan file ke server']);
}
