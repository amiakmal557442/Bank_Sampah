<?php
require_once __DIR__ . '/db.php';
$result = $conn->query("SHOW COLUMNS FROM withdrawals");
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
?>
