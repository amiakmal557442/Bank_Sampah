<?php
require_once 'db.php';
$res = $conn->query("SELECT * FROM transaction_items");
$items = [];
while ($row = $res->fetch_assoc()) {
    $items[] = $row;
}
echo json_encode($items, JSON_PRETTY_PRINT);
