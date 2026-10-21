-- HUMANITARIAN PROGRAMME DATA ANALYSIS 
-- This is a new final submission file; it does not overwrite earlier practice code.

CREATE DATABASE IF NOT EXISTS humanitarian_program;
USE humanitarian_program;

-- DATABASE SETUP
-- Create village_locations first because it is referenced by beneficiary_partner_data.
CREATE TABLE IF NOT EXISTS village_locations (
    village_id INT PRIMARY KEY,
    village VARCHAR(30) NOT NULL UNIQUE,
    latitude VARCHAR(30),
    longitude VARCHAR(30),
    total_population INT NOT NULL
);

CREATE TABLE IF NOT EXISTS jurisdiction_hierarchy (
    id INT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    type VARCHAR(20) NOT NULL,
    parent_id INT NULL,
    FOREIGN KEY (parent_id) REFERENCES jurisdiction_hierarchy(id)
);

CREATE TABLE IF NOT EXISTS beneficiary_partner_data (
    partner_id INT PRIMARY KEY,
    partner VARCHAR(30) NOT NULL,
    village VARCHAR(30) NOT NULL,
    beneficiaries INT NOT NULL,
    beneficiary_type VARCHAR(30) NOT NULL,
    FOREIGN KEY (village) REFERENCES village_locations(village)
);

-- SAMPLE DATA: VILLAGE LOCATIONS
INSERT INTO village_locations
(village_id, village, latitude, longitude, total_population)
VALUES
(1,'Dharkenley','2.0469','45.3182',5000),
(2,'Bulo-Kahin','2.0560','45.3250',4200),
(3,'Hilo Kelyo','2.0650','45.3300',3800),
(4,'Xubow','2.1000','45.3500',6000),
(5,'Xiintooy','2.1100','45.3600',4500),
(6,'Dhagax Jebis','2.1200','45.3700',5200),
(7,'Filtare','2.1300','45.3800',3900),
(8,'Howl-Wadaag','2.1400','45.3900',4700),
(9,'Balcad','2.1500','45.4000',5500),
(10,'Mareeray','2.1600','45.4100',4300),
(11,'Kulmis','2.1700','45.4200',6058),
(12,'Sabuun','2.1800','45.4300',5100),
(13,'Bayaxaw','2.1900','45.4400',3600),
(14,'Bayaxawo','2.2000','45.4500',4000)
ON DUPLICATE KEY UPDATE village=VALUES(village), latitude=VALUES(latitude),
longitude=VALUES(longitude), total_population=VALUES(total_population);

-- SAMPLE DATA: JURISDICTION HIERARCHY
INSERT INTO jurisdiction_hierarchy (id,name,type,parent_id) VALUES
(1,'Middle Shabelle','Region',NULL),
(2,'Hiraan','Region',NULL),
(3,'Balcad','District',1),
(4,'Jowhar','District',1),
(5,'Beledweyn','District',2),
(6,'Dharkenley','Village',3),
(7,'Bulo-Kahin','Village',3),
(8,'Hilo Kelyo','Village',3),
(9,'Xubow','Village',4),
(10,'Xiintooy','Village',4),
(11,'Dhagax Jebis','Village',4),
(12,'Filtare','Village',4),
(13,'Howl-Wadaag','Village',4),
(14,'Balcad','Village',4),
(15,'Mareeray','Village',4),
(16,'Kulmis','Village',4),
(17,'Sabuun','Village',4),
(18,'Bayaxaw','Village',4),
(19,'Bayaxawo','Village',4)
ON DUPLICATE KEY UPDATE name=VALUES(name), type=VALUES(type), parent_id=VALUES(parent_id);

-- BENEFICIARY PARTNER DATA
INSERT INTO beneficiary_partner_data
(partner_id,partner,village,beneficiaries,beneficiary_type)
VALUES
(1,'World Vision','Dharkenley',1200,'Individuals'),
(2,'World Vision','Bulo-Kahin',350,'Households'),
(3,'CARE','Dharkenley',800,'Individuals'),
(4,'CARE','Hilo Kelyo',250,'Households'),
(5,'IRC','Xubow',1500,'Individuals'),
(6,'IRC','Xiintooy',300,'Households'),
(7,'World Vision','Dhagax Jebis',900,'Individuals'),
(8,'CARE','Filtare',450,'Households'),
(9,'IRC','Howl-Wadaag',1100,'Individuals'),
(10,'World Vision','Balcad',700,'Households'),
(11,'CARE','Mareeray',600,'Individuals'),
(12,'IRC','Kulmis',400,'Households'),
(13,'World Vision','Sabuun',1000,'Individuals'),
(14,'CARE','Bayaxaw',500,'Households'),
(15,'IRC','Bayaxawo',1300,'Individuals'),
(16,'World Vision','Dharkenley',700,'Households'),
(17,'CARE','Bulo-Kahin',550,'Individuals'),
(18,'IRC','Hilo Kelyo',900,'Individuals')
ON DUPLICATE KEY UPDATE partner=VALUES(partner), village=VALUES(village),
beneficiaries=VALUES(beneficiaries), beneficiary_type=VALUES(beneficiary_type);

