<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

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
