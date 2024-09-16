-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 06 16 2023
-- Description:    - this  is  sp  for getting the save loan level LTV
-- Description : Please review the LMS Scripts for the 08/01/2023 CAB
-- Modified By: Soma
-- Modified Date: 07/18/2023
-- Bug : 7292  Renewal exclude existing collateral,  
-- Modified By: vikram
-- Modified Date:08/15/2023
-- Bug-7514 fixed- missing previous loans linked to collateral. 
-- Lines Updated:43,57 and 75 to 79
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date       Modified By      	Review Date			ETA	  		Comments  									
--========================================================================================================================================================== 
--06/29/24    	    Pawan  	      	    07/23/24     	1M  	        Bug: 10028 -  Renewal : Rrefreshing Collateral Information Account Level Data -Part 2

CREATE OR ALTER  PROCEDURE [dbo].[DealCapture_LoanApplication_SaveLoanLeveLTV]  
	@LoanApplicationId INT
AS            
BEGIN            
BEGIN TRY            
 DECLARE @RequestObject NVARCHAR(MAX)=CONCAT('exec [dbo].[DealCapture_LoanApplication_SaveLoanLeveLTV]',@LoanApplicationId)

 DECLARE @IsTriggerLTVCalc BIT=0

 SELECT @IsTriggerLTVCalc=IsTriggerLTVCalc FROM [Application] WHERE IsActive=1 AND ApplicationId=@LoanApplicationId

 --IF @IsTriggerLTVCalc=1
 --BEGIN
	 DECLARE @CollateralKey NVARCHAR(150)=NULL,
		 @CollSequence INT,
		 @BankId INT,
		 @CollateralValue DECIMAL(18,2),
		 @NonIBCDebt DECIMAL(18,2)=0.00,
		 @LienPositionId INT,
		 @PropertyOccupancyId INT,
		 @UseOfFundsId INT,
		 @ProductCode INT,
		 @AllocatedAmount DECIMAL(18,2),
		 @LoanAmount DECIMAL(18,2),
		 @AccountNumber BIGINT=null,
		 @CollateralId int=null

	 SELECT TOP 1 
		 @CollateralKey=Pkey,
		 @BankId=BankId,
		 @CollSequence=seq,
		 @CollateralValue=CollateralAmount,
		 @NonIBCDebt=NonIBCDebtAmount,
		 @LienPositionId=LienPositionId,
		 @PropertyOccupancyId=PropertyOccupanyId,
		 @UseOfFundsId=0,
		 @ProductCode=ProductCode,
		 @AllocatedAmount=NewAllocatedAmount
		,@LoanAmount=dbo.fn_GetLoanAmount(@LoanApplicationID)
		
		 ,@CollateralId=Id

		FROM [DealCapture.LoanCollateralDetail] WHERE ApplicationId = @LoanApplicationID and isDeleted=0 and Isnull(IsExclude,0)=0

		select @AccountNumber= loanaccountnumber FROM [Application] where applicationid=@LoanApplicationID	
		--select @LoanAmount =LoanAmount   FROM [dbo].[DealCapture.LoanCreditMemo] where loanapplicationid=@LoanApplicationID

		 ---------------------------------------
		 DECLARE @PrevTotalCollLtvValues TABLE 
		(
		PrevDistinctCollTotalCollValue decimal(18,2),  
		 prevDistinctCollTotalNonIBCDebt decimal(18,2),  
		 PrevDistinctCollTotalLendingLimit decimal(18,2),
		 previousCollLoansTotalAmount decimal(18,2)
		)
DECLARE @previousLoansTotalAmount decimal(18,2),
		@prevDistinctCollTotalLendingLimit decimal(18,2),
		@prevDistinctCollTotalCollValue decimal(18,2),
		@prevDistinctCollTotalNonIBCDebt decimal(18,2),
		 @previousOtherCollLoansTotalAmount decimal(18,2)=0
		 ---7514--bug fixed
		  SELECT 
		@previousLoansTotalAmount= SUM([CMS].[dbo].[fn_GetLoanLoanTotalCommitment ](colltrk.AccountNumber,colltrk.BankId ))
		FROM [CMS].[dbo].CollManagement_CollTrk  AS colltrk WITH(NOLOCK)  
		WHERE colltrk.CollateralKey =@CollateralKey and CollSequence = @CollSequence
		and colltrk.BankId = @BankId and colltrk.isActive = 1  and not  (colltrk.AccountNumber=@AccountNumber)


INSERT INTO @PrevTotalCollLtvValues
EXEC CMS.[dbo].[Collateral_GetLMSOtherTotalCollLtvValues] @BankId ,  @CollSequence,  
															@CollateralKey ,@CollateralValue,
															@NonIBCDebt, 
															@ProductCode ,
															@LienPositionId ,
															@PropertyOccupancyId ,
															@UseOfFundsId ,@AccountNumber,  @LoanApplicationID ,@CollateralId

	 SELECT TOP 1 @prevDistinctCollTotalCollValue = s.PrevDistinctCollTotalCollValue, @prevDistinctCollTotalNonIBCDebt=s.prevDistinctCollTotalNonIBCDebt,
@previousOtherCollLoansTotalAmount = s.previousCollLoansTotalAmount 
from @PrevTotalCollLtvValues s
SET @previousLoansTotalAmount=ISNULL( @previousLoansTotalAmount,0)+ISNULL(@previousOtherCollLoansTotalAmount,0)
		 -----------------------

SET @prevDistinctCollTotalCollValue=@prevDistinctCollTotalCollValue+@CollateralValue
SET @prevDistinctCollTotalNonIBCDebt=@prevDistinctCollTotalNonIBCDebt+@NonIBCDebt

DECLARE @LoanLevelLTV DECIMAL(18,2)


SELECT @LoanLevelLTV = [CMS].[dbo].[fn_GetLoanLevelLtv](@LoanAmount,@prevDistinctCollTotalNonIBCDebt,@previousLoansTotalAmount,@prevDistinctCollTotalCollValue)



UPDATE [DealCapture.LoanCollateral] SET  LoanLevelLTV=@LoanLevelLTV WHERE LoanApplicationId = @LoanApplicationID

DECLARE @LoanStageId INT, @StatusId INT, @Oldrecord INT  
  SELECT @LoanStageId = StageId, @StatusId = ApplicationStatus  FROM [Application] WITH(NOLOCK) where ApplicationId = @LoanApplicationId  
  
 INSERT INTO [AuditDealCapture.LoanCollateral]
  ( LoanApplicationId, IsLoanSecured, LoanNarretive,  [CreatedBy], [CreatedDate],[LoanStageId], [StatusId],LoanLevelLTV) 
  select  LoanApplicationId, IsLoanSecured, LoanNarretive,  [CreatedBy], getdate(),@LoanStageId, @StatusId ,@LoanLevelLTV from   [DealCapture.LoanCollateral]
  WHERE LoanApplicationId = @LoanApplicationID
 
--UPDATE [Application] SET IsTriggerLTVCalc=0 WHERE ApplicationId=@LoanApplicationId
--select 1
 --END
 END TRY  
  
 BEGIN CATCH  
  EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_SaveLoanLeveLTV]',NUll,@RequestObject  
 select 0
 END CATCH  
   
END
GO

