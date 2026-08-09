<?php
require_once __DIR__ . '/../bank_sampah_api/db.php';

// 1. Tambah kolom password jika belum ada
$checkPass = $conn->query("SHOW COLUMNS FROM users LIKE 'password'");
if ($checkPass && $checkPass->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN password VARCHAR(64) NOT NULL DEFAULT '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92' AFTER email");
    echo "Kolom 'password' berhasil ditambahkan.\n";
}

// 2. Tambah kolom profile_picture jika belum ada
$checkPic = $conn->query("SHOW COLUMNS FROM users LIKE 'profile_picture'");
if ($checkPic && $checkPic->num_rows === 0) {
    $conn->query("ALTER TABLE users ADD COLUMN profile_picture VARCHAR(255) DEFAULT NULL AFTER email");
    echo "Kolom 'profile_picture' berhasil ditambahkan.\n";
}

// 3. Reset password semua user ke '123456'
$passHash = hash('sha256', '123456');
$conn->query("UPDATE users SET password = '$passHash'");
echo "Semua password user berhasil di-set ke 123456.\n";
