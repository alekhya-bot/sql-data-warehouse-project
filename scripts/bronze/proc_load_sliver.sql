/*
=====================================================================
Storage procedure : Load sliver layer (souce-> bronze)
======================================================================
Script Purpose:
  This store procedure loads data into the 'sliver' scema from external csv file.
  it performs the following actions:
  - Turncate the sliver table before loading data
  - Uses the BULK INSERT command to load data from csv files to bronze tables.

Parameters
   None;
   this store produrce does not acept any parameters or return any value.

Usage Example:
EXEC EXEC sliver.load_bronze 
========================================================================
*/


EXEC sliver.load_sliver
CREATE OR ALTER PROCEDURE sliver.load_sliver AS
BEGIN
    	DECLARE @start_Time Datetime, @end_Time Datetime, @batch_start_time Datetime, @batch_end_time Datetime;
	BEGIN TRY
		SET @batch_start_time = GETDATE();
		PRINT '===================================';
		PRINT 'Loading sliver Layer';
		PRINT '===================================';

		PRINT'-------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT'-------------------------------------';

---- loading crm_cust_info table

	SET @start_Time = GETDATE();
    PRINT'>> TRUNCATING Table into :sliver.crm_cust_info';
	TRUNCATE Table sliver.crm_cust_info;
	PRINT '>> INSERT INTO sliver.crm_cust_info';
	INSERT INTO sliver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname ,
		cst_lastname,
		cst_marital_status ,
		cst_gndr,
		cst_create_date)

	SELECT
		cst_id,
		cst_key,
		TRIM(cst_firstname) AS cst_fistname,
		trim(cst_lastname) AS cst_lastname,
		CASE WHEN UPPER(TRIM (cst_marital_status)) = 'S' THEN 'SINGLE'
			 WHEN UPPER(TRIM (cst_marital_status)) = 'M' THEN 'MARRIED'
			 else 'n/a'
		END cst_marital_status,
	
		CASE WHEN UPPER(TRIM (cst_gndr)) = 'F' THEN 'Female'
			 WHEN UPPER(TRIM (cst_gndr)) = 'M' THEN 'Male'

			 else 'n/a'
		END cst_gndr,
		cst_create_date 

	FROM(

		SELECT *,

		ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) as last_flag
		FROM bronze.crm_cust_info
		WHERE cst_id =1
		)t where last_flag  = 1; 

		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

---- loading crm_prd_info table

		SET @start_Time = GETDATE();
	PRINT'>> TRUNCATING Table into : sliver.crm_prd_info';
	TRUNCATE Table sliver.crm_prd_info ;
	PRINT'>>INSERT INTO sliver.crm_prd_info';
	INSERT INTO sliver.crm_prd_info  (
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)

	SELECT
	prd_id,
	Replace (substring(prd_key, 1,5), '-','_')AS Cat_id,--extract category id
	SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,-- data product id
	prd_nm,
	ISNULL(prd_cost, 0) prd_cost,

	CASE UPPER(TRIM(prd_line))  
		  WHEN 'M' THEN 'mountain'
		  WHEN 'R' THEN 'Road'
		  WHEN 'S' THEN 'OtherSales'
		  WHEN 'T' THEN 'Touring'
		  else 'n/a'
	END prd_line,-- map product line codes to descriptive values

	CAST(prd_start_dt AS DATE) prd_start_dt,
	CAST( 
		LEAD (prd_start_dt) OVER (PARTITION BY prd_key Order BY prd_start_dt)-1 
		AS DATE
		)AS prd_end_dt-- calculate end date as one day beforethe next day start time

	From bronze.crm_prd_info
	 SET @end_Time = GETDATE();

		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

