<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, ngrok-skip-browser-warning");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include '../db.php';

$summary = [
    'totalPetugas' => 0,
    'petugasAktif' => 0,
    'petugasIstirahat' => 0,
    'dropPointKritis' => 0,
    'tugasSelesai' => 0,
    'tugasAntrean' => 0,
];

$resPetugas = $conn->query("SELECT COUNT(*) as cnt FROM users WHERE role = 'petugas'");
if ($row = $resPetugas->fetch_assoc()) {
    $summary['totalPetugas'] = (int)$row['cnt'];
}

$resAktif = $conn->query("
    SELECT COUNT(DISTINCT u.id) as cnt
    FROM users u
    LEFT JOIN transactions t ON t.petugas_id = u.id AND t.status != 'selesai'
    WHERE u.role = 'petugas' AND (u.is_online = 1 OR t.id IS NOT NULL)
");
if ($row = $resAktif->fetch_assoc()) {
    $summary['petugasAktif'] = (int)$row['cnt'];
}
$summary['petugasIstirahat'] = max(0, $summary['totalPetugas'] - $summary['petugasAktif']);

$resKritis = $conn->query("SELECT COUNT(*) as cnt FROM drop_points WHERE capacity_status = 'kritis'");
if ($row = $resKritis->fetch_assoc()) {
    $summary['dropPointKritis'] = (int)$row['cnt'];
}

$resSelesai = $conn->query("SELECT COUNT(*) as cnt FROM transactions WHERE type = 'pickup' AND status = 'selesai'");
if ($row = $resSelesai->fetch_assoc()) {
    $summary['tugasSelesai'] = (int)$row['cnt'];
}

$resAntrean = $conn->query("SELECT COUNT(*) as cnt FROM transactions WHERE type = 'pickup' AND status = 'menunggu'");
if ($row = $resAntrean->fetch_assoc()) {
    $summary['tugasAntrean'] = (int)$row['cnt'];
}

$dropPoints = [];
$resDp = $conn->query("SELECT * FROM drop_points");
while ($row = $resDp->fetch_assoc()) {
    $percent = 50;
    if ($row['capacity_status'] == 'kritis') $percent = 90;
    if ($row['capacity_status'] == 'aman') $percent = 30;

    $idHash = crc32($row['id']);
    $percent = ($percent + ($idHash % 20)) % 100;

    $dropPoints[] = [
        'name' => $row['name'],
        'capacityPercent' => $percent,
        'isCritical' => $percent >= 80
    ];
}

$workerStatus = [];
$sqlWorker = "
    SELECT
        u.full_name as petugas_name,
        u.address as vehicle,
        t.pickup_lat,
        t.pickup_lng,
        t.id as task_id,
        t.status as task_status,
        t.type as task_type,
        dp.name as dp_name
    FROM users u
    LEFT JOIN transactions t ON t.petugas_id = u.id AND t.status != 'selesai'
    LEFT JOIN drop_points dp ON t.drop_point_id = dp.id
    WHERE u.role = 'petugas' AND (u.is_online = 1 OR t.id IS NOT NULL)
";
$resWorker = $conn->query($sqlWorker);
while ($row = $resWorker->fetch_assoc()) {
    $location = 'Pusat Kota';
    if (!empty($row['dp_name'])) {
        $location = $row['dp_name'];
    } else if (!empty($row['pickup_lat']) && !empty($row['pickup_lng'])) {
        $location = substr($row['pickup_lat'], 0, 8) . ', ' . substr($row['pickup_lng'], 0, 8);
    }

    $taskName = !empty($row['task_type']) ? ucfirst($row['task_type']) : 'Patroli';
    $statusName = !empty($row['task_status']) ? ucfirst(str_replace('_', ' ', $row['task_status'])) : 'Siaga';

    $workerStatus[] = [
        'petugas_name' => $row['petugas_name'] ?: 'Petugas',
        'vehicle' => $row['vehicle'] ?: 'Kendaraan Roda 2',
        'location' => $location,
        'task' => $taskName,
        'status' => $statusName
    ];
}

$response = [
    'summary' => $summary,
    'dropPoints' => $dropPoints,
    'workerStatus' => $workerStatus
];

echo json_encode($response);
?>
