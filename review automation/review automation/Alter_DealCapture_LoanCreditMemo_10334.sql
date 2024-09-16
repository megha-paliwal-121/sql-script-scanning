/***************************************************************************************				                                
-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the Loan credit memo
-- ETA < 1 min				                        
========================================================================================*/
--==========================================================================================================================================================
--Modified Date       Modified By      	Review Date			ETA	  		Comments  									
--========================================================================================================================================================== 
--06/29/24    	    soma  	      	    07/23/24     	1M  	        Bug: 10334 -  Collateral Management enhancements to Commercial retail tenant details

--exec  [DealCapture_LoanCreditMemo] 12844
CREATE  OR ALTER PROCEDURE [dbo].[DealCapture_LoanCreditMemo](
@LoanApplicationId INT)
AS
BEGIN 
BEGIN TRY
 DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEc [dbo].[DealCapture_LoanCreditMemo] ',@LoanApplicationId)

---------------------------------------------------------------------------
SELECT LCM.[Id]
      ,LCM.[LoanApplicationId]
      ,LCM.[AdvanceTypeId]
      ,LCM.[LoanPurposeID]
      ,LCM.[ExistingLetterId]
      ,LCM.[ExistingLetter]
      ,LCM.[LetterofCredit]
      ,LCM.[LoanAmount]
      ,LCM.[Date]
      ,LCM.[AdditionalDetails]
      ,LCM.[UseofFundsId]
	  ,LCM.[COVID19Impact]
	  ,LCM.[NAICSCodeID]
      ,LCM.[DepositoryInstitutionTypeID]
      ,LCM.[CreatedBy]
      ,LCM.[CreatedDate]
      ,LCM.[ModifiedBy]
      ,LCM.[ModifiedDate]
	  ,1 IsEditable
	  , version [Version]
	  ,A.LoanOfficerBankId AS BankID
	  ,A.LoanAccountNumber as  LoanApplicationNumber
	  ,A.AttorneyLawFirmID
	  ,LCM.ISCommitmentChanged
	  ,LCM.UnusedCommitment
	  ,LCM.TotalCommitment
	  ,LCM.NewTotalCommitment
	  ,LCM.CurrentBalance
	  ,LCM.[IsActiveLetterOfCredit]
      ,LCM.[DirectDebt]
      ,LCM.[InDirectDebt]
	  ,LCM.Notes
	  ,LCM.ChangeCommittmentAmount
  FROM [dbo].[DealCapture.LoanCreditMemo] LCM WITH(NOLOCK)
  INNER JOIN Application A WITH(NOLOCK) ON A.ApplicationID = LCM.LoanApplicationId
  WHERE LCM.LoanApplicationId= @LoanApplicationId

   select top 1 [IsDomestic]  IsDomestic from vw_LoanPartyData  WITH(NOLOCK) where applicationID = @LoanApplicationId AND PartyRoleId =1

  	--  (SELECT IsDomestic FROM [dbo].[DealCapture.PartyInformations] 
	  --WHERE LoanApplicationId= @LoanApplicationId AND ) 
	  END TRY

BEGIN CATCH
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanCreditMemo]',NULL,@requestObject
END CATCH
End
GO

