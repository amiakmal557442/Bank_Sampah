<?php
$data = json_encode(['time'=>'2026-08-10 16:00', 'user_name'=>'tes', 'role'=>'-', 'module'=>'Authentication', 'action'=>'Percobaan login gagal', 'ip_address'=>'127.0.0.1', 'status'=>'GAGAL']); 
$ch = curl_init('http://localhost/bank_sampah_api/audit_logs/index.php'); 
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true); 
curl_setopt($ch, CURLOPT_POST, 1); 
curl_setopt($ch, CURLOPT_POSTFIELDS, $data); 
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']); 
$res = curl_exec($ch); 
echo 'RES: '.$res;
