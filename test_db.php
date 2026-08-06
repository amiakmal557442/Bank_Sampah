<?php
require 'bank_sampah_api/db.php';
$res = $conn->query('DESCRIBE users');
if ($res) {
    while ($row = $res->fetch_assoc()) {
        echo $row['Field'] . "\n";
    }
} else {
    echo "Error: " . $conn->error;
}
