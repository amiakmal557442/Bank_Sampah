<?php
require 'bank_sampah_api/db.php';
$res = $conn->query('SELECT * FROM drop_points');
while($row = $res->fetch_assoc()) {
    print_r($row);
}
