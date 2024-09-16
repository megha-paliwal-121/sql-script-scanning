---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the get disbursement instructions
-- ETA < 1 min



CREATE  OR ALTER  PROCEDURE [dbo].[DealCapture_GetDisbursementInstructions]
@LoanApplicationId BIGINT,
@CreatedBy VARCHAR(100)
AS
BEGIN 
  BEGIN TRY

DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_GetDisbursementInstructions] ',@LoanApplicationId,',','''',@CreatedBy)
					
	DECLARE @DisbursementAmount decimal(18,2)
	DECLARE @Loanoriginationfees BIT
	Declare @LoanDisbursementType int = 2
	Declare @LoanRequestTypeId int
	Declare @ApplicationStageID int
	Declare  @IsSubmittedforCreditManager bit =0

	--Ritesh  this line added fotr renewal and add new
	select @LoanDisbursementType = case when LoanRequestTypeId=1166 then 2 else 3 end, @ApplicationStageID=StageId, @IsSubmittedforCreditManager = isnull(IsSubmittedforCreditManager,0) from  Application with (nolock)where ApplicationID=@LoanApplicationId and
 IsActive=1

	SELECT @DisbursementAmount = CASE WHEN isloanoriginationfees = 1 THEN TotalAmount ELSE 0 END                  
		FROM   [dealcapture.ratesandfees]  WITH(nolock)
		WHERE  LoanApplicationId = @LoanApplicationId

		SELECT @Loanoriginationfees = isloanoriginationfees                
		FROM   [dealcapture.ratesandfees]  WITH(nolock)
		WHERE  LoanApplicationId = @LoanApplicationId

Declare @NewTotalCommitment decimal(18,2)
DECLARE @TotalCommitment  decimal(18,2)
DECLARE @CurrentBalance  decimal(18,2)
DECLARE @newLoanAmount  decimal(18,2)
DECLARE @UnusedCommitment  decimal(18,2)
DECLARE @loanAmountRenewal  decimal(18,2)
DECLARE  @IsShowCorePopup bit=0
Declare @ChangeCommittmentAmount decimal(18,2)
Declare @LoanUnusedCommitment decimal(18,2)
Declare @FundsAvailableToDisburse decimal(18,2)
  ----------------------------------------------------New logic for unused commitment ------
	  If (@ApplicationStageID>=3 and  @IsSubmittedforCreditManager=1)
	  Begin
		set @IsShowCorePopup= dbo.[fn_IsMaintanancePending](@LoanApplicationId,1)
		
		--select @IsShowCorePopup 
	  END

	 DECLARE 
				 @TDNewTotalCommitment Decimal(18,2)
				,@TDOriginalTotalCommitment Decimal(18,2) 
				,@TDCurrentBalance Decimal(18,2) 
				,@TDLetterofCredit Decimal(18,2) 
				,@TDUCProposedLoan Decimal(18,2) 
				, @TDUCRenewalAmount Decimal(18,2)
		Declare  @unusedCommitementMemo  decimal(18,2)


				SELECT 	@TDNewTotalCommitment = isnull(NewTotalCommitment ,0.00) ,
				@TDOriginalTotalCommitment =  isnull(TotalCommitment,0.00) ,
				@TDCurrentBalance = isnull(CurrentBalance,0.00),
				@TDLetterofCredit = isnull(LetterofCredit,0.00) 
				
			

				FROM [dbo].[DealCapture.LoanCreditMemo] LC  WITH(NOLOCK) inner join application A  with(nolock)
				on a.ApplicationID=lc.LoanApplicationId
				WHERE LoanApplicationId= @LoanApplicationId

				--New Total Commitment = Original Total Commitment for Renewal Transaction
				--New Total Commitment < Original Total Commitment for Renewal Transaction

				set @TDUCRenewalAmount =  @TDOriginalTotalCommitment -  @TDCurrentBalance;
				---- Calculate Praposed Loan
				if(@TDNewTotalCommitment <= @TDOriginalTotalCommitment ) 
				begin 
				  				 set @TDUCRenewalAmount =  @TDNewTotalCommitment -  @TDCurrentBalance;
				end 
		
			SEt @unusedCommitementMemo= @TDUCRenewalAmount


	 -----------------------------------------------------------------------------------------------------------------------


DECLARE @DisbursementAmount decimal(18,2)
	DECLARE @Loanoriginationfees BIT
	Declare @LoanDisbursementType int = 2
	Declare @LoanRequestTypeId int
	Declare @ApplicationStageID int
	Declare  @IsSubmittedforCreditManager bit =0

select 
 @newLoanAmount = case when NewTotalCommitment>TotalCommitment then NewTotalCommitment-TotalCommitment else 0 end 
 ,@NewTotalCommitment=NewTotalCommitment, @TotalCommitment=TotalCommitment,@CurrentBalance =CurrentBalance,
 --@UnusedCommitment = UnusedCommitment  --Comment  by ritesh  7908
 @UnusedCommitment= @unusedCommitementMemo, @ChangeCommittmentAmount = ISNULL(ChangeCommittmentAmount,0) , @LoanUnusedCommitment = ISNULL(UnusedCommitment, 0)
 from [DealCapture.LoanCreditMemo] WITH(NOLOCK) where LoanApplicationId= @LoanApplicationId

SET @loanAmountRenewal = @newLoanAmount+@CurrentBalance+ @UnusedCommitment
SET @FundsAvailableToDisburse = @LoanUnusedCommitment + @ChangeCommittmentAmount


	IF( NOT EXISTS(SELECT 1 FROM [dbo].[DealCapture.DisbursementFeeDetails]  WITH(nolock) WHERE [LoanApplicationId] = @LoanApplicationId
	AND TypeId = @LoanDisbursementType AND IsActive=1)
	AND  @Loanoriginationfees =1)
	BEGIN

		INSERT INTO [dbo].[DealCapture.DisbursementFeeDetails]
			([LoanApplicationId]
			,[TypeId]
			,[MethodofTransferId]
			,[TransferDetails]
			,[CustomerFeeAmount]
			,[DisbursementAmount]
			,[CreatedBy]
			,[CreatedDate]
			,[UpdatedBy]
			,[UpdatedDate]
			,[IsActive]
			,IsSystemGenerated)
		VALUES
			(@LoanApplicationId
			,@LoanDisbursementType
			,0
			,0
			,case when @LoanDisbursementType not in (2,3) then @DisbursementAmount else null end  -- 8859 Origination Fee - Customer Fee
			,case when @LoanDisbursementType in (2,3) then @DisbursementAmount else null end
			--,@DisbursementAmount   --Reverted Code as per IBC defect 5410
			
			,@CreatedBy
			,GetDate()
			,''
			,null
			,1
			,1)
	END
	ELSE IF(EXISTS(SELECT 1 FROM [dbo].[DealCapture.DisbursementFeeDetails]  WITH(nolock) WHERE [LoanApplicationId] = @LoanApplicationId AND TypeId = 2 AND IsActive=1)
	AND  @Loanoriginationfees =0)
	BEGIN
	UPDATE [DealCapture.DisbursementFeeDetails] SET
			 IsActive = 0
			,UpdatedBy = @CreatedBy
			,UpdatedDate = GETDATE()
		WHERE LoanApplicationId = @LoanApplicationId AND TypeId = 2
	END
	ELSE 
	BEGIN

		UPDATE [DealCapture.DisbursementFeeDetails] SET
			 DisbursementAmount = DisbursementAmount
			,UpdatedBy = @CreatedBy
			,UpdatedDate = GETDATE()
		WHERE LoanApplicationId = @LoanApplicationId AND TypeId = 2
	END

	SELECT DF.Id,
			loanapplicationid,
			Typeid,
			DT.[name] AS [Type],
			methodoftransferid,
			MT.[name] AS MethodofTransfer,
			transferdetails,
			customerfeeamount,
			disbursementamount
			,isnull(IsSystemGenerated,0) as IsSystemGenerated
			,ISNULL(ThirdPartyName,'') as ThirdPartyName
	FROM   [dbo].[DealCapture.DisbursementFeeDetails] DF WITH(nolock)
			LEFT OUTER JOIN [master].loandisbursementtype DT WITH(nolock)
					ON DF.typeid = DT.id
						AND DT.isactive = 1
			LEFT OUTER JOIN [master].loanmethodoftransfer MT WITH(nolock)
					ON DF.MethodofTransferId = MT.id
						AND MT.isactive = 1
	WHERE  DF.LoanApplicationId = @LoanApplicationId AND DF.IsActive=1
		Order by  df.Id asc





	SELECT 
			
			SUM(ISNULl(DF.customerfeeamount, 0)) AS TotalCustomerFee,
			SUM(ISNULL(DF.[disbursementamount], 0)) AS TotalDisbursementAmount,
			--dbo.[fn_GetLoanAmount](DF.loanapplicationid) - SUM(ISNULL(DF.[disbursementamount], 0))  AS UnDisbursementAmount
			--Fixed by Ritesh 4984
			case when A.LoanRequestTypeId= 1166  
					then  dbo.[fn_GetLoanAmount](DF.loanapplicationid) - SUM(ISNULL(DF.[disbursementamount], 0)) 
				else @FundsAvailableToDisburse - SUM(ISNULL(DF.[disbursementamount], 0))  end UnDisbursementAmount
				,(@newLoanAmount+ @UnusedCommitment )-SUM(ISNULL(DF.[disbursementamount], 0)) tbd
			,[dbo].[Fn_calculatedisbursementtotalfee](DF.loanapplicationid) AS TotalFee
			,ISNULL(A.IsDisbursementAcknowledge,0) AS IsAcknowledge
			 ,case when A.LoanRequestTypeId= 1166  then   CONVERT(DECIMAL(18,2), lc.loanamount) else @loanAmountRenewal   end LoanAmount
			--,lc.UnusedCommitment  -- comment  by Ritesh
			,@unusedCommitementMemo as UnusedCommitment

			,lc.NewTotalCommitment
			,@newLoanAmount as newLoanAmount
			,lc.TotalCommitment
			,CurrentBalance as NewBalance
			,@IsShowCorePopup as IsShowCorePopup
			
				FROM   [dbo].[DealCapture.DisbursementFeeDetails] DF WITH(nolock)
			INNER JOIN [dealcapture.loancreditmemo] lc WITH(nolock)
					ON lc.loanapplicationid = DF.loanapplicationid
			INNER JOIN dbo.[Application] A WITH(nolock)
					ON A.ApplicationID = DF.loanapplicationid
	WHERE  DF.loanapplicationid = @LoanApplicationId AND DF.IsActive = 1
	GROUP  BY lc.loanamount,
				DF.loanapplicationid,A.IsDisbursementAcknowledge,LoanRequestTypeId
				,NewTotalCommitment						,lc.TotalCommitment,CurrentBalance
			



	

  END TRY

  BEGIN CATCH

  EXEC uspLogError '[dbo].[DealCapture_GetDisbursementInstructions]',NULL,@requestObject

  END CATCH
	
END

--select * from [DealCapture.DisbursementFeeDetails] 
--23294
GO

