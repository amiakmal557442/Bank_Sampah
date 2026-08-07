<?php
require_once 'db.php';

$res = $conn->query("SELECT * FROM transaction_items");
$items = $res->fetch_all(MYSQLI_ASSOC);
echo "TRANSACTION ITEMS:\n";
print_r($items);

$res2 = $conn->query("SELECT * FROM waste_categories");
$cats = $res2->fetch_all(MYSQLI_ASSOC);
echo "\nWASTE CATEGORIES:\n";
print_r($cats);
