<?php
$_SERVER['REQUEST_METHOD'] = 'POST';
$postData = json_encode([
    'id' => 'user-test-' . time(),
    'full_name' => 'Test User Admin',
    'email' => 'testadmin_' . time() . '@gmail.com',
    'phone_number' => '',
    'password' => 'password123',
    'role' => 'admin',
    'address' => '',
    'default_setor_method' => 'drop_in',
    'point_balance' => 0,
    'is_active' => 1
]);

// Simulate php://input
$stream = fopen('php://memory', 'r+');
fwrite($stream, $postData);
rewind($stream);

// Include db and execute
require_once 'C:/xampp/htdocs/bank_sampah_api/db.php';

$data = json_decode($postData, true);
$id = $data['id'] ?? ('USR-' . time());
$phone = $data['phone_number'] ?? null;
$email = $data['email'] ?? null;
$password = hash('sha256', $data['password'] ?? '123456');
$name = $data['full_name'] ?? '';
$role = $data['role'] ?? 'nasabah';
$address = $data['address'] ?? null;
$profile_picture = $data['profile_picture'] ?? null;

echo "Trying insert...\n";
$stmt = $conn->prepare("INSERT INTO users (id, phone_number, email, password, full_name, role, address, profile_picture) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
if (!$stmt) {
    die("Prepare failed: " . $conn->error . "\n");
}
$stmt->bind_param("ssssssss", $id, $phone, $email, $password, $name, $role, $address, $profile_picture);
if ($stmt->execute()) {
    echo "SUCCESS!\n";
} else {
    echo "Execute failed: " . $stmt->error . "\n";
}
