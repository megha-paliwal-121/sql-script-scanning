/***************************************************************************************                                      
-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the  insert details
-- ETA < 1 min                       
==========================================================================================================================================================
Modified Date       Modified By      	Review Date			ETA	  		Comments  									
========================================================================================================================================================== 
9/12/23		     	Ritesh	     		09/13/2023   		1M  		Bug: 7820 Renewals fees N/A
--03/06/2024		Pawan Shukla        05/06/2024			1M		    Bug:6094 : Abundance of caution collateral	
--05/29/2024		Pawan Shukla        07/23/2024			1M		    Bug:9868 : Refreshing Transaction "Loan Details" - Part5 - Balance Calculation Rules
==========================================================================================================================================================

*******************************************************************************************/  
CREATE  OR ALTER    PROCEDURE  [dbo].[DealCapture_LoanApplication_InsertRATEANdDetail]  
  
@LoanApplicationId int,  
@IsFixedRate bit,  
@FixedRate decimal(18, 2), 

@IsLoanOriginationFees bit,  
@LoanOriginationFeesTypeId int,  
@TotalAmount decimal(18, 2),  
@Percentage decimal(18, 5),  
@CreatedBy nvarchar(100),  
@ModifiedBy nvarchar(100),  
@RateFeeVersion nvarchar(max),
@Notes nvarchar(max) = NULL,
--------------------------------Detail-----------------------------  
@Id int,  
@PeriodId int,  
@IndexCodeId int,  
@CurrentIndexRate decimal(18, 5),  
@Offset decimal(18, 5),  
@Floor decimal(18, 5),  
@Ceiling decimal(18, 5),  
@RecomputationPostExpiration INT=NULL,
@StartingRate decimal(18, 5),  
@DateSeqBegin DATETIME=NULL, 
@DateSeqEnd DATETIME=NULL, 
----  
@RateFeeDetailVersion nvarchar(max),  
@IsRateOnlySave  BIT  
  
AS   
BEGIN   
 DECLARE @NewVersionId uniqueIdentifier  
 DECLARE @ErrorCode nvarchar(5) = '0'  
 SET @NewVersionId = newid()  
  
BEGIN TRY  
  BEGIN TRANSACTION  
  
    DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_LoanApplication_InsertRATEANdDetail] ',@LoanApplicationId)    
	DECLARE @UpdatedBy Varchar(100)  
	SET @UpdatedBy = isnull(@CreatedBy,@ModifiedBy)  
  
	DECLARE @LoanStageId INT, @StageId INT, @Oldrecord INT  
	SELECT @LoanStageId = StageId, @StageId = ApplicationStatus FROM [Application] WITH(NOLOCK) where ApplicationId = @LoanApplicationId  

   
DECLARE @RatesAndFeeId INT  
-------------------------------RatesAndFees]------------------------------  
IF EXISTS(SELECT 1 FROM [DealCapture.RatesAndFees] WITH(NOLOCK) where LoanApplicationId = @LoanApplicationID)  
BEGIN  
   
   DECLARE @RatefeeId INT  
   SELECT @RatefeeId = Id from [DealCapture.RatesAndFees] WITH(NOLOCK) WHERE LoanApplicationId = @LoanApplicationID 

   Update [DealCapture.RatesAndFees]   
   SET 
  -- [IsFixedRate] =@IsFixedRate,  
  -- FixedRate= @FixedRate, 
   IsLoanOriginationFees=@IsLoanOriginationFees,  
   LoanOriginationFeesTypeId=@LoanOriginationFeesTypeId,  
   TotalAmount=@TotalAmount,  
   Percentage =@Percentage,  
   ModifiedBy=@ModifiedBy,  
   ModifiedDate=getdate(),  
   Version = @NewVersionId,
   Notes = @Notes
   WHERE LoanApplicationId = @LoanApplicationID   
  
  
        
  INSERT INTO [AuditDealCapture.RatesAndFees]  
  (Id,LoanApplicationId,[IsFixedRate], [FixedRate], [IsLoanOriginationFees], [LoanOriginationFeesTypeId], [TotalAmount], [Percentage], [CreatedBy], [CreatedDate], [LoanStageId], [StatusId],[Notes]) values   
  (@RatefeeId,@LoanApplicationID,@IsFixedRate,@FixedRate,@IsLoanOriginationFees,@LoanOriginationFeesTypeId,@TotalAmount,@Percentage,@UpdatedBy,getdate(),@LoanStageId, @StageId,@Notes)  
    
