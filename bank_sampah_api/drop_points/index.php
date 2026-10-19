<?php
require_once __DIR__ . '/../db.php';

$method = $_SERVER['REQUEST_METHOD'];

// Ensure default Parepare drop points exist and have valid names
$conn->query("UPDATE drop_points SET name = 'Drop Point Pasar Lakessi', address = 'Jl. Lasinrang No. 12, Pasar Lakessi, Parepare', latitude = -4.0045, longitude = 119.6240, capacity_status = 'aman', operating_hours = '07:00 - 17:00' WHERE id = 'DP-001' AND (name = '' OR name = 'Drop Point Pusat Parepare')");
$conn->query("UPDATE drop_points SET name = 'Drop Point Lumpue', address = 'Jl. H.A.M. Arsyad, Lumpue, Bacukiki Barat, Parepare', latitude = -4.0410, longitude = 119.6280, capacity_status = 'aman', operating_hours = '08:00 - 17:00' WHERE id = 'DP-002' AND (name = '' OR name = 'Drop Point Soreang')");

$conn->query("INSERT IGNORE INTO drop_points (id, name, address, latitude, longitude, capacity_status, operating_hours) VALUES 
('DP-001', 'Drop Point Pasar Lakessi', 'Jl. Lasinrang No. 12, Pasar Lakessi, Parepare', -4.0045, 119.6240, 'aman', '07:00 - 17:00'),
('DP-002', 'Drop Point Lumpue', 'Jl. H.A.M. Arsyad, Lumpue, Bacukiki Barat, Parepare', -4.0410, 119.6280, 'aman', '08:00 - 17:00'),
('DP-003', 'Drop Point Pusat Parepare', 'Jl. Bau Massepe No. 10, Parepare', -4.0150, 119.6290, 'aman', '08:00 - 17:00'),
('DP-004', 'Drop Point Soreang', 'Jl. Jendral Sudirman No. 5, Soreang, Parepare', -3.9868, 119.6341, 'aman', '09:00 - 15:00')");

if ($method === 'GET') {
    $result = $conn->query("SELECT * FROM drop_points ORDER BY id ASC");
    $data = [];
    while ($row = $result->fetch_assoc()) {
        $row['latitude'] = (float)$row['latitude'];
        $row['longitude'] = (float)$row['longitude'];
        $row['capacity_status'] = $row['capacity_status'] ?? 'aman';
        $data[] = $row;
    }
    echo json_encode(['success' => true, 'data' => $data]);
    exit();
}

if ($method === 'POST') {
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);
    if (!$data || !is_array($data)) {
        echo json_encode(['success' => false, 'message' => 'Data tidak valid']);
        exit();
    }

    $id = !empty($data['id']) ? $data['id'] : ('DP-' . rand(100, 999));
    $name = trim($data['name'] ?? '');
    $address = trim($data['address'] ?? '');
    $lat = (float)($data['latitude'] ?? -4.0150);
    $lng = (float)($data['longitude'] ?? 119.6290);
    $capacity = in_array($data['capacity_status'] ?? '', ['aman', 'penuh']) ? $data['capacity_status'] : 'aman';
    $hours = !empty($data['operating_hours']) ? $data['operating_hours'] : '08:00 - 17:00';

    try {
        $stmt = $conn->prepare("INSERT INTO drop_points (id, name, address, latitude, longitude, capacity_status, operating_hours) VALUES (?, ?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name), address = VALUES(address), latitude = VALUES(latitude), longitude = VALUES(longitude), capacity_status = VALUES(capacity_status), operating_hours = VALUES(operating_hours)");
        $stmt->bind_param("sssddss", $id, $name, $address, $lat, $lng, $capacity, $hours);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Drop Point berhasil disimpan']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Gagal membuat drop point: ' . $stmt->error]);
        }
    } catch (Throwable $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit();
}

if ($method === 'PUT') {
    $id = $_GET['id'] ?? null;
    $raw = file_get_contents('php://input');
    $data = json_decode($raw, true);

    if (!$id || !$data) {
        echo json_encode(['success' => false, 'message' => 'ID dan payload wajib diisi']);
        exit();
    }

    $updates = [];
    $types = '';
    $values = [];

    if (!empty($data['name'])) {
        $updates[] = "name = ?";
        $types .= 's';
        $values[] = trim($data['name']);
    }
    if (isset($data['address'])) {
        $updates[] = "address = ?";
        $types .= 's';
        $values[] = trim($data['address']);
    }
    if (isset($data['capacity_status']) && in_array($data['capacity_status'], ['aman', 'penuh'])) {
        $updates[] = "capacity_status = ?";
        $types .= 's';
        $values[] = $data['capacity_status'];
    }
    if (isset($data['latitude'])) {
        $updates[] = "latitude = ?";
        $types .= 'd';
        $values[] = (float)$data['latitude'];
    }
    if (isset($data['longitude'])) {
        $updates[] = "longitude = ?";
        $types .= 'd';
        $values[] = (float)$data['longitude'];
    }
    if (isset($data['operating_hours'])) {
        $updates[] = "operating_hours = ?";
        $types .= 's';
        $values[] = $data['operating_hours'];
    }

    if (empty($updates)) {
        echo json_encode(['success' => true, 'message' => 'Tidak ada perubahan']);
        exit();
    }

    $sql = "UPDATE drop_points SET " . implode(', ', $updates) . " WHERE id = ?";
    $types .= 's';
    $values[] = $id;

    try {
        $stmt = $conn->prepare($sql);
        $stmt->bind_param($types, ...$values);
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Drop Point diperbarui']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Gagal memperbarui drop point: ' . $stmt->error]);
        }
    } catch (Throwable $e) {
        echo json_encode(['success' => false, 'message' => $e->getMessage()]);
    }
    exit();
}

if ($method === 'DELETE') {
    $id = $_GET['id'] ?? null;
    if ($id) {
        try {
            $stmt = $conn->prepare("DELETE FROM drop_points WHERE id = ?");
            $stmt->bind_param("s", $id);
            $stmt->execute();
            echo json_encode(['success' => true, 'message' => 'Drop Point dihapus']);
        } catch (Throwable $e) {
            echo json_encode(['success' => false, 'message' => $e->getMessage()]);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'ID wajib diisi']);
    }
    exit();
}
