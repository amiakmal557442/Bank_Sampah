<?php
$h = '$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe';
$candidates = ['123456', 'admin', 'admin123', 'akmal', 'akmal123', 'admin@banksampah.com', 'password', 'banksampah', 'parepare'];
foreach ($candidates as $p) {
    if (password_verify($p, $h)) {
        echo "MATCH: " . $p . "\n";
        exit;
    }
}
echo "NO MATCH\n";
