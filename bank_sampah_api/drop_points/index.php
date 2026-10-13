<?php
require_once __DIR__ . '/../db.php';
require_once __DIR__ . '/../jwt_helper.php';

$method = $_SERVER['REQUEST_METHOD'];

if ($method !== 'OPTIONS') {
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
}

if (in_array($method, ['POST', 'PUT', 'DELETE']) && $decoded_token['role'] !== 'admin') {
    echo json_encode(['success' => false, 'message' => 'Akses ditolak: Hanya admin yang diizinkan']);
    exit();
}

if ($method === 'GET') {
    $result = $conn->query("SELECT * FROM drop_points");
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $row['latitude'] = (float)$row['latitude'];
        $row['longitude'] = (float)$row['longitude'];
        $data[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $id = $data['id'] ?? ('DP-' . rand(100, 999));
    $name = $data['name'] ?? '';
    $address = $data['address'] ?? '';
    $lat = (float)($data['latitude'] ?? 0);
    $lng = (float)($data['longitude'] ?? 0);
    $capacity = $data['capacity_status'] ?? 'aman';
    $hours = $data['operating_hours'] ?? '08:00 - 17:00';

    $stmt = $conn->prepare("INSERT INTO drop_points (id, name, address, latitude, longitude, capacity_status, operating_hours) VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("sssddss", $id, $name, $address, $lat, $lng, $capacity, $hours);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Drop Point berhasil dibuat']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal membuat drop point']);
    }
    exit();
}

if ($method === 'PUT') {
    $id = $_GET['id'] ?? null;
    $data = json_decode(file_get_contents('php://input'), true);
    if ($id) {
        $stmt = $conn->prepare("UPDATE drop_points SET name = ?, address = ?, capacity_status = ? WHERE id = ?");
        $stmt->bind_param("ssss", $data['name'], $data['address'], $data['capacity_status'], $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Drop Point diperbarui']);
    }
    exit();
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if ($id) {
        $stmt = $conn->prepare("DELETE FROM drop_points WHERE id = ?");
        $stmt->bind_param("s", $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Drop Point dihapus']);
    }
    exit();
}
