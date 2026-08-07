<?php
require_once 'db.php';

$id = 'TRX-TEST-001';
$itemId = 'ITI-TEST-001';
$catId = 1;
$weight = 2.5;
$itemPoints = 5000;

// try insert transaction first
$conn->query("INSERT IGNORE INTO transactions (id, nasabah_id, type) VALUES ('$id', 'USR-001', 'drop_in')");

$insertStmt = $conn->prepare("INSERT INTO transaction_items (id, transaction_id, waste_category_id, estimated_weight, actual_weight, final_points) VALUES (?, ?, ?, ?, ?, ?)");
$insertStmt->bind_param("ssiddi", $itemId, $id, $catId, $weight, $weight, $itemPoints);

if ($insertStmt->execute()) {
    echo "SUCCESS\n";
} else {
    echo "ERROR: " . $insertStmt->error . "\n";
}
