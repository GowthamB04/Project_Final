-- newone.sql
-- Database seed for Health Insurance Claim Management System
-- Based on d.sql and health_db_initialization.sql reference schemas

CREATE DATABASE IF NOT EXISTS health_db;
USE health_db;

-- Disable FK checks while dropping/creating
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS documents;
DROP TABLE IF EXISTS claims;
DROP TABLE IF EXISTS treatments;
DROP TABLE IF EXISTS doctors;
DROP TABLE IF EXISTS hospitals;
DROP TABLE IF EXISTS user_policies;
DROP TABLE IF EXISTS insurance_policies;
DROP TABLE IF EXISTS users;

SET FOREIGN_KEY_CHECKS=1;

-- ============================================
-- TABLE: users
-- ============================================
CREATE TABLE users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(200),
    email VARCHAR(200) UNIQUE,
    phone_number VARCHAR(30),
    date_of_birth DATE,
    address VARCHAR(255),
    role VARCHAR(50) NOT NULL,
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    bank_account_number VARCHAR(40),
    ifsc_code VARCHAR(20),
    bank_name VARCHAR(100),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    INDEX idx_username (username),
    INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: insurance_policies
-- ============================================
CREATE TABLE insurance_policies (
    policy_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    policy_number VARCHAR(50) UNIQUE NOT NULL,
    policy_name VARCHAR(200) NOT NULL,
    policy_type VARCHAR(50),
    coverage_amount DOUBLE NOT NULL DEFAULT 0,
    premium_amount DOUBLE NOT NULL DEFAULT 0,
    benefits TEXT,
    policy_status VARCHAR(20) NOT NULL DEFAULT 'INACTIVE',
    start_date DATE,
    end_date DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_policy_number (policy_number),
    INDEX idx_policy_status (policy_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: user_policies
-- ============================================
CREATE TABLE user_policies (
    user_policy_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    policy_id BIGINT NOT NULL,
    purchased_date DATE,
    expiry_date DATE,
    policy_active_status VARCHAR(20) DEFAULT 'ACTIVE',
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (policy_id) REFERENCES insurance_policies(policy_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_policy_id (policy_id),
    UNIQUE KEY unique_user_policy (user_id, policy_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: hospitals
-- ============================================
CREATE TABLE hospitals (
    hospital_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    hospital_name VARCHAR(200) NOT NULL,
    hospital_type VARCHAR(50),
    address VARCHAR(255),
    phone_number VARCHAR(30),
    INDEX idx_hospital_name (hospital_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: doctors
-- ============================================
CREATE TABLE doctors (
    doctor_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    doctor_name VARCHAR(100) NOT NULL,
    specialization VARCHAR(50) NOT NULL,
    qualification VARCHAR(50),
    experience_years INT,
    hospital_id BIGINT NOT NULL,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) ON DELETE CASCADE,
    INDEX idx_hospital_id (hospital_id),
    INDEX idx_specialization (specialization)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: treatments
-- ============================================
CREATE TABLE treatments (
    treatment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    diagnosis VARCHAR(200) NOT NULL,
    treatment_description TEXT,
    treatment_amount DOUBLE NOT NULL DEFAULT 0,
    treatment_date DATE,
    user_id BIGINT NOT NULL,
    doctor_id BIGINT,
    hospital_id BIGINT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctors(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (hospital_id) REFERENCES hospitals(hospital_id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_doctor_id (doctor_id),
    INDEX idx_hospital_id (hospital_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: claims
-- ============================================
CREATE TABLE claims (
    claim_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    claim_number VARCHAR(60) UNIQUE NOT NULL,
    claim_amount DOUBLE NOT NULL,
    approved_amount DOUBLE DEFAULT 0,
    claim_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    approver_comment TEXT,
    rejection_reason TEXT,
    recommendation_status VARCHAR(20),
    recommendation_reason TEXT,
    recommendation_score INT,
    claim_date DATE,
    approved_date DATE,
    rejected_date DATE,
    user_id BIGINT NOT NULL,
    treatment_id BIGINT NOT NULL,
    policy_id BIGINT NOT NULL,
    assigned_approver_id BIGINT,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (treatment_id) REFERENCES treatments(treatment_id) ON DELETE CASCADE,
    FOREIGN KEY (policy_id) REFERENCES insurance_policies(policy_id) ON DELETE CASCADE,
    FOREIGN KEY (assigned_approver_id) REFERENCES users(user_id),
    INDEX idx_claim_number (claim_number),
    INDEX idx_user_id (user_id),
    INDEX idx_claim_status (claim_status),
    INDEX idx_approver_id (assigned_approver_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: documents
-- ============================================
CREATE TABLE documents (
    document_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    document_name VARCHAR(200) NOT NULL,
    document_type VARCHAR(100),
    document_path VARCHAR(255),
    uploaded_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    claim_id BIGINT NOT NULL,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
    INDEX idx_claim_id (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- TABLE: payments
-- ============================================
CREATE TABLE payments (
    payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_amount DOUBLE NOT NULL,
    payment_date DATE,
    payment_mode VARCHAR(50),
    transaction_id VARCHAR(100),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    company_account_number VARCHAR(40),
    company_bank_name VARCHAR(200),
    claim_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    INDEX idx_claim_id (claim_id),
    INDEX idx_user_id (user_id),
    UNIQUE KEY unique_claim_payment (claim_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================
-- INSERT SAMPLE DATA (15 users)
-- 1 admin, 2 approvers, 10 policyholders, 2 misc users
-- Passwords use bcrypt-like placeholders to match initialization style

INSERT INTO users (username, password, full_name, email, phone_number, date_of_birth, address, role, account_status, bank_account_number, ifsc_code, bank_name, created_at)
VALUES
('administrator', '$2a$12$GqS4yfRrKjOZ.Sts3Ydd7.ngD.XUO.gX4xvfYXVhGMiX7/j7XGNrm', 'System Administrator', 'admin@example.com','9000000001','1980-01-01','Admin Office','ADMIN','ACTIVE',NULL,NULL,NULL,NOW()),
('Approver_01', '$2a$12$edUxPIHUfImLJXFEZoiWiuiAWAje397lss7imcK/uqfsh9Fx5jUIC','Approver One','approver1@example.com','9000000002','1979-02-02','Approver Address','APPROVER','ACTIVE',NULL,NULL,NULL,NOW()),
('Approver_02', '$2a$12$edUxPIHUfImLJXFEZoiWiuiAWAje397lss7imcK/uqfsh9Fx5jUIC','Approver Two','approver2@example.com','9000000003','1978-03-03','Approver Address','APPROVER','ACTIVE',NULL,NULL,NULL,NOW()),

('Draven23', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Draven','draven23@example.com','9000000010','1985-05-12','1 River St','POLICYHOLDER','ACTIVE','1234567890123456','ICIC0000001','ICICI Bank',NOW()),
('Gowtham40', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Gowtham','gowtham40@example.com','9000000011','1984-06-06','2 Park Ave','POLICYHOLDER','ACTIVE','2345678901234567','HDFC0000002','HDFC Bank',NOW()),
('angel67', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Angel','angel67@example.com','9000000012','1990-07-07','3 Market Rd','POLICYHOLDER','ACTIVE','3456789012345678','AXAX0000003','Axis Bank',NOW()),
('banu12', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Banu','banu12@example.com','9000000013','1991-08-08','4 Garden Ln','POLICYHOLDER','ACTIVE','4567890123456789','SBIN0000004','State Bank',NOW()),
('Sivaranjeni89', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Sivaranjeni','sivaranjeni89@example.com','9000000014','1992-09-09','5 Hill Top','POLICYHOLDER','ACTIVE','5678901234567890','NDSE0000005','NDSE Bank',NOW()),
('Karthik92', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Karthik','karthik92@example.com','9000000015','1980-10-10','6 Lake Side','POLICYHOLDER','ACTIVE','6789012345678901','IDIB0000006','IDBI Bank',NOW()),
('Priya95', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Priya','priya95@example.com','9000000016','1986-11-11','7 River Rd','POLICYHOLDER','ACTIVE','7890123456789012','BOBI0000007','BoB',NOW()),
('Ramesh85', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Ramesh','ramesh85@example.com','9000000017','1975-12-12','8 Valley St','POLICYHOLDER','ACTIVE','8901234567890123','KKBK0000008','Kotak Bank',NOW()),
('Neha90', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Neha','neha90@example.com','9000000018','1993-01-01','9 Forest Ln','POLICYHOLDER','ACTIVE','9012345678901234','AUBL0000009','Aurora Bank',NOW()),
('Arjun00', '$2a$12$05qSDPjY7feEIVFPB4Alx.c7WMgid/ECWEvR2pBRBo3QlVssGpz2i','Arjun','arjun00@example.com','9000000019','1994-02-02','10 Sunset Blvd','POLICYHOLDER','ACTIVE','0123456789012345','FDRL0000010','Federal Bank',NOW()),

-- Two extra generic users
('viewer01', '$2a$12$ZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzz','Viewer One','viewer01@example.com','9000000020','1998-03-03','11 Read St','USER','ACTIVE',NULL,NULL,NULL,NOW()),
('support01', '$2a$12$ZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzZzzz','Support Agent','support01@example.com','9000000021','1989-04-04','12 Help Ave','USER','ACTIVE',NULL,NULL,NULL,NOW());

-- ============================================
-- INSERT SAMPLE DATA - INSURANCE POLICIES (14)
-- ============================================
INSERT INTO insurance_policies (policy_number, policy_name, policy_type, coverage_amount, premium_amount, benefits, policy_status, start_date, end_date, created_at)
VALUES
('P-1001','Health Basic Plan A','Individual',500000,4500,'Basic hospital + OPD','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1002','Health Extra Plan A','Individual',1000000,9000,'Extended surgery cover','INACTIVE','2020-01-01','2022-12-31',NOW()),
('P-1003','Health Basic Plan B','Individual',400000,3500,'Basic hospital cover','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1004','Health Extra Plan B','Individual',800000,8000,'Extended cover old','INACTIVE','2019-01-01','2021-12-31',NOW()),
('P-1005','Family Care A','Family',600000,4800,'Family cover','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1006','Family Care A - Old','Family',600000,4800,'Old plan','INACTIVE','2018-01-01','2020-12-31',NOW()),
('P-1007','Senior Shield','Individual',700000,5600,'Senior care','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1008','Senior Shield - Old','Individual',700000,5600,'Old senior plan','INACTIVE','2021-01-01','2023-12-31',NOW()),
('P-1009','Young Star','Individual',300000,2500,'Young adult plan','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1010','Young Star - Old','Individual',300000,2500,'Old young plan','INACTIVE','2017-01-01','2019-12-31',NOW()),
('P-1011','Comprehensive Plus','Family',900000,8500,'Comprehensive family cover','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1012','Standard Cover','Individual',450000,3900,'Standard cover','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1013','Essential Cover','Individual',350000,3000,'Essential services','ACTIVE','2025-01-01','2027-12-31',NOW()),
('P-1014','Starter Health','Individual',200000,1500,'Entry level','ACTIVE','2025-01-01','2027-12-31',NOW());

-- ============================================
-- Map policies to users (user_policies)
-- First five policyholders get two policies each (one active, one inactive)
-- Remaining five get one active policy each
-- Users inserted earlier: admin=1, Approver_01=2, Approver_02=3, Draven23=4, ... Arjun00=13, viewer01=14, support01=15
-- ============================================
INSERT INTO user_policies (user_id, policy_id, purchased_date, expiry_date, policy_active_status) VALUES
(4,1,'2025-02-10','2027-12-31','ACTIVE'),
(4,2,'2020-03-05','2022-12-31','INACTIVE'),
(5,3,'2025-04-01','2027-12-31','ACTIVE'),
(5,4,'2019-06-15','2021-12-31','INACTIVE'),
(6,5,'2025-05-20','2027-12-31','ACTIVE'),
(6,6,'2018-09-10','2020-12-31','INACTIVE'),
(7,7,'2025-03-11','2027-12-31','ACTIVE'),
(7,8,'2021-02-21','2023-12-31','INACTIVE'),
(8,9,'2025-07-07','2027-12-31','ACTIVE'),
(8,10,'2017-11-30','2019-12-31','INACTIVE'),
(9,11,'2025-01-15','2027-12-31','ACTIVE'),
(10,12,'2025-06-01','2027-12-31','ACTIVE'),
(11,13,'2025-08-18','2027-12-31','ACTIVE'),
(12,14,'2025-09-01','2027-12-31','ACTIVE'),
(13,11,'2025-10-05','2027-12-31','ACTIVE');

-- ============================================
-- Insert hospitals and doctors (minimal set used by treatments)
-- ============================================
INSERT INTO hospitals (hospital_name, hospital_type, address, phone_number) VALUES
('Apollo Hospitals','Private','100 Health St','9111111111'),
('Fortis Healthcare','Private','200 Medical Plaza','9122222222'),
('Max Healthcare','Private','300 Care Ave','9133333333');

INSERT INTO doctors (doctor_name, specialization, qualification, experience_years, hospital_id) VALUES
('Dr. Rajesh Kumar','Cardiology','MD',15,1),
('Dr. Priya Sharma','Orthopedics','MBBS',10,1),
('Dr. Amit Singh','Neurology','MD',12,2),
('Dr. Neha Gupta','Gastroenterology','MD',8,2),
('Dr. Vikram Patel','Oncology','MD',18,3);

-- ============================================
-- Insert treatments for 10 policyholders (one per policyholder)
-- treatment_id will start at 1 and map to claims below
-- ============================================
INSERT INTO treatments (diagnosis, treatment_description, treatment_amount, treatment_date, user_id, doctor_id, hospital_id) VALUES
('Appendectomy','Appendix removal surgery',80000,'2025-03-01',4,3,2),
('Knee Replacement','Joint replacement surgery',150000,'2025-05-10',5,2,1),
('Chemotherapy','Cancer treatment',250000,'2025-09-12',6,5,3),
('Cardiac Bypass','Bypass surgery',400000,'2025-04-20',7,1,1),
('Fracture Fixation','Orthopedic surgery',120000,'2025-12-05',8,2,2),
('General Surgery','General operation',20000,'2025-07-01',9,4,2),
('ENT Procedure','ENT surgery',30000,'2025-10-10',10,4,3),
('Minor Procedure','Outpatient procedure',5000,'2025-11-11',11,5,3),
('Cardiac Check','Cardiology treatment',22000,'2025-08-08',12,1,1),
('Transplant Related','Special procedure',75000,'2025-02-22',13,5,3);

-- ============================================
-- Create 20 claims: each of the 10 policyholders creates 2 claims (20 total)
-- Status distribution: 10 SETTLED, 6 PENDING, 4 REJECTED
-- We'll reference treatments 1..10 for the first claim of each user and reuse for second where appropriate
-- ============================================
INSERT INTO claims (claim_number, claim_amount, approved_amount, claim_status, approver_comment, rejection_reason, recommendation_status, recommendation_reason, recommendation_score, claim_date, approved_date, user_id, treatment_id, policy_id, assigned_approver_id)
VALUES
('C-1001',120000,120000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-03-01','2025-03-10',4,1,1,2),
('C-1002',60000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-02-14',NULL,4,1,1,NULL),
('C-1003',45000,45000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-05-10','2025-05-20',5,2,3,3),
('C-1004',30000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-06-20',NULL,5,2,3,NULL),
('C-1005',250000,250000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-09-12','2025-09-20',6,3,5,2),
('C-1006',80000,0,'REJECTED',NULL,'Treatment not covered','','Insufficient cover',50,'2026-11-02',NULL,6,3,5,3),
('C-1007',150000,150000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-04-20','2025-05-01',7,4,7,3),
('C-1008',50000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-08-08',NULL,7,4,7,NULL),
('C-1009',90000,90000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-12-05','2025-12-15',8,5,9,2),
('C-1010',40000,0,'REJECTED',NULL,'Policy lapsed','','Policy expired',30,'2026-03-18',NULL,8,5,9,3),
('C-1011',200000,200000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-07-01','2025-07-10',9,6,11,2),
('C-1012',45000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-01-21',NULL,9,6,11,NULL),
('C-1013',30000,30000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-10-10','2025-10-20',10,7,12,3),
('C-1014',25000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-04-14',NULL,10,7,12,NULL),
('C-1015',50000,50000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-11-11','2025-11-20',11,8,13,2),
('C-1016',60000,0,'REJECTED',NULL,'Document insufficient','','Missing docs',20,'2026-09-09',NULL,11,8,13,3),
('C-1017',22000,22000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-08-08','2025-08-20',12,9,14,2),
('C-1018',18000,0,'PENDING',NULL,NULL,NULL,NULL,NULL,'2026-05-05',NULL,12,9,14,NULL),
('C-1019',75000,75000,'SETTLED','Approved','', 'APPROVE','Docs OK',100,'2025-02-22','2025-03-05',13,10,11,3),
('C-1020',33000,0,'REJECTED',NULL,'Not covered','','Not in policy',10,'2026-12-12',NULL,13,10,11,2);

-- ============================================
-- Create payments for the 10 SETTLED claims (claim_ids will be 1,3,5,7,9,11,13,15,17,19)
-- ============================================
INSERT INTO payments (payment_amount, payment_date, payment_mode, transaction_id, payment_status, company_account_number, company_bank_name, claim_id, user_id) VALUES
(120000,'2025-03-10','Bank Transfer','TXN1001','COMPLETED','1111222233334444','ICICI Bank',1,4),
(45000,'2025-05-20','Bank Transfer','TXN1002','COMPLETED','1111222233334444','ICICI Bank',3,5),
(250000,'2025-09-20','NEFT','TXN1003','COMPLETED','1111222233334444','ICICI Bank',5,6),
(150000,'2025-05-01','NEFT','TXN1004','COMPLETED','1111222233334444','ICICI Bank',7,7),
(90000,'2025-12-15','Bank Transfer','TXN1005','COMPLETED','1111222233334444','ICICI Bank',9,8),
(200000,'2025-07-10','Bank Transfer','TXN1006','COMPLETED','1111222233334444','ICICI Bank',11,9),
(30000,'2025-10-20','NEFT','TXN1007','COMPLETED','1111222233334444','ICICI Bank',13,10),
(50000,'2025-11-20','Bank Transfer','TXN1008','COMPLETED','1111222233334444','ICICI Bank',15,11),
(22000,'2025-08-20','NEFT','TXN1009','COMPLETED','1111222233334444','ICICI Bank',17,12),
(75000,'2025-03-05','Bank Transfer','TXN1010','COMPLETED','1111222233334444','ICICI Bank',19,13);

-- ============================================
-- Insert documents for each claim
-- Each claim request includes four required documents:
-- medical bill, prescription, treatment bill, hospital bill
-- ============================================
INSERT INTO documents (document_name, document_type, document_path, claim_id) VALUES
('MedicalBill_C1001.pdf','Medical Bill','/docs/C-1001/MedicalBill.pdf',1),
('Prescription_C1001.pdf','Prescription','/docs/C-1001/Prescription.pdf',1),
('TreatmentBill_C1001.pdf','Treatment Bill','/docs/C-1001/TreatmentBill.pdf',1),
('HospitalBill_C1001.pdf','Hospital Bill','/docs/C-1001/HospitalBill.pdf',1),
('MedicalBill_C1002.pdf','Medical Bill','/docs/C-1002/MedicalBill.pdf',2),
('Prescription_C1002.pdf','Prescription','/docs/C-1002/Prescription.pdf',2),
('TreatmentBill_C1002.pdf','Treatment Bill','/docs/C-1002/TreatmentBill.pdf',2),
('HospitalBill_C1002.pdf','Hospital Bill','/docs/C-1002/HospitalBill.pdf',2),
('MedicalBill_C1003.pdf','Medical Bill','/docs/C-1003/MedicalBill.pdf',3),
('Prescription_C1003.pdf','Prescription','/docs/C-1003/Prescription.pdf',3),
('TreatmentBill_C1003.pdf','Treatment Bill','/docs/C-1003/TreatmentBill.pdf',3),
('HospitalBill_C1003.pdf','Hospital Bill','/docs/C-1003/HospitalBill.pdf',3),
('MedicalBill_C1004.pdf','Medical Bill','/docs/C-1004/MedicalBill.pdf',4),
('Prescription_C1004.pdf','Prescription','/docs/C-1004/Prescription.pdf',4),
('TreatmentBill_C1004.pdf','Treatment Bill','/docs/C-1004/TreatmentBill.pdf',4),
('HospitalBill_C1004.pdf','Hospital Bill','/docs/C-1004/HospitalBill.pdf',4),
('MedicalBill_C1005.pdf','Medical Bill','/docs/C-1005/MedicalBill.pdf',5),
('Prescription_C1005.pdf','Prescription','/docs/C-1005/Prescription.pdf',5),
('TreatmentBill_C1005.pdf','Treatment Bill','/docs/C-1005/TreatmentBill.pdf',5),
('HospitalBill_C1005.pdf','Hospital Bill','/docs/C-1005/HospitalBill.pdf',5),
('MedicalBill_C1006.pdf','Medical Bill','/docs/C-1006/MedicalBill.pdf',6),
('Prescription_C1006.pdf','Prescription','/docs/C-1006/Prescription.pdf',6),
('TreatmentBill_C1006.pdf','Treatment Bill','/docs/C-1006/TreatmentBill.pdf',6),
('HospitalBill_C1006.pdf','Hospital Bill','/docs/C-1006/HospitalBill.pdf',6),
('MedicalBill_C1007.pdf','Medical Bill','/docs/C-1007/MedicalBill.pdf',7),
('Prescription_C1007.pdf','Prescription','/docs/C-1007/Prescription.pdf',7),
('TreatmentBill_C1007.pdf','Treatment Bill','/docs/C-1007/TreatmentBill.pdf',7),
('HospitalBill_C1007.pdf','Hospital Bill','/docs/C-1007/HospitalBill.pdf',7),
('MedicalBill_C1008.pdf','Medical Bill','/docs/C-1008/MedicalBill.pdf',8),
('Prescription_C1008.pdf','Prescription','/docs/C-1008/Prescription.pdf',8),
('TreatmentBill_C1008.pdf','Treatment Bill','/docs/C-1008/TreatmentBill.pdf',8),
('HospitalBill_C1008.pdf','Hospital Bill','/docs/C-1008/HospitalBill.pdf',8),
('MedicalBill_C1009.pdf','Medical Bill','/docs/C-1009/MedicalBill.pdf',9),
('Prescription_C1009.pdf','Prescription','/docs/C-1009/Prescription.pdf',9),
('TreatmentBill_C1009.pdf','Treatment Bill','/docs/C-1009/TreatmentBill.pdf',9),
('HospitalBill_C1009.pdf','Hospital Bill','/docs/C-1009/HospitalBill.pdf',9),
('MedicalBill_C1010.pdf','Medical Bill','/docs/C-1010/MedicalBill.pdf',10),
('Prescription_C1010.pdf','Prescription','/docs/C-1010/Prescription.pdf',10),
('TreatmentBill_C1010.pdf','Treatment Bill','/docs/C-1010/TreatmentBill.pdf',10),
('HospitalBill_C1010.pdf','Hospital Bill','/docs/C-1010/HospitalBill.pdf',10),
('MedicalBill_C1011.pdf','Medical Bill','/docs/C-1011/MedicalBill.pdf',11),
('Prescription_C1011.pdf','Prescription','/docs/C-1011/Prescription.pdf',11),
('TreatmentBill_C1011.pdf','Treatment Bill','/docs/C-1011/TreatmentBill.pdf',11),
('HospitalBill_C1011.pdf','Hospital Bill','/docs/C-1011/HospitalBill.pdf',11),
('MedicalBill_C1012.pdf','Medical Bill','/docs/C-1012/MedicalBill.pdf',12),
('Prescription_C1012.pdf','Prescription','/docs/C-1012/Prescription.pdf',12),
('TreatmentBill_C1012.pdf','Treatment Bill','/docs/C-1012/TreatmentBill.pdf',12),
('HospitalBill_C1012.pdf','Hospital Bill','/docs/C-1012/HospitalBill.pdf',12),
('MedicalBill_C1013.pdf','Medical Bill','/docs/C-1013/MedicalBill.pdf',13),
('Prescription_C1013.pdf','Prescription','/docs/C-1013/Prescription.pdf',13),
('TreatmentBill_C1013.pdf','Treatment Bill','/docs/C-1013/TreatmentBill.pdf',13),
('HospitalBill_C1013.pdf','Hospital Bill','/docs/C-1013/HospitalBill.pdf',13),
('MedicalBill_C1014.pdf','Medical Bill','/docs/C-1014/MedicalBill.pdf',14),
('Prescription_C1014.pdf','Prescription','/docs/C-1014/Prescription.pdf',14),
('TreatmentBill_C1014.pdf','Treatment Bill','/docs/C-1014/TreatmentBill.pdf',14),
('HospitalBill_C1014.pdf','Hospital Bill','/docs/C-1014/HospitalBill.pdf',14),
('MedicalBill_C1015.pdf','Medical Bill','/docs/C-1015/MedicalBill.pdf',15),
('Prescription_C1015.pdf','Prescription','/docs/C-1015/Prescription.pdf',15),
('TreatmentBill_C1015.pdf','Treatment Bill','/docs/C-1015/TreatmentBill.pdf',15),
('HospitalBill_C1015.pdf','Hospital Bill','/docs/C-1015/HospitalBill.pdf',15),
('MedicalBill_C1016.pdf','Medical Bill','/docs/C-1016/MedicalBill.pdf',16),
('Prescription_C1016.pdf','Prescription','/docs/C-1016/Prescription.pdf',16),
('TreatmentBill_C1016.pdf','Treatment Bill','/docs/C-1016/TreatmentBill.pdf',16),
('HospitalBill_C1016.pdf','Hospital Bill','/docs/C-1016/HospitalBill.pdf',16),
('MedicalBill_C1017.pdf','Medical Bill','/docs/C-1017/MedicalBill.pdf',17),
('Prescription_C1017.pdf','Prescription','/docs/C-1017/Prescription.pdf',17),
('TreatmentBill_C1017.pdf','Treatment Bill','/docs/C-1017/TreatmentBill.pdf',17),
('HospitalBill_C1017.pdf','Hospital Bill','/docs/C-1017/HospitalBill.pdf',17),
('MedicalBill_C1018.pdf','Medical Bill','/docs/C-1018/MedicalBill.pdf',18),
('Prescription_C1018.pdf','Prescription','/docs/C-1018/Prescription.pdf',18),
('TreatmentBill_C1018.pdf','Treatment Bill','/docs/C-1018/TreatmentBill.pdf',18),
('HospitalBill_C1018.pdf','Hospital Bill','/docs/C-1018/HospitalBill.pdf',18),
('MedicalBill_C1019.pdf','Medical Bill','/docs/C-1019/MedicalBill.pdf',19),
('Prescription_C1019.pdf','Prescription','/docs/C-1019/Prescription.pdf',19),
('TreatmentBill_C1019.pdf','Treatment Bill','/docs/C-1019/TreatmentBill.pdf',19),
('HospitalBill_C1019.pdf','Hospital Bill','/docs/C-1019/HospitalBill.pdf',19),
('MedicalBill_C1020.pdf','Medical Bill','/docs/C-1020/MedicalBill.pdf',20),
('Prescription_C1020.pdf','Prescription','/docs/C-1020/Prescription.pdf',20),
('TreatmentBill_C1020.pdf','Treatment Bill','/docs/C-1020/TreatmentBill.pdf',20),
('HospitalBill_C1020.pdf','Hospital Bill','/docs/C-1020/HospitalBill.pdf',20);

-- Done. newone.sql now follows the reference schema and contains the requested records.
