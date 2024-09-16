-- Author: Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description: dbo].[USP_Insert_Refresh_CollateralAccountLevelSummary] Stored Procedure
-- ETA < 1 min

CREATE OR ALTER   PROCEDURE [dbo].[USP_Insert_Refresh_CollateralAccountLevelSummary]     
       @ApplicationID BIGINT
	  ,@CollateralID BIGINT
	  ,@CIF NVARCHAR(50)
	  ,@Sequence INT
	  ,@CollateralCode NVARCHAR(10)
	  ,@DescriptionId INT
	  ,@SequenceRecordSource NVARCHAR(500)
	  ,@PostRefreshChanges NVARCHAR(500)
	  ,@IsChangeReportApplicable BIT
	  ,@IsSequenceAdded BIT
	  ,@IsSwapCollApplicable BIT
	  ,@IsSequenceDeleted BIT
      ,@LoginUser VARCHAR(100)
AS              
BEGIN              
BEGIN TRY              
 BEGIN TRANSACTION   
	
	DECLARE @Description NVARCHAR(100)
	SELECT @Description=Name FROM [MASTER].[LoanCollProductDescription] WITH(NOLOCK) WHERE  Id=@DescriptionId
	INSERT INTO [dbo].[Refresh_CollateralAccountLevelSummary]
           ([ApplicationId]
           ,[CollateralId]
           ,[CIF]
           ,[Sequence]
           ,[CollateralCode]
           ,[CollateralDescription]
           ,[SequenceRecordSource]
           ,[PostRefreshChanges]
           ,[IsChangeReportApplicable]
           ,[IsSwapCollApplicable]
           ,[IsSequenceAdded]
           ,[IsSequenceDeleted]
           ,[IsActive]
           ,[CreatedBy]
           ,[CreatedDate]
           ,[UpdatedBy]
           ,[UpdatedDate])
     VALUES
           (@ApplicationID
           ,@CollateralID
           ,@CIF
           ,@Sequence
           ,@CollateralCode
           ,@Description
           ,@SequenceRecordSource
           ,@PostRefreshChanges
           ,@IsChangeReportApplicable
           ,@IsSwapCollApplicable
           ,@IsSequenceAdded
           ,@IsSequenceDeleted
           ,1
           ,@LoginUser
           ,GETDATE()
           ,@LoginUser
           ,GETDATE())
  
 
 COMMIT TRAN
 SELECT 1
 END TRY            
            
 BEGIN CATCH       
   ROLLBACK TRAN
   EXECUTE [dbo].[uspLogError] '[dbo].[USP_Insert_Refresh_CollateralAccountLevelSummary]',NULL,''         
 END CATCH                    
END
GO

