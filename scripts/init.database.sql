/*
===========================================================
Create database and schema
===========================================================
Script purpose
  This script creates a new database named as 'Data Warehouse' after checking if it already exists
  if the database exsits, it is dropped and recreated, Additionally, the script set up three schemas
  within the database: 'bronze', 'sliver', 'gold'.

WARNING:
  Running this script wil drop the entire 'Datawarehouse' database if it exists.
  ALL data in the database will be permanently deleted. Proceed wit caution
  and ensure you have proper backups before running this script,
*/

USE master;
GO

--Drop and recreate the 'datawarehouse' database--
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'datawarehouse')
BEGIN
  ALTER database 'datawarehouse' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
  DROP DATABASE datawarehouse;
END:
GO

--Create datawarehouse--
CREATE DATABASE DataWAREHOUSE;
GO

USE DataWAREHOUSE;
GO

-- Create database schemas--
CREATE SCHEMA bronze;
GO
  
CREATE SCHEMA sliver;
GO
  
CREATE SCHEMA gold;

