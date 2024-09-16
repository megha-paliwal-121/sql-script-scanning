-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the get capital equity
-- ETA < 1 min

--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--05/11/2024	        Soma     			05/11/2024   	1M  		 Bug: 7294  Draw enhancements
CREATE OR ALTER  PROCEDURE [dbo].[DealCapture_LoanApplication_GetCapitalEquity] --24422
(
@LoanapplicationId bigint
)
as
begin
BEGIN TRY
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_LoanApplication_GetCapitalEquity] ',@LoanapplicationId) 

DECLARE @NewDollerBalance Decimal(18,2)

Select @NewDollerBalance = ChangeCommittmentAmount from [DealCapture.LoanCreditMemo] WITH(NOLOCK) where LoanApplicationId = @LoanapplicationId

declare @loanRequetType varchar(50);
select @loanRequetType =  LoanRequestTypeId
from 
  Application  with (nolock)
where ApplicationId=@LoanapplicationId;
if(@loanRequetType = 1166)
Begin
select 
Id,
ApplicationId as LoanApplicationId,
IsTheConFirstTime as IsTheConFirstAdvance,
IsTheConRemaingInProject as IsTheConRemainInProject ,
1 IsEditable
, [Version]
,@NewDollerBalance NewDollerBalance
from 

[dbo].[DealCapture.LoanCapitalEquity] with (nolock)

where ApplicationId=@LoanapplicationId
End
Else
Begin
If Exists(select Id from  [dbo].[DealCapture.LoanCapitalEquity] with (nolock) where ApplicationId=@LoanapplicationId)
Begin
select 
Id,
ApplicationId as LoanApplicationId,
IsTheConFirstTime as IsTheConFirstAdvance,
IsTheConRemaingInProject as IsTheConRemainInProject ,
1 IsEditable
, [Version]
,@NewDollerBalance   NewDollerBalance
from 

[dbo].[DealCapture.LoanCapitalEquity] with (nolock)

where ApplicationId=@LoanapplicationId
End
Else
Begin
select 
0 Id ,
@LoanapplicationId as LoanApplicationId,
Null as IsTheConFirstAdvance,
Null as IsTheConRemainInProject ,
1 IsEditable
, NEWID() As Version
,@NewDollerBalance NewDollerBalance

End
End
END TRY

BEGIN CATCH
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_GetCapitalEquity]',NULL,@requestObject
END CATCH



end
GO