-- TASK 1: EXPLORE THE DATA
-- 1A: Display all records from each table.
SELECT * FROM beneficiary_partner_data;
SELECT * FROM village_locations;
SELECT * FROM jurisdiction_hierarchy;

-- 1B: Display partner, village, and beneficiaries.
SELECT partner, village, beneficiaries FROM beneficiary_partner_data;

-- 1C: Find villages with population greater than 4,500.
SELECT village, total_population
FROM village_locations
WHERE total_population > 4500
ORDER BY total_population DESC;

-- 1D: Find records where beneficiary type is Households.
SELECT * FROM beneficiary_partner_data
WHERE beneficiary_type = 'Households';

-- TASK 2: CONVERT BENEFICIARY COUNTS
-- Households represent an estimated 6 individuals per household.
SELECT partner, village, beneficiaries, beneficiary_type,
       CASE
           WHEN beneficiary_type = 'Individuals' THEN beneficiaries
           WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
           ELSE 0
       END AS individual_beneficiaries
FROM beneficiary_partner_data;

-- TASK 3: PARTNER ANALYSIS
SELECT partner,
       SUM(CASE
               WHEN beneficiary_type = 'Individuals' THEN beneficiaries
               WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
               ELSE 0
           END) AS total_individual_beneficiaries,
       COUNT(DISTINCT village) AS distinct_villages_served,
       AVG(CASE
               WHEN beneficiary_type = 'Individuals' THEN beneficiaries
               WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
               ELSE 0
           END) AS average_individual_beneficiaries_per_record
FROM beneficiary_partner_data
GROUP BY partner
ORDER BY total_individual_beneficiaries DESC;

-- TASK 4: VILLAGE COVERAGE
SELECT bpd.partner, vl.village,
       CASE
           WHEN bpd.beneficiary_type = 'Individuals' THEN bpd.beneficiaries
           WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
           ELSE 0
       END AS individual_beneficiaries,
       vl.total_population AS village_population,
       ROUND(
           (CASE
                WHEN bpd.beneficiary_type = 'Individuals' THEN bpd.beneficiaries
                WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
                ELSE 0
            END) / NULLIF(vl.total_population, 0) * 100, 2
       ) AS coverage_percent
FROM beneficiary_partner_data AS bpd
JOIN village_locations AS vl ON bpd.village = vl.village
ORDER BY vl.village, bpd.partner;

-- TASK 5: ADD DISTRICT INFORMATION
SELECT bpd.partner, bpd.village, district.name AS district,
       CASE
           WHEN bpd.beneficiary_type = 'Individuals' THEN bpd.beneficiaries
           WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
           ELSE 0
       END AS individual_beneficiaries
FROM beneficiary_partner_data AS bpd
JOIN jurisdiction_hierarchy AS village_node
  ON village_node.name = bpd.village AND village_node.type = 'Village'
JOIN jurisdiction_hierarchy AS district
  ON village_node.parent_id = district.id AND district.type = 'District'
ORDER BY district.name, bpd.village, bpd.partner;

-- TASK 6: MULTIPLE-PARTNER VILLAGES
SELECT village, COUNT(DISTINCT partner) AS number_of_distinct_partners
FROM beneficiary_partner_data
GROUP BY village
HAVING COUNT(DISTINCT partner) > 1
ORDER BY number_of_distinct_partners DESC, village;

-- TASK 7: CREATE SUMMARY TABLES
-- Drop only these output tables so the summary tables can be rebuilt.
DROP TABLE IF EXISTS Partner_summary;




CREATE TABLE Partner_summary AS
SELECT partner AS Partner,
       SUM(CASE
               WHEN beneficiary_type = 'Individuals' THEN beneficiaries
               WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
               ELSE 0
           END) AS `Total beneficiaries`,
       COUNT(DISTINCT village) AS `Villages served`,
       CAST(
           AVG(CASE
                   WHEN beneficiary_type = 'Individuals' THEN beneficiaries
                   WHEN beneficiary_type = 'Households' THEN beneficiaries * 6
                   ELSE 0
               END) AS DECIMAL(12,2)
       ) AS `Average beneficiaries`
FROM beneficiary_partner_data
GROUP BY partner;

-- Recreate the district summary table.
DROP TABLE IF EXISTS District_summary;

CREATE TABLE District_summary AS
SELECT district.name AS District,
       SUM(CASE
               WHEN bpd.beneficiary_type = 'Individuals' THEN bpd.beneficiaries
               WHEN bpd.beneficiary_type = 'Households' THEN bpd.beneficiaries * 6
               ELSE 0
           END) AS `Total individual beneficiaries`,
       COUNT(DISTINCT village_node.name) AS `Number of villages served`
FROM beneficiary_partner_data AS bpd
JOIN jurisdiction_hierarchy AS village_node
  ON village_node.name = bpd.village AND village_node.type = 'Village'
JOIN jurisdiction_hierarchy AS district
  ON village_node.parent_id = district.id AND district.type = 'District'
GROUP BY district.name;

-- Check the completed summary tables.
SELECT * FROM Partner_summary ORDER BY `Total beneficiaries` DESC;
SELECT * FROM District_summary ORDER BY `Total individual beneficiaries` DESC;
