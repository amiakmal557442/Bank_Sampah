<?php
require 'bank_sampah_api/db.php';
$conn->query("UPDATE drop_points SET latitude=-4.0150, longitude=119.6290 WHERE id='DP-001'");
echo 'Done';
