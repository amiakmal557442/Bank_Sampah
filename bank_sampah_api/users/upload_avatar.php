<?php
header('Content-Type: application/json');
require_once __DIR__ . '/../db.php';

// Auto-migration: Tambah kolom profile_picture jika belum ada
$checkCol = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_picture'");
if ($checkCol && $checkCol->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email");
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit();
}

$user_id = $_POST['user_id'] ?? null;
if (!$user_id) {
    echo json_encode(['success' => false, 'message' => 'ID User wajib dikirim']);
    exit();
}

if (!isset($_FILES['profile_picture']) || $_FILES['profile_picture']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(['success' => false, 'message' => 'File foto profil tidak ditemukan atau bermasalah']);
    exit();
}

$file = $_FILES['profile_picture'];
$allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
$ext = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));

if (!in_array($ext, $allowedExts)) {
    echo json_encode(['success' => false, 'message' => 'Format file tidak didukung (gunakan JPG, PNG, WEBP)']);
    exit();
}

// Buat folder uploads/profiles jika belum ada
$uploadDir = __DIR__ . '/../uploads/profiles/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

// Nama file unik berdasarkan user_id dan timestamp
$filename = 'profile_' . preg_replace('/[^a-zA-Z0-9_\-]/', '_', $user_id) . '_' . time() . '.' . $ext;
$targetPath = $uploadDir . $filename;

if (move_uploaded_file($file['tmp_name'], $targetPath)) {
    // Update ke database
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