END   
ELSE   
BEGIN   
  
 INSERT INTO [DealCapture.RatesAndFees](LoanApplicationId,[IsFixedRate], [FixedRate], [IsLoanOriginationFees], [LoanOriginationFeesTypeId], [TotalAmount], [Percentage], [CreatedBy], [CreatedDate],Version,[Notes]) values   
             (@LoanApplicationID,@IsFixedRate,@FixedRate,@IsLoanOriginationFees,@LoanOriginationFeesTypeId,@TotalAmount,@Percentage,@UpdatedBy,getdate() , @NewVersionId,@Notes)  
    
 SELECT @RatefeeId = SCOPE_IDENTITY()  
 INSERT INTO [AuditDealCapture.RatesAndFees]  
  (Id,LoanApplicationId,[IsFixedRate], [FixedRate], [IsLoanOriginationFees], [LoanOriginationFeesTypeId], [TotalAmount], [Percentage], [CreatedBy], [CreatedDate], [LoanStageId], [StatusId], [Notes]) values   
  (@RatefeeId,@LoanApplicationID,@IsFixedRate,@FixedRate,@IsLoanOriginationFees,@LoanOriginationFeesTypeId,@TotalAmount,@Percentage,@UpdatedBy,getdate(),@LoanStageId, @StageId,@Notes)  
    
END   
-------------------------------RatesAndFeesDetail------------------------------  
SELECT @RatesAndFeeId =Id  FROM [dbo].[DealCapture.RatesAndFees] WITH(NOLOCK) WHERE LoanApplicationId=@LoanApplicationId  

  
DECLARE @RatesAndFeeDetailId INT  
  
  
IF(@IsRateOnlySave=0)  
BEGIN   
 IF EXISTS(SELECT 1 FROM [dbo].[DealCapture.RatesAndFeesDetail] WHERE ID = @Id and @RatesAndFeeId=[RatesAndFeeId])  
BEGIN   
  
--IF NOT EXISTS ( SELECT * FROM dbo.[DealCapture.RatesAndFeesDetail]   WHERE id = @Id AND [Version]=@RateFeeDetailVersion AND   
--      ((SELECT TOP 1 ApplicationValue FROM ApplicationSettings WHERE ApplicationKey='IsVersionEnable' AND IsActive=1) = '1'))  
--    BEGIN  
--   SET @ErrorCode='99'  
--   RAISERROR('This application has been updated before submitting your changes. Please refresh the page and try again.',16,2)  
--    END  

 Update dbo.[DealCapture.RatesAndFeesDetail]   
 SET   
   PeriodId =@PeriodId,  
   IndexCodeId=@IndexCodeId,  
   CurrentIndexRate=@CurrentIndexRate, 
   RecomputationPostExpiration=@RecomputationPostExpiration,
   Offset=@Offset,  
   [Floor]=@Floor,  
   [Ceiling]= @Ceiling,
   [DateSeqBegin]=@DateSeqBegin,
   [DateSeqEnd]=@DateSeqEnd,
   StartingRate=@StartingRate,  
   Version = @NewVersionId  
 WHERE id = @Id and RatesAndFeeId=@RatesAndFeeId  
  
  
 INSERT INTO [dbo].[AuditDealCapture.RatesAndFeesDetail](Id,RatesAndFeeId,[PeriodId], [IndexCodeId], [CurrentIndexRate], [Offset], [Floor], [Ceiling], [StartingRate],[DateSeqBegin],[DateSeqEnd],[IsDelete],[CreatedBy],[CreatedDate],[LoanStageId], [StatusId],RecomputationPostExpiration) Values  
  (@Id,@RatesAndFeeId,@PeriodId,@IndexCodeId,@CurrentIndexRate,@Offset,@Floor,@Ceiling,@StartingRate,@DateSeqBegin,@DateSeqEnd,0,@UpdatedBy,getdate(),@LoanStageId, @StageId,@RecomputationPostExpiration)  

END   
ELSE   
BEGIN   
INSERT INTO [dbo].[DealCapture.RatesAndFeesDetail](RatesAndFeeId,[PeriodId], [IndexCodeId], [CurrentIndexRate], [Offset], [Floor], [Ceiling], [StartingRate],[DateSeqBegin],[DateSeqEnd],Version,RecomputationPostExpiration) Values  
              (@RatesAndFeeId,@PeriodId,@IndexCodeId,@CurrentIndexRate,@Offset,@Floor,@Ceiling,@StartingRate,@DateSeqBegin,@DateSeqEnd,@NewVersionId,@RecomputationPostExpiration)  
  
