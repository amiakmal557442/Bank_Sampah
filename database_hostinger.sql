-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: bank_sampah
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` varchar(50) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `role` varchar(50) DEFAULT NULL,
  `module` varchar(100) DEFAULT NULL,
  `action` varchar(255) DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `status` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=122 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
INSERT INTO `audit_logs` VALUES (1,'2026-08-10 16:00','tes_curl','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(2,'2026-08-10 23:59','admin@banksampah.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(3,'2026-08-10 23:59','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(4,'2026-08-10 23:59','jdjsofn','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(5,'2026-08-11 00:00','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(6,'2026-08-11 00:00','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(7,'2026-08-11 07:47','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(8,'2026-08-11 07:48','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(9,'2026-08-11 07:48','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(10,'2026-08-11 07:49','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(11,'2026-08-11 07:53','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(12,'2026-08-13 13:54','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(13,'2026-08-13 14:08','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(14,'2026-08-13 14:10','accank','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(15,'2026-08-13 14:11','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(16,'2026-08-13 14:30','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(17,'2026-08-13 15:02','afkar','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(18,'2026-08-13 15:03','accank','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(19,'2026-08-13 15:03','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(20,'2026-08-13 15:04','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(21,'2026-08-13 15:08','accank','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(22,'2026-08-13 15:09','afkar','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(23,'2026-08-13 15:12','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(24,'2026-08-13 15:24','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(25,'2026-08-13 15:25','Administrator','Admin','Konfigurasi Sistem','Mengubah konfigurasi sistem dan limit poin','127.0.0.1','BERHASIL'),(26,'2026-08-13 15:58','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(27,'2026-08-13 16:03','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(28,'2026-08-13 17:39','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(29,'2026-08-13 18:01','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(30,'2026-08-13 18:12','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(31,'2026-08-13 18:12','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(32,'2026-08-13 18:19','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(33,'2026-08-13 18:20','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(34,'2026-08-13 18:25','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(35,'2026-08-13 18:26','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(36,'2026-08-13 18:36','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(37,'2026-08-13 18:36','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(38,'2026-08-13 18:43','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(39,'2026-08-13 18:44','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(40,'2026-08-13 18:53','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(41,'2026-08-13 18:53','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(42,'2026-08-13 18:54','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(43,'2026-08-13 18:55','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(44,'2026-08-13 18:55','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(45,'2026-08-13 18:57','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(46,'2026-08-13 18:57','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(47,'2026-08-13 18:58','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(48,'2026-08-13 18:59','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(49,'2026-08-13 18:59','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(50,'2026-08-13 19:00','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(51,'2026-08-13 19:00','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(52,'2026-08-13 19:00','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(53,'2026-08-13 19:10','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(54,'2026-08-13 19:10','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(55,'2026-08-13 19:11','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(56,'2026-08-13 19:11','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(57,'2026-08-13 19:12','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(58,'2026-08-13 19:13','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(59,'2026-08-13 19:25','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(60,'2026-08-13 19:25','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(61,'2026-08-14 14:58','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(62,'2026-08-14 15:02','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(63,'2026-08-14 15:06','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(64,'2026-08-14 15:06','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(65,'2026-08-14 15:21','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(66,'2026-08-14 15:33','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(67,'2026-08-14 15:47','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(68,'2026-08-14 16:03','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(69,'2026-08-14 16:04','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(70,'2026-08-14 16:04','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(71,'2026-08-14 16:05','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(72,'2026-08-14 16:05','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(73,'2026-08-14 16:09','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(74,'2026-08-14 16:22','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(75,'2026-08-14 16:30','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(76,'2026-08-14 16:31','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(77,'2026-08-14 16:32','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(78,'2026-08-14 16:43','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(79,'2026-08-14 17:59','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(80,'2026-08-14 18:03','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(81,'2026-08-14 18:04','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(82,'2026-08-14 18:05','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(83,'2026-08-14 18:10','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(84,'2026-08-14 18:10','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(85,'2026-08-14 18:22','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(86,'2026-08-14 18:22','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(87,'2026-08-14 18:23','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(88,'2026-08-14 18:25','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(89,'2026-08-14 18:25','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(90,'2026-08-14 18:26','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(91,'2026-08-14 18:31','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(92,'2026-08-14 18:36','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(93,'2026-08-14 18:36','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(94,'2026-08-14 18:37','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(95,'2026-08-14 18:38','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(96,'2026-08-14 18:38','akmal galon le mineral','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(97,'2026-08-17 16:24','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(98,'2026-08-17 16:24','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(99,'2026-09-13 09:02','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(100,'2026-09-13 09:03','akmal@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(101,'2026-09-13 09:03','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(102,'2026-09-13 09:04','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(103,'2026-09-13 09:13','tokan','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(104,'2026-09-17 17:06','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(105,'2026-09-17 17:10','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(106,'2026-09-17 17:10','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(107,'2026-09-17 17:11','muhakmal557@gmail.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(108,'2026-09-17 17:11','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(109,'2026-09-17 17:12','user','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(110,'2026-09-17 17:13','petugas@banksampah.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(111,'2026-09-17 17:15','user','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(112,'2026-09-17 17:24','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(113,'2026-10-03 16:12','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(114,'2026-10-11 20:51','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(115,'2026-10-11 20:52','user','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(116,'2026-10-12 10:01','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(117,'2026-10-12 10:37','user','nasabah','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(118,'2026-10-12 10:40','petugas@banksampah.com','-','Authentication','Percobaan login gagal','127.0.0.1','GAGAL'),(119,'2026-10-12 10:41','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(120,'2026-10-12 10:41','Tokan Shimada','petugas','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL'),(121,'2026-10-12 10:45','Akmal Ahsan','admin','Authentication','Login ke dalam sistem','127.0.0.1','BERHASIL');
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `b2b_sales`
--

DROP TABLE IF EXISTS `b2b_sales`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `b2b_sales` (
  `id` varchar(36) NOT NULL,
  `partner_name` varchar(150) NOT NULL,
  `total_weight` decimal(10,2) NOT NULL,
  `total_margin` decimal(15,2) NOT NULL,
  `sale_date` date NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `b2b_sales`
--

LOCK TABLES `b2b_sales` WRITE;
/*!40000 ALTER TABLE `b2b_sales` DISABLE KEYS */;
/*!40000 ALTER TABLE `b2b_sales` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `chats`
--

DROP TABLE IF EXISTS `chats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `chats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `sender_id` varchar(50) NOT NULL,
  `receiver_id` varchar(50) NOT NULL,
  `message` text NOT NULL,
  `is_read` tinyint(1) DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_sender` (`sender_id`),
  KEY `idx_receiver` (`receiver_id`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `chats`
--

LOCK TABLES `chats` WRITE;
/*!40000 ALTER TABLE `chats` DISABLE KEYS */;
INSERT INTO `chats` VALUES (1,'USR-002','USR-001','akmal',1,'2026-08-09 14:47:11'),(2,'USR-002','USR-001','OIIII',1,'2026-08-09 14:55:09'),(3,'USR-001','USR-002','APAAA ?????',1,'2026-08-09 14:55:35'),(4,'USR-002','USR-001','tes dulu',1,'2026-08-09 15:00:39'),(5,'USR-001','USR-002','bagus',1,'2026-08-09 15:07:47'),(6,'user-1785927466185000','USR-001','oi mal',1,'2026-08-09 15:26:34'),(7,'USR-001','user-1785927466185000','apa ?',1,'2026-08-09 15:26:59'),(8,'user-1785927466185000','USR-001','bisami ga ?',1,'2026-08-09 15:27:12'),(9,'USR-001','user-1785927466185000','bah bah bisami',1,'2026-08-09 15:27:18'),(10,'USR-002','USR-001','bang motor aing meledak',1,'2026-08-10 11:55:42'),(11,'USR-001','USR-002','njir',1,'2026-08-10 11:55:52'),(12,'USR-001','USR-002','kok bisa bang',1,'2026-08-10 11:56:02'),(13,'user-1785927466185000','USR-001','oi admin',1,'2026-08-10 15:36:10'),(14,'USR-001','user-1785927466185000','njir',1,'2026-08-10 15:36:17'),(15,'USR-001','user-1785927466185000','apa coba',1,'2026-08-10 15:36:33'),(16,'USR-002','USR-001','bang ada member suki',1,'2026-08-10 15:46:17'),(17,'user-1786601421931367','USR-001','tes',1,'2026-08-13 06:13:28'),(18,'USR-001','user-1786601421931367','terkirim',1,'2026-08-13 06:13:49'),(19,'USR-002','user-1785927466185000','we telaso',1,'2026-08-14 08:43:29'),(20,'USR-002','user-1785927466185000','tes',1,'2026-08-14 09:59:57'),(21,'user-1785927466185000','petugas123','bang.... dimana ???',0,'2026-08-14 10:04:24'),(22,'USR-002','user-1785927466185000','oi bang mana ???',1,'2026-08-14 10:25:49'),(23,'user-1785927466185000','USR-002','sorry bang sorry',1,'2026-08-14 10:31:45');
/*!40000 ALTER TABLE `chats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `drop_points`
--

DROP TABLE IF EXISTS `drop_points`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `drop_points` (
  `id` varchar(36) NOT NULL,
  `name` varchar(100) NOT NULL,
  `address` text NOT NULL,
  `latitude` double DEFAULT NULL,
  `longitude` double DEFAULT NULL,
  `capacity_status` enum('aman','penuh') DEFAULT 'aman',
  `operating_hours` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `drop_points`
--

LOCK TABLES `drop_points` WRITE;
/*!40000 ALTER TABLE `drop_points` DISABLE KEYS */;
INSERT INTO `drop_points` VALUES ('DP-001','Drop Point Pasar Lakessi','Jl. Lasinrang No. 12, Pasar Lakessi, Parepare',-4.0045,119.624,'aman','07:00 - 17:00'),('DP-002','Drop Point Lumpue','Jl. H.A.M. Arsyad, Lumpue, Bacukiki Barat, Parepare',-4.041,119.628,'aman','08:00 - 17:00'),('DP-003','Drop Point Pusat Parepare','Jl. Bau Massepe No. 10, Ujung, Parepare',-4.015,119.629,'aman','08:00 - 17:00'),('DP-004','Drop Point Soreang','Jl. Jendral Sudirman No. 5, Soreang, Parepare',-3.9868,119.6341,'aman','09:00 - 15:00');
/*!40000 ALTER TABLE `drop_points` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transaction_items`
--

DROP TABLE IF EXISTS `transaction_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `transaction_items` (
  `id` varchar(36) NOT NULL,
  `transaction_id` varchar(20) NOT NULL,
  `waste_category_id` int(11) NOT NULL,
  `estimated_weight` decimal(10,2) DEFAULT NULL,
  `actual_weight` decimal(10,2) DEFAULT NULL,
  `final_points` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `transaction_id` (`transaction_id`),
  KEY `waste_category_id` (`waste_category_id`),
  CONSTRAINT `transaction_items_ibfk_1` FOREIGN KEY (`transaction_id`) REFERENCES `transactions` (`id`) ON DELETE CASCADE,
  CONSTRAINT `transaction_items_ibfk_2` FOREIGN KEY (`waste_category_id`) REFERENCES `waste_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transaction_items`
--

LOCK TABLES `transaction_items` WRITE;
/*!40000 ALTER TABLE `transaction_items` DISABLE KEYS */;
INSERT INTO `transaction_items` VALUES ('ITI-1234567890123000-1','TRX-1786100158065',1,2.00,2.00,4000),('ITI-1785934752031000','TRX-1785934752031',3,0.00,0.00,0),('ITI-1785934807430000','TRX-1785934807429',1,0.00,0.00,0),('ITI-1785936341856000','TRX-1785936341855',3,0.00,0.00,0),('ITI-1785936570271000','TRX-1785936570270',3,0.00,0.00,0),('ITI-1785937266934000','TRX-1785937266934',3,0.00,0.00,0),('ITI-1785939884468000','TRX-1785939884468',1,0.00,0.00,0),('ITI-1785941060944000','TRX-1785941060942',1,0.00,0.00,0),('ITI-1785941649057000','TRX-1785941649056',1,0.00,0.00,0),('ITI-1785975956941000','TRX-1785975956941',2,0.00,0.00,0),('ITI-1785976298540000','TRX-1785976298540',4,0.00,0.00,0),('ITI-1785977609828000','TRX-1785977609828',1,0.00,0.00,0),('ITI-1785978339780000','TRX-1785978339780',1,0.00,0.00,0),('ITI-1785979635501000','TRX-1785979635501',4,0.00,0.00,0),('ITI-1785979770773000','TRX-1785979770772',3,0.00,0.00,0),('ITI-1785980267220000','TRX-1785980267220',1,0.00,0.00,0),('ITI-1785980267221000','TRX-1785980267220',2,0.00,0.00,0),('ITI-1785981131499000','TRX-1785981131499',3,0.00,0.00,0),('ITI-1785981469549000','TRX-1785981469549',3,0.00,0.00,0),('ITI-1785981907397000','TRX-1785981907396',1,0.00,0.00,0),('ITI-1785981979150000','TRX-1785981979150',1,0.00,0.00,0),('ITI-1785982380244000','TRX-1785982380243',4,0.00,0.00,0),('ITI-1785983337965000','TRX-1785983337965',3,0.00,0.00,0),('ITI-1785997084545000','TRX-1785997084545',3,0.00,0.00,0),('ITI-1786102919283000-1','TRX-1786102868031',3,2.50,2.50,8750),('ITI-1786103315836000','TRX-1786103298089',3,3.50,3.50,12250),('ITI-1786115412538540','TRX-1786115061423',1,2.00,2.00,4000),('ITI-1786115412539407','TRX-1786115061423',3,5.00,5.00,17500),('ITI-1786190591665000-1','TRX-1786190455282',4,6.50,6.50,32500),('ITI-1786190599482000-1','TRX-1786188256043',1,1.00,1.00,2000),('ITI-1786195444269503-1','TRX-1786194884383',1,1.00,1.00,2000),('ITI-1786195531413370','TRX-1786195406427',4,4.50,4.50,22500),('ITI-1786195679154127','TRX-1786195606935',1,2.50,2.50,5000),('ITI-1786197117531593-1','TRX-1786197008879',1,1.00,1.00,2000),('ITI-1786197117532977-2','TRX-1786197008879',2,3.50,3.50,5250),('ITI-1786283773840000','TRX-1786283030133',1,1.00,1.00,2000),('ITI-1786283777597000','TRX-1786279949467',1,1.00,1.00,2000),('ITI-1786283781894000','TRX-1786283723892',1,1.00,1.00,2000),('ITI-1786284535517000-1','TRX-1786284473933',4,4.00,4.00,20000),('ITI-1786285462886000-1','TRX-1786285414196',1,1.00,1.00,2000),('ITI-1786285462886000-2','TRX-1786285414196',2,1.00,1.00,1500),('ITI-1786285462886000-3','TRX-1786285414196',3,1.00,1.00,3500),('ITI-1786285462886000-4','TRX-1786285414196',4,1.00,1.00,5000),('ITI-1786363124289544','TRX-1786363032930',1,1.00,1.00,2000),('ITI-1786363204515623-1','TRX-1786363144338',1,1.00,1.00,2000),('ITI-1786364853970000-1','TRX-1786363918128',1,1.00,1.00,2000),('ITI-1786364853970000-2','TRX-1786363918128',2,1.00,1.00,1500),('ITI-1786369202049000','TRX-1786366059622',1,1.00,1.00,2000),('ITI-1786369202050000','TRX-1786366059622',3,3.50,3.50,12250),('ITI-1786376758749602-1','TRX-1786376092369',3,3.50,3.50,12250),('ITI-1786405842516290-1','TRX-1786405764435',1,1.00,1.00,2000),('ITI-1786605048202345-1','TRX-1786604686274',1,2.00,2.00,4000),('ITI-1786605048202345-2','TRX-1786604686274',2,2.00,2.00,3000),('ITI-1786616765007000','TRX-1786604975096',1,1.00,1.00,2000),('ITI-1786618693393000-1','TRX-1786618523564',3,41.00,41.00,143500),('ITI-1786618693393000-2','TRX-1786618523564',4,1.00,1.00,5000),('ITI-1786619467429000','TRX-1786619400716',1,40.50,40.50,81000),('ITI-1786619467430000','TRX-1786619400716',4,10.00,10.00,50000),('ITI-1786695802019000-1','TRX-1786694687872',1,1.00,1.00,2000),('ITI-1786701905992000','TRX-1786696296938',1,1.00,1.00,2000),('ITI-1786702213737000','TRX-1786696254082',1,1.00,1.00,2000),('ITI-1786703137027000','TRX-1786702888705',1,3.50,3.50,7000),('ITI-1786703792186000','TRX-1786703087846',2,1.50,1.50,2250),('ITI-1786955095928000-1','TRX-1786703855915',1,1.00,1.00,2000),('ITI-1791773010005000','TRX-1789636376536',3,2.00,2.00,7000),('ITI-TEST-001','TRX-TEST-001',1,2.50,2.50,5000),('ITI-TEST-PUT','TRX-TEST-001',1,2.50,2.50,5000),('TI-130','TRX-1785999972679',3,0.00,NULL,NULL),('TI-168','TRX-1786026023719',2,0.00,NULL,NULL),('TI-249','TRX-1786024986716',1,0.00,NULL,NULL),('TI-261','TRX-1785998733473',3,0.00,NULL,NULL),('TI-266','TRX-1786024778308',3,0.00,NULL,NULL),('TI-267','TRX-1786024778308',1,0.00,NULL,NULL),('TI-273','TRX-1786026991171',2,0.00,NULL,NULL),('TI-298','TRX-1786024956417',3,0.00,NULL,NULL),('TI-464','TRX-1786026991171',1,0.00,NULL,NULL),('TI-480','TRX-1786081764700',2,0.00,NULL,NULL),('TI-484','TRX-1786024986716',2,0.00,NULL,NULL),('TI-488','TRX-1786000585406',3,0.00,NULL,NULL),('TI-554','TRX-1786081617769',1,0.00,NULL,NULL),('TI-694','TRX-1785998733473',2,0.00,NULL,NULL),('TI-741','TRX-1786026023719',1,0.00,NULL,NULL),('TI-811','TRX-1786088651695',1,0.00,NULL,NULL),('TI-824','TRX-1786088651695',2,0.00,NULL,NULL),('TI-853','TRX-1786026117114',2,0.00,NULL,NULL),('TI-890','TRX-1786024778308',2,0.00,NULL,NULL),('TI-904','TRX-1786081764700',1,0.00,NULL,NULL),('TI-959','TRX-1786026117114',1,0.00,NULL,NULL);
/*!40000 ALTER TABLE `transaction_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
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
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `full_name` varchar(100) DEFAULT NULL,
  `address` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `nasabah_id` (`nasabah_id`),
  KEY `petugas_id` (`petugas_id`),
  KEY `drop_point_id` (`drop_point_id`),
  KEY `idx_status` (`status`),
  CONSTRAINT `transactions_ibfk_1` FOREIGN KEY (`nasabah_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `transactions_ibfk_2` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`) ON DELETE SET NULL,
  CONSTRAINT `transactions_ibfk_3` FOREIGN KEY (`drop_point_id`) REFERENCES `drop_points` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transactions`
--

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES ('TRX-1785934752031','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 12:59:12','akmal le mineral',''),('TRX-1785934807429','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 13:00:07','akmal le mineral',''),('TRX-1785936341855','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 13:25:41','akmal le mineral',''),('TRX-1785936570270','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 13:29:30','akmal le mineral',''),('TRX-1785937266934','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 13:41:06','akmal le mineral',''),('TRX-1785939884468','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-05 14:24:44','akmal le mineral',''),('TRX-1785941060942','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-05 14:44:20','akmal le mineral',''),('TRX-1785941649056','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,460,NULL,'2026-08-05 14:54:09','akmal le mineral',''),('TRX-1785975956941','user-1785927466185000',NULL,'DP-002','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-06 00:25:57','akmal le mineral',''),('TRX-1785976298540','user-1785976279071000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-06 00:31:38','shimada',''),('TRX-1785977609828','user-1785927466185000',NULL,'DP-002','drop_in','selesai',NULL,NULL,NULL,NULL,0,370,NULL,'2026-08-06 00:53:29','akmal le mineral',''),('TRX-1785978339780','user-1785976279071000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,250,NULL,'2026-08-06 01:05:39','shimada',''),('TRX-1785979635501','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,290,NULL,'2026-08-06 01:27:15','akmal le mineral',''),('TRX-1785979770772','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-06 01:29:30','akmal le mineral',''),('TRX-1785980267220','user-1785927466185000',NULL,'DP-002','drop_in','selesai',NULL,NULL,NULL,NULL,0,1555,NULL,'2026-08-06 01:37:47','akmal le mineral',''),('TRX-1785981131499','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,4250,NULL,'2026-08-06 01:52:11','akmal le mineral',''),('TRX-1785981469549','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-06 01:57:49','akmal le mineral',''),('TRX-1785981907396','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-06 02:05:07','akmal le mineral',''),('TRX-1785981979150','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-06 02:06:19','akmal le mineral',''),('TRX-1785982380243','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,0,NULL,'2026-08-06 02:13:00','akmal le mineral',''),('TRX-1785983337965','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,42000,NULL,'2026-08-06 02:28:57','akmal le mineral',''),('TRX-1785997084545','user-1785927466185000',NULL,'DP-001','drop_in','selesai',NULL,NULL,NULL,NULL,0,2000,NULL,'2026-08-06 06:18:04','akmal le mineral',''),('TRX-1785998733473','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-06',NULL,NULL,NULL,0,2000,NULL,'2026-08-06 06:45:33','akmal le mineral',''),('TRX-1785999972679','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-06',NULL,NULL,NULL,0,2000,NULL,'2026-08-06 07:06:12','akmal le mineral',''),('TRX-1786000585406','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-06',NULL,NULL,NULL,0,3500,NULL,'2026-08-06 07:16:25','akmal le mineral',''),('TRX-1786024778308','petugas-1785927406580000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,15750,NULL,'2026-08-06 13:59:38',NULL,NULL),('TRX-1786024956417','petugas-1785927406580000',NULL,'DP-001','drop_in','selesai','2026-08-06',NULL,NULL,NULL,0,3500,NULL,'2026-08-06 14:02:36',NULL,NULL),('TRX-1786024986716','petugas-1785927406580000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,2000,NULL,'2026-08-06 14:03:06',NULL,NULL),('TRX-1786026023719','petugas-1785927406580000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,3500,NULL,'2026-08-06 14:20:23',NULL,NULL),('TRX-1786026117114','petugas-1785927406580000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,6000,NULL,'2026-08-06 14:21:57',NULL,NULL),('TRX-1786026991171','petugas-1785927406580000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,11000,NULL,'2026-08-06 14:36:31',NULL,NULL),('TRX-1786081617769','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,9500,NULL,'2026-08-07 05:46:59',NULL,NULL),('TRX-1786081764700','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,2000,NULL,'2026-08-07 05:49:25',NULL,NULL),('TRX-1786088651695','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,4250,NULL,'2026-08-07 07:44:12',NULL,NULL),('TRX-1786091229956','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,16500,NULL,'2026-08-07 08:27:10',NULL,NULL),('TRX-1786092406167','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,7000,NULL,'2026-08-07 08:46:46',NULL,NULL),('TRX-1786095379019','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,3500,NULL,'2026-08-07 09:36:19',NULL,NULL),('TRX-1786095896975','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,12500,NULL,'2026-08-07 09:44:57',NULL,NULL),('TRX-1786099310284','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,2000,NULL,'2026-08-07 10:41:50',NULL,NULL),('TRX-1786099323714','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,7000,NULL,'2026-08-07 10:42:03',NULL,NULL),('TRX-1786099450497','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,2000,NULL,'2026-08-07 10:44:10',NULL,NULL),('TRX-1786099461050','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,2000,NULL,'2026-08-07 10:44:21',NULL,NULL),('TRX-1786100158065','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,4000,4000,NULL,'2026-08-07 10:55:58',NULL,NULL),('TRX-1786100882218','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,5000,NULL,'2026-08-07 11:08:02',NULL,NULL),('TRX-1786101976810','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,0,8000,NULL,'2026-08-07 11:26:16',NULL,NULL),('TRX-1786102868031','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,0,8750,NULL,'2026-08-07 11:41:08',NULL,NULL),('TRX-1786103298089','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,12250,12250,NULL,'2026-08-07 11:48:18',NULL,NULL),('TRX-1786115061423','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-07',NULL,NULL,NULL,21500,21500,NULL,'2026-08-07 15:04:21',NULL,NULL),('TRX-1786188256043','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-08',NULL,NULL,NULL,2000,2000,NULL,'2026-08-08 11:24:16',NULL,NULL),('TRX-1786190455282','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-08',NULL,NULL,NULL,32500,32500,NULL,'2026-08-08 12:00:56',NULL,NULL),('TRX-1786194884383','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-08',NULL,NULL,NULL,2000,2000,'tx_TRX-1786194884383_1786194886.jpg','2026-08-08 13:14:45',NULL,NULL),('TRX-1786195403662','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan','2026-08-08',NULL,NULL,NULL,0,0,'tx_TRX-1786195403662_1786195407.jpg','2026-08-08 13:23:24',NULL,NULL),('TRX-1786195406427','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-08',NULL,NULL,NULL,22500,22500,'tx_TRX-1786195406427_1786195410.jpg','2026-08-08 13:23:27',NULL,NULL),('TRX-1786195606935','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,5000,5000,'tx_TRX-1786195606935_1786195611.jpg','2026-08-08 13:26:47',NULL,NULL),('TRX-1786197008879','user-1785927466185000',NULL,NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,7250,7250,'tx_TRX-1786197008879_1786197012.jpg','2026-08-08 13:50:09',NULL,NULL),('TRX-1786279859052','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan','2026-08-09',NULL,NULL,NULL,0,0,NULL,'2026-08-09 12:50:59',NULL,NULL),('TRX-1786279949467','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-09',NULL,NULL,NULL,2000,2000,NULL,'2026-08-09 12:52:29',NULL,NULL),('TRX-1786283030133','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-09',NULL,NULL,NULL,2000,2000,NULL,'2026-08-09 13:43:50',NULL,NULL),('TRX-1786283723892','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,2000,2000,NULL,'2026-08-09 13:55:24',NULL,NULL),('TRX-1786284473933','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-09',NULL,NULL,NULL,20000,20000,'tx_TRX-1786284473933_1786284475.jpg','2026-08-09 14:07:54',NULL,NULL),('TRX-1786285414196','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,12000,12000,'tx_TRX-1786285414196_1786285415.jpg','2026-08-09 14:23:34',NULL,NULL),('TRX-1786363032930','user-1785927466185000',NULL,'DP-001','drop_in','selesai','2026-08-10',NULL,NULL,NULL,2000,2000,'tx_TRX-1786363032930_1786363030.jpg','2026-08-10 11:57:10',NULL,NULL),('TRX-1786363144338','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,2000,2000,'tx_TRX-1786363144338_1786363142.jpg','2026-08-10 11:59:01',NULL,NULL),('TRX-1786363889407','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan','2026-08-10',NULL,NULL,NULL,0,0,NULL,'2026-08-10 12:11:29',NULL,NULL),('TRX-1786363918128','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,3500,3500,'tx_TRX-1786363918128_1786363919.jpg','2026-08-10 12:11:58',NULL,NULL),('TRX-1786366059622','user-1785927466185000','USR-002','DP-001','drop_in','selesai','2026-08-10',NULL,NULL,NULL,14250,14250,NULL,'2026-08-10 12:47:39',NULL,NULL),('TRX-1786376040465','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan','2026-08-10',NULL,NULL,NULL,0,0,NULL,'2026-08-10 15:34:05',NULL,NULL),('TRX-1786376047168','user-1785927466185000',NULL,'DP-001','drop_in','dibatalkan','2026-08-10',NULL,NULL,NULL,0,0,NULL,'2026-08-10 15:34:05',NULL,NULL),('TRX-1786376092369','user-1785927466185000','USR-002','DP-001','drop_in','selesai','2026-08-10',NULL,NULL,NULL,12250,12250,'tx_TRX-1786376092369_1786376093.jpg','2026-08-10 15:34:49',NULL,NULL),('TRX-1786405764435','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,2000,2000,'tx_TRX-1786405764435_1786405765.jpg','2026-08-10 23:49:22',NULL,NULL),('TRX-1786604683508','user-1785927466185000',NULL,'DP-002','drop_in','dibatalkan','2026-08-13',NULL,NULL,NULL,0,0,'tx_TRX-1786604683508_1786604681.jpg','2026-08-13 07:04:37',NULL,NULL),('TRX-1786604686274','user-1785927466185000','petugas-1786604528843431','DP-002','drop_in','selesai','2026-08-13',NULL,NULL,NULL,7000,7000,'tx_TRX-1786604686274_1786604690.jpg','2026-08-13 07:04:40',NULL,NULL),('TRX-1786604975096','user-1785927466185000','USR-002','DP-001','drop_in','selesai','2026-08-13',NULL,NULL,NULL,2000,2000,NULL,'2026-08-13 07:09:29',NULL,NULL),('TRX-1786618523564','user-1785927466185000','USR-002','DP-002','drop_in','selesai','2026-08-13',NULL,NULL,NULL,148500,148500,NULL,'2026-08-13 10:55:24',NULL,NULL),('TRX-1786619400716','user-1785927466185000','USR-002','DP-001','drop_in','selesai','2026-08-13',NULL,NULL,NULL,131000,131000,NULL,'2026-08-13 11:10:01',NULL,NULL),('TRX-1786694687872','user-1785927466185000','USR-002','DP-002','drop_in','selesai','2026-08-14',NULL,NULL,NULL,2000,2000,NULL,'2026-08-14 08:04:48',NULL,NULL),('TRX-1786696254082','user-1785927466185000','USR-002','DP-002','drop_in','selesai','2026-08-14',NULL,NULL,NULL,2000,2000,NULL,'2026-08-14 08:30:54',NULL,NULL),('TRX-1786696296938','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,2000,2000,NULL,'2026-08-14 08:31:37',NULL,NULL),('TRX-1786702888705','user-1785927466185000','USR-002','DP-002','drop_in','selesai','2026-08-14',NULL,NULL,NULL,7000,7000,NULL,'2026-08-14 10:21:29',NULL,NULL),('TRX-1786703087846','user-1785927466185000','USR-002',NULL,'pickup','selesai','0000-00-00',NULL,NULL,NULL,4250,4250,NULL,'2026-08-14 10:24:48',NULL,NULL),('TRX-1786703855915','user-1785927466185000','USR-002','DP-001','drop_in','selesai','2026-08-14',NULL,NULL,NULL,2000,2000,NULL,'2026-08-14 10:37:36',NULL,NULL),('TRX-1789636376536','user-1789636320139','USR-002','DP-001','drop_in','selesai','2026-09-17',NULL,NULL,NULL,10750,10750,NULL,'2026-09-17 09:12:57',NULL,NULL),('TRX-1791772695246','user-1789636320139',NULL,'DP-001','drop_in','dikonfirmasi','2026-10-12',NULL,NULL,NULL,0,0,NULL,'2026-10-12 02:38:15',NULL,NULL),('TRX-1791772768285','user-1789636320139',NULL,NULL,'pickup','dikonfirmasi','0000-00-00',NULL,NULL,NULL,0,0,'tx_TRX-1791772768285_1791772769.png','2026-10-12 02:39:28',NULL,NULL),('TRX-TEST-001','USR-001',NULL,NULL,'drop_in','selesai',NULL,NULL,NULL,NULL,0,7500,NULL,'2026-08-07 09:22:27',NULL,NULL);
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `users` (
  `id` varchar(36) NOT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `profile_picture` varchar(255) DEFAULT NULL,
  `password` varchar(64) NOT NULL DEFAULT '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92',
  `full_name` varchar(100) NOT NULL,
  `role` enum('nasabah','petugas','admin','staf') NOT NULL DEFAULT 'nasabah',
  `address` text DEFAULT NULL,
  `default_setor_method` enum('drop_in','pickup','rvm','donasi') DEFAULT NULL,
  `point_balance` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_online` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `phone_number` (`phone_number`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('petugas-1785927406580000','085251151030','tokan557@gmail.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','akmal galon','petugas','Zona: Drop Point 03 - Wilayah Selatan, Armada: Truk / Mobil Box, Plat: b 1234 cg','pickup',41750,1,'2026-08-05 10:56:46',0),('petugas-1786604528843431','08120004372','afkar@gmail.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','afkar','petugas','Zona: Drop Point 02 - Wilayah Utara, Armada: Mobil Pick-up, Plat: DD 4523 AK',NULL,0,1,'2026-08-13 07:02:02',1),('user-1785927466185000',NULL,'muhakmal557@gmail.com','profile_user-1785927466185000_1786197185.jpg','$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','akmal galon le mineral','nasabah','jalan saptamarga','drop_in',98500,1,'2026-08-05 10:57:46',1),('user-1785976279071000',NULL,'shimada@gmail.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','shimada','nasabah','','drop_in',2000,1,'2026-08-06 00:31:19',0),('user-1786405934972','123123123','shimada@banksampah.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','shimada','admin','',NULL,0,1,'2026-08-10 23:52:15',0),('user-1786601421931367',NULL,'ahsan@gmail.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','accank','nasabah','',NULL,0,1,'2026-08-13 06:10:15',1),('user-1789262024802','0852555555','tokan@gmail.com',NULL,'7ecb4eaa652f6456f059b1543291f894dc28cfea85d9d6d5b92d18dd32c9b782','tokan','nasabah','',NULL,0,1,'2026-09-13 01:13:45',1),('user-1789636320139','19057105710975','user@banksampah.com',NULL,'8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92','user','nasabah','',NULL,10750,1,'2026-09-17 09:12:02',1),('USR-001','081234567890','admin@banksampah.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','Akmal Ahsan','admin','Kantor Pusat Bank Sampah',NULL,7500,1,'2026-08-05 10:09:24',1),('USR-002','081987654321','tokan@banksampah.com',NULL,'$2y$10$NBHgaVhYPT9UGNxa/Mp.iejI1IlipsAJrLyIC.gQ6p0/XYsvvnpFe','Tokan Shimada','petugas','Jl. Petugas No. 1',NULL,0,1,'2026-08-05 10:09:24',1);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `waste_categories`
--

DROP TABLE IF EXISTS `waste_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `waste_categories` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `point_per_kg` int(11) NOT NULL,
  `icon_url` text DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `waste_categories`
--

LOCK TABLES `waste_categories` WRITE;
/*!40000 ALTER TABLE `waste_categories` DISABLE KEYS */;
INSERT INTO `waste_categories` VALUES (1,'Plastik',2000,'icon_plastik.png',1),(2,'Kertas & Kardus',1500,'icon_kertas.png',1),(3,'Besi & Logam',3500,'icon_besi.png',1),(4,'Elektronik Bekas',5000,'icon_elektronik.png',1);
/*!40000 ALTER TABLE `waste_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `withdrawals`
--

DROP TABLE IF EXISTS `withdrawals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `withdrawals` (
  `id` varchar(36) NOT NULL,
  `nasabah_id` varchar(36) NOT NULL,
  `points_deducted` int(11) NOT NULL,
  `method` varchar(50) NOT NULL,
  `account_details` text NOT NULL,
  `status` varchar(20) NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `nasabah_id` (`nasabah_id`),
  CONSTRAINT `withdrawals_ibfk_1` FOREIGN KEY (`nasabah_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `withdrawals`
--

LOCK TABLES `withdrawals` WRITE;
/*!40000 ALTER TABLE `withdrawals` DISABLE KEYS */;
INSERT INTO `withdrawals` VALUES ('WD-1786189943-628','user-1785927466185000',100000,'Uang Tunai (Cash)','Detail menyusul','approved','2026-08-08 11:52:23'),('WD-1786189943-638','user-1785927466185000',100000,'Uang Tunai (Cash)','Detail menyusul','approved','2026-08-08 11:52:23'),('WD-1786190632-160','user-1785927466185000',1000,'DANA','Detail menyusul','approved','2026-08-08 12:03:52'),('WD-1786190728-490','user-1785927466185000',1000,'GoPay','Detail menyusul','rejected','2026-08-08 12:05:28'),('WD-1786616407-198','user-1785927466185000',18000,'tukar_barang','Gula Pasir 1 Kg (Titip Kurir)','approved','2026-08-13 10:20:07'),('WD-1786618730-137','user-1785927466185000',40000,'tukar_barang','Indomie Goreng (1 Dus) (Ambil di Kantor)','approved','2026-08-13 10:58:50'),('WD-1786618792-919','user-1785927466185000',40000,'tukar_barang','Indomie Goreng (1 Dus) (Ambil di Kantor)','approved','2026-08-13 10:59:52'),('WD-1786619531-123','user-1785927466185000',18000,'tukar_barang','Gula Pasir 1 Kg (Titip Kurir)','selesai','2026-08-13 11:12:11');
/*!40000 ALTER TABLE `withdrawals` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `worker_logs`
--

DROP TABLE IF EXISTS `worker_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `worker_logs` (
  `id` varchar(36) NOT NULL,
  `petugas_id` varchar(36) NOT NULL,
  `log_type` varchar(50) DEFAULT NULL,
  `location_lat` double DEFAULT NULL,
  `location_lng` double DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `petugas_id` (`petugas_id`),
  CONSTRAINT `worker_logs_ibfk_1` FOREIGN KEY (`petugas_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `worker_logs`
--

LOCK TABLES `worker_logs` WRITE;
/*!40000 ALTER TABLE `worker_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `worker_logs` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-14  8:09:50
