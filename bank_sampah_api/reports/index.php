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

$bulan = isset($_GET['bulan']) ? (int)$_GET['bulan'] : 0;
$tahun = isset($_GET['tahun']) ? (int)$_GET['tahun'] : 0;

$whereClause = "";
if ($bulan > 0 && $tahun > 0) {
    $bulanStr = str_pad($bulan, 2, "0", STR_PAD_LEFT);
    $whereClause = "WHERE DATE_FORMAT(created_at, '%m') = '$bulanStr' AND DATE_FORMAT(created_at, '%Y') = '$tahun'";
} else if ($tahun > 0) {
    $whereClause = "WHERE DATE_FORMAT(created_at, '%Y') = '$tahun'";
}

$sqlTx = "SELECT COUNT(*) as cnt, SUM(total_actual_points) as total_pts FROM transactions $whereClause " . ($whereClause ? "AND" : "WHERE") . " status = 'selesai'";
$resTx = $conn->query($sqlTx);
$rowTx = $resTx->fetch_assoc();
$total_tx = (int)($rowTx['cnt'] ?? 0);
$total_points = (int)($rowTx['total_pts'] ?? 0);

$sqlVol = "SELECT SUM(ti.actual_weight) as total_kg FROM transaction_items ti JOIN transactions t ON ti.transaction_id = t.id " . ($whereClause ? "$whereClause AND t.status = 'selesai'" : "WHERE t.status = 'selesai'");
$resVol = $conn->query($sqlVol);
$rowVol = $resVol->fetch_assoc();
$total_kg = (float)($rowVol['total_kg'] ?? 0.0);

$sqlNasabah = "SELECT COUNT(DISTINCT nasabah_id) as cnt FROM transactions $whereClause " . ($whereClause ? "AND" : "WHERE") . " status = 'selesai'";
$resNasabah = $conn->query($sqlNasabah);
$rowNasabah = $resNasabah->fetch_assoc();
$total_nasabah = (int)($rowNasabah['cnt'] ?? 0);

$sqlAllNasabah = "SELECT COUNT(*) as cnt FROM users WHERE role = 'nasabah'";
$resAllNasabah = $conn->query($sqlAllNasabah);
$rowAllNasabah = $resAllNasabah->fetch_assoc();
$all_nasabah = (int)($rowAllNasabah['cnt'] ?? 1);

$sqlCat = "
    SELECT wc.name, SUM(ti.actual_weight) as total_kg
    FROM transaction_items ti
    JOIN waste_categories wc ON ti.waste_category_id = wc.id
    JOIN transactions t ON ti.transaction_id = t.id
    " . ($whereClause ? "$whereClause AND t.status = 'selesai'" : "WHERE t.status = 'selesai'") . "
    GROUP BY wc.name ORDER BY total_kg DESC
";
$resCat = $conn->query($sqlCat);
$kategoriData = [];
while ($rowCat = $resCat->fetch_assoc()) {
    $kategoriData[] = [
        'name' => $rowCat['name'],
        'kg' => (float)$rowCat['total_kg']
    ];
}

$sqlTrend = "
    SELECT DATE_FORMAT(created_at, '%d/%m') as day, SUM(total_actual_points) as pts, COUNT(*) as cnt
    FROM transactions
    WHERE status = 'selesai' AND created_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
    GROUP BY DATE_FORMAT(created_at, '%d/%m')
    ORDER BY MIN(created_at) ASC
";
$resTrend = $conn->query($sqlTrend);
$trendData = [];
while ($rowTrend = $resTrend->fetch_assoc()) {
    $trendData[] = [
        'label' => $rowTrend['day'],
        'pts' => (float)$rowTrend['pts'],
        'cnt' => (int)$rowTrend['cnt']
    ];
}

$sqlRekap = "
    SELECT
        DATE_FORMAT(created_at, '%m/%Y') as periode,
        COUNT(*) as total_tx,
        SUM(total_actual_points) as total_pts
    FROM transactions
    WHERE status = 'selesai'
    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
    ORDER BY MAX(created_at) DESC
    LIMIT 6
";
$resRekap = $conn->query($sqlRekap);
$rekapData = [];
while ($rowRekap = $resRekap->fetch_assoc()) {
    $rekapData[] = [
        'periode' => $rowRekap['periode'],
        'total_tx' => (int)$rowRekap['total_tx'],
        'total_pts' => (float)$rowRekap['total_pts']
    ];
}

$recycle_pct = $total_kg > 0 ? ($total_kg / ($total_kg * 1.06)) * 100 : 0;

$response = [
    'totalTx' => $total_tx,
    'totalPoints' => $total_points,
    'totalKg' => $total_kg,
    'totalNasabah' => $total_nasabah,
    'allNasabah' => $all_nasabah,
    'recyclePct' => $recycle_pct,
    'kategoriData' => $kategoriData,
    'trendData' => $trendData,
    'rekapData' => $rekapData
];

echo json_encode($response);
?>
