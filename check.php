<?php
require 'bank_sampah_api/db.php';
$sql = "SELECT * FROM withdrawals";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}
?>
