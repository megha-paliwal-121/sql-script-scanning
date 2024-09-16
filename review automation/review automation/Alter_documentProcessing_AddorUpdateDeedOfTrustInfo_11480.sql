-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the add or update deed of trust info 
-- ETA < 1 min
--==========================================================================================================================================================

--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	

--========================================================================================================================================================== 
--01/02/20204		    Soma      		    --02/23/20204  	1M  		 Bug: 7608 DB Error Log Checking 
--06/02/20204		    Thirupathi      		    --07/23/20204  	1M  		 Bug: 11480  Rrefreshing Collateral Information -Part 4 Swap Collaterals - Account Level
--==========================================================================================================================================================

/****** Script for SelectTopNRows command from SSMS  ******/

CREATE  OR ALTER   PROCEDURE [dbo].[documentProcessing_AddorUpdateDeedOfTrustInfo]
@Id BIGINT  ,
@CollateralInfoId BIGINT ,
@GrantorCounty nvarchar(150),
@GrantorStateId BIGINT ,
@LegalDescription nvarchar(max),
@PropertyCounty nvarchar(150),
@PurposetoWitId BIGINT ,
@PurposetoWitVerbiage nvarchar(max),
@PhysicalAddress nvarchar(150),
@AddressLine2 [nvarchar](100) ,
@Street [nvarchar](50),
@City nvarchar(150),
@County nvarchar(150),
@State bigint,
@Zip nvarchar(150),
@Country nvarchar(50),
@IsAdditionalNotesSecured bit,
@AdditionalNotesSecuredText nvarchar(max),
@AdditionalBorrowersSecured nvarchar(max),
@ApplicationId BIGINT,
@CreatedBy nvarchar(150),
@ModifiedBy nvarchar(150),
@VestingInfo nvarchar(max),
@VolumeNumber nvarchar(200),
 @PageNumber Varchar(200),
 @FillingNumber Varchar(MAX),    
 @DeedofTrustDate datetime,
 @OriginalTrustee varchar(500),
 @RenewalCounty varchar(200),
@RenewalState varchar(200),


@CIsImprovements bit,
@CPermanentLender varchar(300),
@ConstAmount decimal(18,2)=null,
@CIsBorrowernotContractor bit,
@CContractor varchar(300),
@CContractorAddress varchar(300),
@CContractorAddressLine2 [nvarchar](100) ,
@CContractorStreet [nvarchar](50),
@CContractorCity varchar(300),
@CContractorState bigint,
@CContractorCountry nvarchar(50),
@CCounty varchar(300),
@CContractorZip varchar(300)

as
begin

 DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[documentProcessing_AddorUpdateDeedOfTrustInfo] ',@ApplicationId)

declare @ErrorCode nvarchar(5) = '1'
BEGIN TRY
if (@Id=0)
begin
insert into [dbo].[DocumentProcessing.CollateralInformationDeedOfTrust] (   [CollateralInfoId]
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
	  ,Country
      ,[IsAdditionalNotesSecured]
      ,[AdditionalNotesSecuredText]
      ,[AdditionalBorrowersSecured]
      ,[ApplicationId]
      ,[CreatedBy]
      ,[CreatedDate]
	 , [VestingInformation]
	,[VolumeNumber] 
 ,[PageNumber] 
 ,[FillingNumber] 
 ,[DeedofTrustDate] 
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
      
	  ) values(
	
@CollateralInfoId  ,
@GrantorCounty ,
@GrantorStateId  ,
@LegalDescription, 
@PropertyCounty,
@PurposetoWitId,
@PurposetoWitVerbiage ,
@PhysicalAddress,
@AddressLine2,
@Street,
@City ,
@County ,
@State ,
@Zip ,
@Country,
@IsAdditionalNotesSecured,
@AdditionalNotesSecuredText ,
@AdditionalBorrowersSecured ,
@ApplicationId ,
@CreatedBy ,
GETDATE() ,
@VestingInfo,
@VolumeNumber ,
 @PageNumber ,
 @FillingNumber ,
 @DeedofTrustDate ,
 @OriginalTrustee ,
 @RenewalCounty,
@RenewalState,

@CIsImprovements,
@CPermanentLender,
@ConstAmount,
@CIsBorrowernotContractor,
@CContractor,
@CContractorAddress,
@CContractorAddressLine2 ,
@CContractorStreet,
@CContractorCity,
@CContractorState,
@CContractorCountry,
@CCounty,
@CContractorZip
)
end
else
begin
update [dbo].[DocumentProcessing.CollateralInformationDeedOfTrust] set
 [CollateralInfoId]=@CollateralInfoId
      ,[GrantorCounty]=@GrantorCounty
      ,[GrantorStateId]=@GrantorStateId
      ,[LegalDescription]=@LegalDescription
      ,[PropertyCounty]=@PropertyCounty
      ,[PurposetoWitId]=@PurposetoWitId
      ,[PurposetoWitVerbiage]=@PurposetoWitVerbiage
      ,[PhysicalAddress]=@PhysicalAddress
	  ,[AddressLine2]=@AddressLine2
	  ,[Street]=@Street
      ,[City]=@City
      ,[County]=@County
      ,[State]=@State
      ,[Zip]=@Zip
	  ,[Country]=@Country
      ,[IsAdditionalNotesSecured]=@IsAdditionalNotesSecured
      ,[AdditionalNotesSecuredText]=@AdditionalNotesSecuredText
      ,[AdditionalBorrowersSecured]=@AdditionalBorrowersSecured
      ,[ApplicationId]=@ApplicationId 
	  ,[ModifiedBy]=@ModifiedBy
	  , [VestingInformation]=@VestingInfo
	  ,[VolumeNumber]=@VolumeNumber
      ,[PageNumber]=@PageNumber
      ,[FillingNumber]=@FillingNumber
      ,[DeedofTrustDate]=@DeedofTrustDate
      ,[OriginalTrustee]=@OriginalTrustee
	 , RenewalCounty=@RenewalCounty
      ,RenewalState=@RenewalState,

CIsImprovements	= @CIsImprovements,
CPermanentLender	=@CPermanentLender,
ConstAmount=@ConstAmount,
CIsBorrowernotContractor	=@CIsBorrowernotContractor,
CContractor	=@CContractor,
CContractorAddress	=@CContractorAddress,
CContractorAddressLine2 	=@CContractorAddressLine2 ,
CContractorStreet	=@CContractorStreet,
CContractorCity	=@CContractorCity,
CContractorState	=@CContractorState,
CContractorCountry=@CContractorCountry,
CCounty	=@CCounty,
CContractorZip	 = @CContractorZip
	  ,[ModifiedDate]=GETDATE()  where ID=@Id and ApplicationId =@ApplicationId
end



----- Start Re-Generate Document - Balaji ----		
execute dbo.usp_IsFormFlagReset  @ApplicationId , 19
----- END Re-Generate Document ----
END TRY
BEGIN CATCH

      EXECUTE [dbo].[uspLogError] '[documentProcessing_AddorUpdateDeedOfTrustInfo]',NULL,@requestObject
	  SET @ErrorCode='0'
	  --select @CompID
END CATCH
--SELECT @CompID AS CustomerID , @iApplicationID AS ApplicationID
if @ErrorCode =0  
begin 
  select 0 
end
else
begin 
 select 1
end 
 

end
GO

