-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 05 Jun 2024
-- Description:    - this  is  sp  for getting insert loans to mature
--- Description : Please review the LMS Scripts for the 09/12/2023 CAB
-- Modified Date:06/05/2024
-- Modified By: Soma
-- ETA < 1 min
--==========================================================================================================================================================
--Created Date      Created By       Review Date    ETA	  		Comments  	
--========================================================================================================================================================== 
--06/05/2024	  	Soma			 06/06/2024   	1M  		Deleting closed Accounts from loans to mature

--==========================================================================================================================================================
 
      
CREATE OR ALTER  PROCEDURE [dbo].[usp_Update_LoansToMature]          
AS        
BEGIN        
 BEGIN TRY      
  
  Drop table  If exists #Temp_LoansToMature

select  LM.LoanMatureId,
		LM.loanApplicationId,
		LM.LoanAccountNumber,
		PartyId,
		LM.[Cnum] ,
		LM.[BankId],
		LM.[PrimaryBorrower],
		LM.[CurrentBalance],
		LM.[MaturityDate],
		LM.[AssignedTo],
		LM.[CreatedBy],
		LM.[CreatedDate],
		--LM[Reason],
		[AccountStatus],
		IA.[Status]
	 INTO #Temp_LoansToMature
 FROM  dbo.LoansToMature LM WITH(NOLOCK) 
 INNER JOIN [LHORIZON].[HorizonPlus].[dbo].IAccts IA WITH(NOLOCK) ON LM.LoanAccountNumber=cast(IA.Account  as varchar(50))
	  WHERE 
	  IA.ACCTTYPE IN (SELECT ATP. [accttype] FROM [LHORIZON].[HorizonPlus].[dbo].AccountTypes ATP WITH(NOLOCK)   WHERE ATP.[loan]=1) and
	   IA.[Status] not IN (0,1,2,3) and isnull(LM.loanApplicationId,0)=0

 DELETE LM
	FROM dbo.LoansToMature LM
	JOIN #Temp_LoansToMature TLM ON LM.LoanMatureId = TLM.LoanMatureId
	WHERE  isnull(LM.loanApplicationId,0)=0

	--Inserting into Audit for tracking
	insert into [dbo].[Audit_LoansToMature](loanApplicationId,
		LoanAccountNumber,
		PartyId,
		[Cnum] ,
		[BankId],
		[PrimaryBorrower],
		[CurrentBalance],
		[MaturityDate],
		[AssignedTo],
		[CreatedBy],
		[CreatedDate],
		[Reason],
		[AccountStatus]) select LM.loanApplicationId,
		LM.LoanAccountNumber,
		PartyId,
		LM.[Cnum] ,
		LM.[BankId],
		LM.[PrimaryBorrower],
		LM.[CurrentBalance],
		LM.[MaturityDate],
		LM.[AssignedTo],
		'Update LoanstoMature',
		GETDATE(),
		'',
		LM.[Status] from #Temp_LoansToMature LM

    
 END TRY      
 BEGIN CATCH      
    EXECUTE [dbo].[uspLogError] '[dbo].[usp_InsertLoansToMature]'        
 END CATCH      
END
GO

