<?php
require 'db.php';
$res = $conn->query("SHOW COLUMNS FROM worker_logs");
while($r = $res->fetch_assoc()){
    echo $r['Field'] . " - " . $r['Type'] . "\n";
}