---- loading crm_sales_details table

	SET @start_Time = GETDATE();
	PRINT'>> TRUNCATING Table into :sliver.crm_sales_details';
	TRUNCATE Table sliver.crm_sales_details;
	PRINT'>> INSERT INTO sliver.crm_sales_details';
	INSERT INTO sliver.crm_sales_details (
	 sls_ord_num,
	 sls_prd_key,
	 sls_cust_id,
	 sls_order_dt,
	 sls_ship_dt,
	 sls_due_dt,
	 sls_sales,
	 sls_quantity,
	 sls_price       
	  )
	SELECT     
		 sls_ord_num,
		 sls_prd_key,
		 sls_cust_id,
		 CASE WHEN sls_order_dt = 0 or LEN(sls_order_dt) != 8 THEN NULL
			  ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
		 END sls_order_dt,
		 CASE WHEN sls_ship_dt = 0 or LEN(sls_ship_dt) != 8 THEN NULL
			  ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
		 END sls_ship_dt,
		 CASE WHEN sls_due_dt = 0 or LEN(sls_due_dt) != 8 THEN NULL
			  ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
		 END sls_due_dt,
		 CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales != sls_quantity* ABS(sls_price)
				 Then  sls_quantity* ABS (sls_price)
			  ELSE sls_sales
		END AS sls_sales,-- recalculate sales if original value is missing or incorrect--
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <=0 
				 THEN sls_sales/ NULLIF (sls_quantity,0)
			 ELSE sls_price -- Dervie price if original valu is invalid
		END sls_price
	  FROM bronze.crm_sales_details

	  SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';


        PRINT'-------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT'-------------------------------------';
---- loading erp_cust_az12' table

	SET @start_Time = GETDATE();
    PRINT'>> TRUNCATING Table into :sliver.erp_cust_az12';
	TRUNCATE Table sliver.erp_cust_az12;
	PRINT '>> insert data into:sliver.erp_cust_az12';
	INSERT INTO sliver.erp_cust_az12 (
	 cid,
	 bdate,
	 gen 
	 )
	SELECT

	 CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
		  ELSE cid
	END AS cid,
 
	 CASE WHEN bdate > GETDATE() THEN NULL
		   ELSE bdate
	 END AS bdate, -- Set future bdate to null--

	 CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
		 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
		 ELSE 'n/a' -- Normalize gender value and unknown cases--
	END AS gen 
	 FROM bronze.erp_cust_az12

	 SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';
---- loading erp__loc_a101  table

	SET @start_Time = GETDATE();
    PRINT'>> TRUNCATING Table into : sliver.erp_loc_a101 ';
	TRUNCATE Table sliver.erp_loc_a101 ;
	PRINT '>> insert data into:sliver.erp_loc_a101';
	INSERT INTO sliver.erp_loc_a101 (cid,cntry)
	SELECT
	REPLACE (cid,'-', '')cid,
	CASE WHEN TRIM(cntry) = 'DE' THEN 'Germany'
		 WHEN TRIM(Cntry) IN ('US', 'USA') THEN 'United States'
		 WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
		 ELSE TRIM(cntry)
	END cntry -- normalizing and handle missing or blank country codes--
	FROM bronze.erp_loc_a101

	SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

---- loading erp_px_cat_g1v2  table

	SET @start_Time = GETDATE();
    PRINT'>> TRUNCATING Table into :sliver.erp_px_cat_g1v2';
	TRUNCATE Table sliver.erp_px_cat_g1v2;
	PRINT '>> insert data into:sliver.erp_px_cat_g1v2'
	INSERT INTO sliver.erp_px_cat_g1v2 (
	id,
	cat,
	subcat,
	maintaince
	)
	SELECT
	id, 
	cat,
	subcat,
	maintaince
	From bronze.erp_px_cat_g1v2
	
		SET @end_Time = GETDATE();
		PRINT '>>Load duration: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';
		PRINT '>>---------------';

		SET @batch_end_time = GETDATE();

		PRINT'======================================='
		PRINT 'Loading sliver laye is completed';
		PRINT '- total Load duration: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + 'seconds';
		PRINT'======================================='
	END TRY
	BEGIN CATCH
	PRINT '==============================================='
	PRINT 'ERROR OCCURS DURING LOADING bronze LAYER'
	PRINT 'ERROR MESSAGE' + ERROR_MESSAGE ();
	PRINT 'ERROR NUMBER' + CAST(ERROR_NUMBER() AS NVARCHAR);
	PRINT 'ERROR NUMBER' + CAST(error_STATE() AS NVARCHAR);
	PRINT '==============================================='

	END CATCH
END

