-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the get deed of trust info
-- ETA < 1 min
/****** Script for SelectTopNRows command from SSMS  ******/
--==========================================================================================================================================================

--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	

--========================================================================================================================================================== 
--06/02/20204		    Thirupathi      		    --07/23/20204  	1M  		 Bug: 11480  Rrefreshing Collateral Information -Part 4 Swap Collaterals - Account Level
--==========================================================================================================================================================

CREATE OR ALTER  PROCEDURE [dbo].[documentProcessing_GetDeedOfTrustInfo]

@CollateralInfoId BIGINT ,
@ApplicationId BIGINT


as
begin

BEGIN TRY
 DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[documentProcessing_GetDeedOfTrustInfo] ',@CollateralInfoId,',',@ApplicationId)

 if not exists ( select 1 from [DocumentProcessing.CollateralInformationDeedOfTrust] with(nolock) where ApplicationId=@ApplicationId)  
	Begin 
		select 
		ap.ApplicationID appid
		,id
	  ,[CollateralInfoId]
	  ,[VestingInformation]
      ,[GrantorCounty]
      ,[GrantorStateId]
      ,[LegalDescription]
      ,[PropertyCounty]
      ,[PurposetoWitId]
      ,[PurposetoWitVerbiage]
      ,[PhysicalAddress]
	  ,[AddressLine2]
	  ,[Street]
      ,[City]
      ,[County]
      ,[State]
      ,[Zip]
	  ,[Country]
      ,[IsAdditionalNotesSecured]
      ,[AdditionalNotesSecuredText]
      ,[AdditionalBorrowersSecured]
      ,CIT.[ApplicationId] 
	   ,[VolumeNumber]
      ,[PageNumber]
      ,[FillingNumber]
      ,case when  [DeedofTrustDate] is null then 
		CASE WHEN AP.LoanRequestTypeId=1166 THEN AP.DateCreated ELSE AP.RenewalDateOpened END  
		else
		[DeedofTrustDate]
		END as [DeedofTrustDate]
      ,[OriginalTrustee]
	  ,[RenewalCounty]
	  ,[RenewalState]

	,[CIsImprovements]
	,[CPermanentLender]
	,[ConstAmount]
	,[CIsBorrowernotContractor]
	,[CContractor]
	,[CContractorAddress]
	,[CContractorAddressLine2]
	,[CContractorStreet]
	,[CContractorCity]
	,[CContractorState]
	,[CContractorCountry]
	,[CCounty]
	,[CContractorZip]
	  from  Application ap
	  Left outer join [dbo].[DocumentProcessing.CollateralInformationDeedOfTrust] CIT  WITH(NOLOCK)  on AP.ApplicationID= CIT.ApplicationId
	  where ap.ApplicationID  =@ApplicationId
	END

	ELSE 
	BEGIN 
		select Id
	  ,[CollateralInfoId]
	  ,[VestingInformation]
      ,[GrantorCounty]
      ,[GrantorStateId]
      ,[LegalDescription]
      ,[PropertyCounty]
      ,[PurposetoWitId]
      ,[PurposetoWitVerbiage]
      ,[PhysicalAddress]
	  ,[AddressLine2]
	  ,[Street]
      ,[City]
      ,[County]
      ,[State]
      ,[Zip]
	  ,[Country]
      ,[IsAdditionalNotesSecured]
      ,[AdditionalNotesSecuredText]
      ,[AdditionalBorrowersSecured]
      ,CIT.[ApplicationId] 
	   ,[VolumeNumber]
      ,[PageNumber]
      ,[FillingNumber]
      ,(case when  [DeedofTrustDate] is null then 
		CASE WHEN AP.LoanRequestTypeId=1166 THEN AP.DateCreated ELSE AP.RenewalDateOpened END  
		else
		[DeedofTrustDate]
		END) as DeedofTrustDate
      ,[OriginalTrustee]
	  ,[RenewalCounty]
	  ,[RenewalState]

	  	,[CIsImprovements]
	,[CPermanentLender]
	,[ConstAmount]
	,[CIsBorrowernotContractor]
	,[CContractor]
	,[CContractorAddress]
	,[CContractorAddressLine2]
	,[CContractorStreet]
	,[CContractorCity]
	,[CContractorState]
	,[CContractorCountry]
	,[CCounty]
	,[CContractorZip]
	  from  [dbo].[DocumentProcessing.CollateralInformationDeedOfTrust] CIT WITH(NOLOCK)
	  Left outer join Application Ap on AP.ApplicationID= CIT.ApplicationId
	  where CIT.ApplicationId =   @ApplicationId  and CIT.CollateralInfoId=@CollateralInfoId
	END

END TRY
BEGIN CATCH
    
      EXECUTE [dbo].[uspLogError] 'documentProcessing_GetDeedOfTrustInfo',NULL,@requestObject
	
	  --select @CompID
END CATCH
end
GO

