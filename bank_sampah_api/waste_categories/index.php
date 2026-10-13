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
    $result = $conn->query("SELECT * FROM waste_categories");
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $row['id'] = (int)$row['id'];
        $row['point_per_kg'] = (int)$row['point_per_kg'];
        $row['is_active'] = (int)$row['is_active'];
        $data[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit();
}

if ($method === 'POST') {
    $data = json_decode(file_get_contents('php://input'), true);
    $name = $data['name'] ?? '';
    $point = (int)($data['point_per_kg'] ?? 0);
    $icon = $data['icon_url'] ?? 'icon_default.png';

    $stmt = $conn->prepare("INSERT INTO waste_categories (name, point_per_kg, icon_url) VALUES (?, ?, ?)");
    $stmt->bind_param("sis", $name, $point, $icon);
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Kategori berhasil dibuat']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Gagal membuat kategori']);
    }
    exit();
}

if ($method === 'PUT') {
    $id = (int)($_GET['id'] ?? 0);
    $data = json_decode(file_get_contents('php://input'), true);
    if ($id > 0) {
        $stmt = $conn->prepare("UPDATE waste_categories SET name = ?, point_per_kg = ? WHERE id = ?");
        $stmt->bind_param("sii", $data['name'], $data['point_per_kg'], $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Kategori diperbarui']);
    }
    exit();
}

if ($method === 'DELETE') {
    $id = (int)($_GET['id'] ?? 0);
    if ($id > 0) {
        $stmt = $conn->prepare("DELETE FROM waste_categories WHERE id = ?");
        $stmt->bind_param("i", $id);
        $stmt->execute();
        echo json_encode(['success' => true, 'message' => 'Kategori dihapus']);
    }
    exit();
}
