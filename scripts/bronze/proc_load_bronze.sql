/*
=====================================================================
Storage procedure : Load bronze layer (souce-> bronze)
======================================================================
Script Purpose:
  This store procedure loads data into the 'bronze' scema from external csv file.
  it performs the following actions:
  - Turncate the bronze table before loading data
  - Uses the BULK INSERT command to load data from csv files to bronze tables.

Parameters
   None;
   this store produrce does not acept any parameters or return any value.

Usage Example:
EXEC EXEC bronze.load_bronze 
========================================================================tdxc
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_Time Datetime, @end_Time Datetime, @batch_start_time Datetime, @batch_end_time Datetime;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================';
		PRINT 'Loading Bronze Layer';
		PRINT '===================================';

		PRINT'-------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT'-------------------------------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info
		PRINT '>> INSERT Data INTO: bronze.crm_cust_info';
		BULK INSERT bronze.crm_cust_info
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.crm_prd_info';
		TRUNCATE TABLE bronze.crm_prd_info
		PRINT '>> INSERT Data INTO: bronze.crm_prd_info';
		BULK INSERT bronze.crm_prd_info
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details
		PRINT '>> INSERT Data INTO: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);

		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		PRINT'-------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT'-------------------------------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.erp_cust_az12';
		TRUNCATE TABLE bronze.erp_cust_az12;
			PRINT '>> INSERT Data INTO: bronze.erp_cust_az12';
		BULK INSERT bronze.erp_cust_az12
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_erp\cust_az12.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.erp_loc_a101';
		TRUNCATE TABLE bronze.erp_loc_a101;
		PRINT '>> INSERT Data INTO: bronze.erp_loc_a101';
		BULK INSERT bronze.erp_loc_a101
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_erp\loc_a101.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @start_Time = GETDATE();
		PRINT '>> Truncating table : bronze.erp_px_cat_g1v2';
		TRUNCATE TABLE bronze.erp_px_cat_g1v2;
		PRINT '>> INSERT Data INTO: bronze.erp_px_cat_g1v2';
		BULK INSERT bronze.erp_px_cat_g1v2
		From 'C:\Program Files\Microsoft SQL Server\dwh\sql-data-warehouse-project\datasets\source_erp\px_cat_g1v2.csv'
		WITH(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @batch_end_time = GETDATE();

		PRINT'======================================='
		PRINT 'Loading bronze laye is completed';
		PRINT '- total Load duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
		PRINT'======================================='
	END TRY
	BEGIN CATCH
	PRINT '==============================================='
	PRINT 'ERROR OCCURS DURING LOADING BRONZE LAYER'
	PRINT 'ERROR MESSAGE' + ERROR_MESSAGE ();
	PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
	PRINT 'ERROR NUMBER' + CAST(error_STATE() AS NVARCHAR);
	PRINT '==============================================='

	END CATCH
END