SELECT @RatesAndFeeDetailId = SCOPE_IDENTITY()  
INSERT INTO [dbo].[AuditDealCapture.RatesAndFeesDetail](Id,RatesAndFeeId,[PeriodId], [IndexCodeId], [CurrentIndexRate], [Offset], [Floor], [Ceiling], [StartingRate],[DateSeqBegin],[DateSeqEnd],[IsDelete],[CreatedBy],[CreatedDate],[LoanStageId], [StatusId],RecomputationPostExpiration) Values  
  (@RatesAndFeeDetailId,@RatesAndFeeId,@PeriodId,@IndexCodeId,@CurrentIndexRate,@Offset,@Floor,@Ceiling,@StartingRate,@DateSeqBegin,@DateSeqEnd,0,@UpdatedBy,getdate(),@LoanStageId, @StageId,@RecomputationPostExpiration)  
  

END   
END  
  
  
-- Loan Application  updte   
exec [DealCapture_LoanApplication_UpdateModifiedDate]  @LoanApplicationId, @UpdatedBy  
-------------------If  user changing variable to fixed rate, then  need to  delete the Record   
--If (@IsFixedRate=1)  
--Begin  

--Delete from   [DealCapture.RatesAndFeesDetail]  where RatesAndFeeId in (select Id from [DealCapture.RatesAndFees] WITH(NOLOCK) where LoanApplicationId = @LoanApplicationID)  
--END   
  
/* Is Form flag Reset Code */  
 EXEC dbo.usp_IsFormFlagReset  @LoanApplicationID , 4  
 Update FolderDocuments SET IsActive=0 , UpdatedBy = 'DealCapture_LoanApplication_InsertRATEANdDetail'  where ApplicationID=@LoanApplicationId and DocumentID IN(182,214)  
/* Is Form flag Reset Code */  
---------------------------------------------Ritesh  if  renewal  fee  off then  should not  show  disburment 7820  
	DECLARE @LoanDisbursementType INT = 2
	--Ritesh  this line added fotr renewal and add new
	SELECT @LoanDisbursementType = CASE WHEN LoanRequestTypeId=1166 THEN 2 ELSE 3 END FROM  Application with (nolock) where ApplicationID=@LoanApplicationId and IsActive=1
	if (@IsLoanOriginationFees=0)
	BEGIN 
		Update  [DealCapture.DisbursementFeeDetails] set IsActive=0 where  LoanApplicationId=@LoanApplicationId and  TypeId=@LoanDisbursementType
		EXEC dbo.usp_IsFormFlagReset @LoanApplicationId , 27
	END
	--Document  generate

   -- Here we are checking rate is fixed or not base on that updating rate and fee table
   SELECT @IsFixedRate=[dbo].[fn_IsFixedRate] (@LoanApplicationId);
   IF @IsFixedRate=1
   BEGIN
		SELECT TOP 1 @FixedRate=StartingRate FROM [DealCapture.RatesAndFeesDetail] WHERE IsDelete=0 AND RatesAndFeeId=@RatesAndFeeId
		UPDATE [DealCapture.RatesAndFees] SET IsFixedRate=@IsFixedRate,FixedRate=@FixedRate WHERE LoanApplicationId=@LoanApplicationId
   END
   ELSE
   BEGIN
		SET @FixedRate=0.00
   END
   UPDATE [DealCapture.RatesAndFees] SET IsFixedRate=@IsFixedRate,FixedRate=@FixedRate WHERE LoanApplicationId=@LoanApplicationId

	---------------------------------------------Ritesh  if  renewal  fee  off then  should not  show  disburment 7820  
  SET @ErrorCode ='1'  
  COMMIT TRANSACTION  
 END TRY  
  
 BEGIN CATCH  
   
   SET @NewVersionId= null   
   ROLLBACK TRANSACTION  
   EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_InsertRATEANdDetail]',NULL,@requestObject  
 END CATCH  
  
SELECT @ErrorCode as 'ErrorCode',@NewVersionId AS 'Version' , @Id as 'ID', @LoanApplicationId as 'ApplicationId'  
  
END
GO

