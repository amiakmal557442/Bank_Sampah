<?php
require_once 'db.php';
$res = $conn->query("SHOW COLUMNS FROM transaction_items");
while ($row = $res->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
