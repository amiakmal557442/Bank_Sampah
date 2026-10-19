<?php
include '../db.php';

$sql = "SELECT id, full_name, role FROM users WHERE role = 'admin' OR role = 'staf' AND is_active = 1";
$result = $conn->query($sql);

$admins = [];
if ($result) {
    while($row = $result->fetch_assoc()) {
        $admins[] = [
            'id' => $row['id'],
            'full_name' => $row['full_name'],
            'role' => $row['role']
        ];
    }
}

echo json_encode([
    'success' => true,
    'data' => $admins
]);

$conn->close();
?>
