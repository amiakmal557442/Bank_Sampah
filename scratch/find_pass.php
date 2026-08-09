<?php
require_once __DIR__ . '/../bank_sampah_api/db.php';

$res = $conn->query("SELECT email, password FROM users");
while ($r = $res->fetch_assoc()) {
    echo $r['email'] . " => " . $r['password'] . "\n";
}
