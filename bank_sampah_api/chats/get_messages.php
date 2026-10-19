<?php
include '../db.php';

$user1 = isset($_GET['user1']) ? $_GET['user1'] : '';
$user2 = isset($_GET['user2']) ? $_GET['user2'] : '';

if (empty($user1) || empty($user2)) {
    echo json_encode([
        'success' => false,
        'message' => 'user1 dan user2 harus diisi'
    ]);
    exit();
}

$stmt_update = $conn->prepare("UPDATE chats SET is_read = 1 WHERE receiver_id = ? AND sender_id = ?");
$stmt_update->bind_param("ss", $user1, $user2);
$stmt_update->execute();
$stmt_update->close();

$stmt = $conn->prepare("
    SELECT * FROM chats
    WHERE (sender_id = ? AND receiver_id = ?)
       OR (sender_id = ? AND receiver_id = ?)
    ORDER BY created_at ASC
");
$stmt->bind_param("ssss", $user1, $user2, $user2, $user1);
$stmt->execute();
$result = $stmt->get_result();

$messages = [];
while($row = $result->fetch_assoc()) {
    $messages[] = $row;
}

echo json_encode([
    'success' => true,
    'data' => $messages
]);

$stmt->close();
$conn->close();
?>
