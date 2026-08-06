-- ============================================================
-- PERBAIKAN DATABASE BANK SAMPAH
-- Jalankan file ini di phpMyAdmin > SQL
-- ============================================================

-- 1. Tambah kolom password & is_active ke tabel users (jika belum ada)
ALTER TABLE `users` 
  ADD COLUMN IF NOT EXISTS `password` varchar(255) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `is_active` tinyint(1) DEFAULT 1;

-- Update password default untuk akun yang belum punya password
-- Hash SHA-256 dari "123456" = 8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92
UPDATE `users` SET `password` = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'
  WHERE `password` IS NULL OR `password` = '';

UPDATE `users` SET `is_active` = 1 WHERE `is_active` IS NULL;

-- 2. Hapus data dummy lama yang sudah tidak relevan
--    (Budi Santoso USR-003 dan transaksi terkait)
--    Foreign key ON DELETE CASCADE akan otomatis hapus transactions & items milik USR-003
DELETE FROM `users` WHERE `id` = 'USR-003';

-- Hapus juga USR-004 jika ada (Siti Aminah)
DELETE FROM `users` WHERE `id` = 'USR-004';

-- 3. Hapus transaksi orphan yang nasabah_id-nya sudah tidak ada
DELETE FROM `transactions` 
  WHERE `nasabah_id` NOT IN (SELECT `id` FROM `users`);

-- 4. Tambahkan kolom full_name dan address ke transactions sebagai fallback
ALTER TABLE `transactions`
  ADD COLUMN IF NOT EXISTS `full_name` varchar(100) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `address` text DEFAULT NULL;

-- Update full_name dan address di transactions dari data users yang masih ada
UPDATE `transactions` t
  JOIN `users` u ON t.nasabah_id = u.id
  SET t.full_name = u.full_name, t.address = u.address
  WHERE t.full_name IS NULL;

-- 5. Tambah indeks untuk performa query
ALTER TABLE `transactions` ADD INDEX IF NOT EXISTS `idx_status` (`status`);

-- ============================================================
-- SELESAI. Refresh phpMyAdmin untuk melihat perubahan.
-- ============================================================
