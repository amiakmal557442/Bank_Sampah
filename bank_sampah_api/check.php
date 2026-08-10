<?php
require_once __DIR__ . '/db.php';
$res = $conn->query('SELECT * FROM audit_logs');
if (!$res) {
    echo "Error: " . $conn->error;
} else {
    while($r = $res->fetch_assoc()) echo json_encode($r)."\n";
}
