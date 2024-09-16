-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the get DealCapture_LoanApplication_DeleteCapitalEquity
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--06/02/2024	        Pawan     		07/23/2024   	1M  		 Bug: 10842 Rrefreshing Collateral Information- Part 6 Field Level Change Report
--==========================================================================================================================================================
CREATE  OR ALTER PROCEDURE [dbo].[DealCapture_LoanApplication_DeleteCapitalEquity] --24422
(
@LoanapplicationId bigint
)
as
begin
BEGIN TRY
DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_LoanApplication_DeleteCapitalEquity] ',@LoanapplicationId)
DECLARE @NewDollerBalance Decimal(18,2)

Select @NewDollerBalance = ChangeCommittmentAmount from [DealCapture.LoanCreditMemo] WITH(NOLOCK) where LoanApplicationId = @LoanapplicationId

--declare @loanRequetType varchar(50);
--select @loanRequetType =  LoanRequestTypeId
--from 
--  Application  with (nolock)
--where ApplicationId=@LoanapplicationId;
--if(@loanRequetType = 1166)
--If(ISNULL(@NewDollerBalance,0) = 0)
--Begin
Delete  dbo.[DealCapture.LoanCapital] where ApplicationId = @LoanapplicationId
Delete From dbo.[DealCapture.LoanCapitalEquity]  where ApplicationId = @LoanapplicationId and ApplicationId='8989'
--end
END TRY
BEGIN CATCH
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_DeleteCapitalEquity]',NULL,@requestObject
END CATCH



end
GO

