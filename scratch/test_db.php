<?php
require_once __DIR__ . '/../bank_sampah_api/db.php';

if ($conn->connect_error) {
    echo "CONNECTION_ERROR: " . $conn->connect_error;
    exit();
}

$result = $conn->query("SELECT id, email, full_name, role FROM users");
if ($result) {
    echo "SUCCESS! User count: " . $result->num_rows . "\n";
    while ($row = $result->fetch_assoc()) {
        echo " - " . $row['email'] . " (" . $row['full_name'] . " - " . $row['role'] . ")\n";
    }
} else {
    echo "MYSQL_QUERY_ERROR: " . $conn->error . "\n";
}
