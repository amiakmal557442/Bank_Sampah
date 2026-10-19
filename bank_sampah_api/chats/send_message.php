<?php
include '../db.php';

$data = json_decode(file_get_contents('php://input'), true);

$sender_id = isset($data['sender_id']) ? $data['sender_id'] : '';
$receiver_id = isset($data['receiver_id']) ? $data['receiver_id'] : '';
$message = isset($data['message']) ? trim($data['message']) : '';

if (empty($sender_id) || empty($receiver_id) || empty($message)) {
    echo json_encode([
        'success' => false,
        'message' => 'Semua field (sender_id, receiver_id, message) harus diisi'
    ]);
    exit();
}

$stmt = $conn->prepare("INSERT INTO chats (sender_id, receiver_id, message, created_at) VALUES (?, ?, ?, NOW())");
$stmt->bind_param("sss", $sender_id, $receiver_id, $message);

if ($stmt->execute()) {
    echo json_encode([
        'success' => true,
        'message' => 'Pesan terkirim'
    ]);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'Gagal mengirim pesan: ' . $stmt->error
    ]);
}

$stmt->close();
$conn->close();
?>
