<?php
require_once __DIR__ . '/../bank_sampah_api/db.php';

$hash123456 = hash('sha256', '123456');
$sql = "UPDATE users SET password = '$hash123456'";
if ($conn->query($sql)) {
    echo "SUCCESS: Semua password akun di MySQL berhasil di-reset menjadi 123456!\n";
} else {
    echo "ERROR: " . $conn->error . "\n";
}
