-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Aug 05, 2026 at 12:10 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `bank_sampah`
--

-- --------------------------------------------------------

--
-- Table structure for table `b2b_sales`
--

CREATE TABLE `b2b_sales` (
  `id` varchar(36) NOT NULL,
  `partner_name` varchar(150) NOT NULL,
  `total_weight` decimal(10,2) NOT NULL,
  `total_margin` decimal(15,2) NOT NULL,
  `sale_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `drop_points`
--

CREATE TABLE `drop_points` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` text NOT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `capacity_status` enum('aman','penuh') DEFAULT 'aman',
  `operating_hours` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `drop_points`
--

INSERT INTO `drop_points` (`id`, `name`, `address`, `latitude`, `longitude`, `capacity_status`, `operating_hours`) VALUES
('DP-001', 'Drop Point Pusat Parepare', 'Jl. Bau Massepe No. 10, Parepare', -4.0150, 119.6290, 'aman', '08:00 - 17:00'),
('DP-002', 'Drop Point Soreang', 'Jl. Jendral Sudirman No. 5, Soreang', -3.9920, 119.6350, 'aman', '09:00 - 15:00');

-- --------------------------------------------------------

--
-- Table structure for table `transactions`
--

CREATE TABLE `transactions` (
  `id` varchar(20) NOT NULL,
  `nasabah_id` varchar(36) NOT NULL,
  `petugas_id` varchar(36) DEFAULT NULL,
  `drop_point_id` varchar(36) DEFAULT NULL,
  `type` enum('drop_in','pickup','rvm','donasi') NOT NULL,
  `status` enum('menunggu','dikonfirmasi','menuju_lokasi','tiba','selesai','dibatalkan','terverifikasi','ditolak') DEFAULT 'menunggu',
  `pickup_date` date DEFAULT NULL,
  `pickup_time_slot` varchar(50) DEFAULT NULL,
  `pickup_lat` double DEFAULT NULL,
  `pickup_lng` double DEFAULT NULL,
  `total_est_points` int(11) DEFAULT 0,
  `total_actual_points` int(11) DEFAULT 0,
  `photo_evidence` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transactions`
--

INSERT INTO `transactions` (`id`, `nasabah_id`, `petugas_id`, `drop_point_id`, `type`, `status`, `pickup_date`, `pickup_time_slot`, `pickup_lat`, `pickup_lng`, `total_est_points`, `total_actual_points`, `photo_evidence`, `created_at`) VALUES
('TRX-0991', 'USR-003', 'USR-002', NULL, 'pickup', 'menunggu', '2026-08-05', NULL, -6.21, 106.82, 15000, 0, NULL, '2026-08-05 10:09:24'),
('TRX-0992', 'USR-004', 'USR-002', NULL, 'pickup', 'menunggu', '2026-08-05', NULL, -6.22, 106.83, 25000, 0, NULL, '2026-08-05 10:09:24');

-- --------------------------------------------------------

--
-- Table structure for table `transaction_items`
--

CREATE TABLE `transaction_items` (
  `id` varchar(36) NOT NULL,
  `transaction_id` varchar(20) NOT NULL,
  `waste_category_id` int(11) NOT NULL,
  `estimated_weight` decimal(10,2) DEFAULT NULL,
  `actual_weight` decimal(10,2) DEFAULT NULL,
  `final_points` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transaction_items`
--

INSERT INTO `transaction_items` (`id`, `transaction_id`, `waste_category_id`, `estimated_weight`, `actual_weight`, `final_points`) VALUES
('TI-001', 'TRX-0991', 1, 5.00, NULL, NULL),
('TI-002', 'TRX-0991', 2, 4.00, NULL, NULL),
('TI-003', 'TRX-0992', 4, 15.00, NULL, NULL),
('TI-004', 'TRX-0992', 3, 6.00, NULL, NULL);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `full_name` varchar(100) NOT NULL,
  `role` enum('nasabah','petugas','admin','staf') NOT NULL DEFAULT 'nasabah',
  `address` text DEFAULT NULL,
  `default_setor_method` enum('drop_in','pickup','rvm','donasi') DEFAULT NULL,
  `point_balance` int(11) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `phone_number`, `email`, `full_name`, `role`, `address`, `default_setor_method`, `point_balance`, `created_at`) VALUES
('USR-001', '081234567890', 'admin@banksampah.com', 'Akmal Ahsan', 'admin', 'Kantor Pusat Bank Sampah', NULL, 0, '2026-08-05 10:09:24'),
('USR-002', '081987654321', 'tokan@banksampah.com', 'Tokan Shimada', 'petugas', 'Jl. Petugas No. 1', NULL, 0, '2026-08-05 10:09:24'),
('USR-003', '081112223334', 'budi@gmail.com', 'Budi Santoso', 'nasabah', 'Jl. Mawar Kembar No. 12, Blok C', NULL, 15000, '2026-08-05 10:09:24');

-- --------------------------------------------------------

--
-- Table structure for table `waste_categories`
--

CREATE TABLE `waste_categories` (
  `id` int(11) NOT NULL,
  `name` varchar(50) NOT NULL,
  `point_per_kg` int(11) NOT NULL,
  `icon_url` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `waste_categories`
--

INSERT INTO `waste_categories` (`id`, `name`, `point_per_kg`, `icon_url`, `is_active`) VALUES
(1, 'Plastik', 2000, 'icon_plastik.png', 1),
(2, 'Kertas & Kardus', 1500, 'icon_kertas.png', 1),
(3, 'Besi & Logam', 3500, 'icon_besi.png', 1),
(4, 'Elektronik Bekas', 5000, 'icon_elektronik.png', 1);

-- --------------------------------------------------------

--
-- Table structure for table `withdrawals`
--

CREATE TABLE `withdrawals` (
  `id` varchar(36) NOT NULL,
  `nasabah_id` varchar(36) NOT NULL,
  `points_deducted` int(11) NOT NULL,
  `method` varchar(50) NOT NULL,
  `account_details` text NOT NULL,
  `status` enum('pending','approved','rejected') DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `worker_logs`
--

CREATE TABLE `worker_logs` (
  `id` varchar(36) NOT NULL,
  `petugas_id` varchar(36) NOT NULL,
  `log_type` varchar(50) DEFAULT NULL,
  `location_lat` double DEFAULT NULL,
  `location_lng` double DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `b2b_sales`
--
ALTER TABLE `b2b_sales`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `drop_points`
--
ALTER TABLE `drop_points`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nasabah_id` (`nasabah_id`),
  ADD KEY `petugas_id` (`petugas_id`),
  ADD KEY `drop_point_id` (`drop_point_id`);

--
-- Indexes for table `transaction_items`
--
ALTER TABLE `transaction_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `transaction_id` (`transaction_id`),
  ADD KEY `waste_category_id` (`waste_category_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `phone_number` (`phone_number`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `waste_categories`
--
ALTER TABLE `waste_categories`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `withdrawals`
--
ALTER TABLE `withdrawals`
  ADD PRIMARY KEY (`id`),
  ADD KEY `nasabah_id` (`nasabah_id`);

--
-- Indexes for table `worker_logs`
--
ALTER TABLE `worker_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `petugas_id` (`petugas_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `waste_categories`
--
ALTER TABLE `waste_categories`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`nasabah_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `transactions_ibfk_3` FOREIGN KEY (`drop_point_id`) REFERENCES `drop_points` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `transaction_items`
--
ALTER TABLE `transaction_items`
  ADD CONSTRAINT `transaction_items_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `transaction_items_ibfk_2` FOREIGN KEY (`waste_category_id`) REFERENCES `waste_categories` (`id`);

--
-- Constraints for table `withdrawals`
--
ALTER TABLE `withdrawals`
  ADD CONSTRAINT `withdrawals_ibfk_1` FOREIGN KEY (`nasabah_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `worker_logs`
--
ALTER TABLE `worker_logs`
  ADD CONSTRAINT `worker_logs_ibfk_1` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
