<?php
require_once 'db.php';

$itemId = 'ITI-TEST-PUT';
$id = 'TRX-TEST-001';
$catId = 1;
$weight = 2.5;
$itemPoints = 5000;

$itemStmt = $conn->prepare("UPDATE transaction_items SET estimated_weight = ?, actual_weight = ?, final_points = ?, waste_category_id = ? WHERE id = ?");
$itemStmt->bind_param("ddiis", $weight, $weight, $itemPoints, $catId, $itemId);
$itemStmt->execute();

echo "Update Affected rows: " . $itemStmt->affected_rows . "\n";

if ($itemStmt->affected_rows === 0) {
    echo "Attempting INSERT...\n";
    $insertStmt = $conn->prepare("INSERT INTO transaction_items (id, transaction_id, waste_category_id, estimated_weight, actual_weight, final_points) VALUES (?, ?, ?, ?, ?, ?)");
    $insertStmt->bind_param("ssiddi", $itemId, $id, $catId, $weight, $weight, $itemPoints);
    if ($insertStmt->execute()) {
        echo "INSERT SUCCESS\n";
    } else {
        echo "INSERT FAILED: " . $insertStmt->error . "\n";
    }
}
