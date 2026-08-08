<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'POST') {
    $txId = $_POST['transaction_id'] ?? '';
    
    if (empty($txId)) {
        echo json_encode(['success' => false, 'message' => 'transaction_id diperlukan']);
        exit();
    }

    if (!isset($_FILES['photo']) || $_FILES['photo']['error'] !== 0) {
        echo json_encode(['success' => false, 'message' => 'Gagal mengunggah file atau tidak ada file']);
        exit();
    }

    $uploadDir = __DIR__ . '/../uploads/transactions/';
    if (!is_dir($uploadDir)) {
        mkdir($uploadDir, 0777, true);
    }

    $fileInfo = pathinfo($_FILES['photo']['name']);
    $extension = isset($fileInfo['extension']) ? strtolower($fileInfo['extension']) : '';
    
    $allowedExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    if (!in_array($extension, $allowedExts)) {
        echo json_encode(['success' => false, 'message' => 'Format file tidak didukung']);
        exit();
    }

    $newFilename = 'tx_' . $txId . '_' . time() . '.' . $extension;
    $targetFile = $uploadDir . $newFilename;

    if (move_uploaded_file($_FILES['photo']['tmp_name'], $targetFile)) {
        
        // Cek apakah sudah ada photo_evidence
        $stmt = $conn->prepare("SELECT photo_evidence FROM transactions WHERE id = ?");
        $stmt->bind_param("s", $txId);
        $stmt->execute();
        $res = $stmt->get_result();
        $existing = '';
        if ($row = $res->fetch_assoc()) {
            $existing = $row['photo_evidence'] ?? '';
        }

        $newList = [];
        if (!empty($existing)) {
            $newList = explode(',', $existing);
        }
        $newList[] = $newFilename;
        $finalPhotos = implode(',', $newList);

        $updateStmt = $conn->prepare("UPDATE transactions SET photo_evidence = ? WHERE id = ?");
        $updateStmt->bind_param("ss", $finalPhotos, $txId);
        $updateStmt->execute();

        echo json_encode([
            'success' => true,
            'message' => 'Berhasil mengunggah foto',
            'filename' => $newFilename,
            'photo_evidence' => $finalPhotos
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal memindahkan file yang diunggah']);
    }
    exit();
}

echo json_encode(['success' => false, 'message' => 'Metode tidak didukung']);
exit();
