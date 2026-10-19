<?php
include '../db.php';

$admin_id = isset($_GET['admin_id']) ? $_GET['admin_id'] : '';

$sql = "
    SELECT
        u.id,
        u.full_name,
        u.role,
        (SELECT COUNT(*) FROM chats c WHERE CAST(c.sender_id AS CHAR) = CAST(u.id AS CHAR) AND CAST(c.receiver_id AS CHAR) = ? AND c.is_read = 0) as unread_count
    FROM users u
    WHERE u.role IN ('nasabah', 'petugas') AND u.is_active = 1
    ORDER BY unread_count DESC, u.full_name ASC
";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $admin_id);
$stmt->execute();
$result = $stmt->get_result();

$users = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $users[] = [
            'id' => $row['id'],
            'full_name' => $row['full_name'],
            'role' => $row['role'],
            'unread_count' => (int)$row['unread_count']
        ];
    }
}

echo json_encode([
    'success' => true,
    'data' => $users
]);

$stmt->close();
$conn->close();
?>
