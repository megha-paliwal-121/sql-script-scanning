-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 08/16/2023
-- Description : Stored Procedure to Get Core Maintenance Compare Fields With Data
-- Modified By: Pawan Shukla
-- Modified Date:08/18/2023
-- Bug :7327- Renewal FASB
-- Modified By: Soma
-- Modified Date:09/27/2023
-- Bug :7955- Unable to Approve Maintenance to Core
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date        	Modified By      Review Date    ETA		Comments  	
--========================================================================================================================================================== 
--12 OCT 2023		    Vikram 			12/10/2023    1M      8104:Compare to Core - Foreign Customer - Incorrect Values pulled as TIN Type,
--22 OCT 2023		    Soma 			21/10/2023    1M      8065:Issue Date and Expiration Date for Maria Compare to Core is wrong
--22 OCT 2023		    Soma 			11/11/2023    1M      8010:Renewal Precision Retreival and Upload Changes in Rule
--01/16/2024		    Ritesh		    02/23/2024	  1M	  BUG: 8754 Approval Queu       LMS
--05/16/2024		    Thirupathi		    07/23/2024	  1M	  BUG: 10282 Entity to be formed Validation on company info    
--==========================================================================================================================================================


CREATE  OR ALTER  PROCEDURE [dbo].[DealCapture_GetCoreMaintenanceComapareFieldsWithData]
(    
	@LmsTableName varchar(1000)='', 
	@LoanApplicationId int
)    
as    
begin   
BEGIN  TRY
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_GetCoreMaintenanceComapareFieldsWithData] ','''',@LmsTableName,',',@LoanApplicationId)

Declare @AuditTableName varchar(200),
	@query varchar(max),
	@PrecisionColumns varchar(MAX),
	@PrimaryKeyColumn varchar(200),
	@PrimaryKeyIds nvarchar(MAX),
	@ParentColumn varchar(200),
	@TempLMSTableName varchar(200),
	@TempAuditLMSTableName varchar(200)
IF OBJECT_ID('TEMPDB..#TempPrimaryKeyId') IS NOT NULL
	    DROP TABLE TEMPDB..#TempPrimaryKeyId
CREATE TABLE #TempPrimaryKeyId 
(
  items int 
)

IF OBJECT_ID('TEMPDB..#Temp_LMSTable') IS NOT NULL
	    DROP TABLE #Temp_LMSTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_table') IS NOT NULL
	    DROP TABLE #temp_audit_table

--------------------------------PartyInfo--------------------------------



If(@LmsTableName='Companies')
Begin
insert into #TempPrimaryKeyId select PartyID FROM Vw_AllLoanParties WITH (NOLOCK) where ApplicationID=@LoanApplicationId and CustomerType='C' and IsExistingParty=1 

PRINT

IF OBJECT_ID('TEMPDB..#Temp_LMSCompanyTable') IS NOT NULL
	    DROP TABLE #Temp_LMSCompanyTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_Companytable') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_Companytable

select lcd.CompanyID,CompanyName1,CompanyName2,hrzC.Data as PartnershipTypeID,cr.CountryName CountryOfRegistration,
		
		Case when isnull(lcd.IsForeign,0)=0 then lcd.TIN else null end as TIN,
		Case when isnull(lcd.IsForeign,0)=0 then tt.Data else null end as TINType,
		Case when lcd.CountryOfRegistrationID<>165 and lcd.IsForeign=1 then lcd.FTIN else '' end as FTIN,
		Case when lcd.CountryOfRegistrationID=165 and lcd.IsForeign=1 then lcd.RFC else '' end as RFC,
		[dbo].[fnFormatPhoneNumber]((case when PrimaryPhoneNumber like '%#%' then  RIGHT(PrimaryPhoneNumber, 10) 
		ELSE  PrimaryPhoneNumber end)) as PrimaryPhoneNumber,ppt.Data PrimaryPhoneType,
		'+'+cast(cc.[DialingCode] as varchar(max))+ ' - '+ cc.[CountryName] PrimaryCountryCode,
		[dbo].[fnFormatPhoneNumber]((case when SecondaryPhoneNumber like '%#%' then  RIGHT(SecondaryPhoneNumber, 10) 
		ELSE  SecondaryPhoneNumber end)) as SecondaryPhoneNumber,spt.Data SecondaryPhoneType,
		'+'+cast(Scc.[DialingCode] as varchar(max))+ ' - '+ Scc.[CountryName] SecondaryCountryCode,
		lcd.Website,lcd.EmailAddress
into  #Temp_LMSCompanyTable from Companies lcd WITH (NOLOCK)
Left Join   [hrz].ComboValues hrzC WITH (NOLOCK) on hrzC.Rec_id = lcd.CompanyTypeID and   [key] in ('CompanyType')
LEFT JOIN [master].[Country] cr WITH (NOLOCK) on lcd.CountryOfRegistrationID=cr.CountryId
LEFT JOIN [hrz].ComboValues tt WITH (NOLOCK) on lcd.TINType=tt.Rec_id and  tt.[key] =  'TaxIDType'  
--LEFT JOIN [hrz].ComboValues bt WITH (NOLOCK) on lcd.BusinessTypeID=bt.Rec_id and  bt.[key] like  '%BusinessType%'   
LEFT JOIN [hrz].ComboValues ppt WITH (NOLOCK) on lcd.PrimaryPhoneTypeID=ppt.Rec_id and  ppt.[key] like  '%PhoneType%'   
LEFT JOIN [master].CountryCodes cc WITH (NOLOCK) on lcd.PrimaryCountryCode=cc.CountryCodeID
LEFT JOIN [hrz].ComboValues spt WITH (NOLOCK) on lcd.SecondaryPhoneTypeID=spt.Rec_id and  spt.[key] like  '%PhoneType%'

LEFT JOIN [master].CountryCodes Scc WITH (NOLOCK) on lcd.SecondaryCountryCode=Scc.CountryCodeID
where lcd.CompanyID in (select items from #TempPrimaryKeyId)

;with cte as
		(
		SELECT t.CompanyID,t.CompanyName1,t.CompanyName2,t.CompanyTypeID,t.CountryOfRegistrationID, 
		Case when isnull(t.IsForeign,0)=0 then t.TIN else null end as TIN,
		Case when isnull(t.IsForeign,0)=0 then t.TINType else 0 end as TINType,
		Case when t.CountryOfRegistrationID<>165 and t.IsForeign=1 then t.FTIN else '' end as FTIN,
		Case when t.CountryOfRegistrationID=165 and t.IsForeign=1 then t.RFC else '' end as RFC,
		t.IsForeign,
		[dbo].[fnFormatPhoneNumber](t.PrimaryPhoneNumber) as PrimaryPhoneNumber,t.PrimaryPhoneTypeID,t.PrimaryCountryCode,
		[dbo].[fnFormatPhoneNumber](t.SecondaryPhoneNumber) as SecondaryPhoneNumber,t.SecondaryPhoneTypeID,t.SecondaryCountryCode,
		t.Website,t.EmailAddress, 
		ROW_NUMBER() OVER(partition by CompanyID ORDER BY CreatedDate asc) AS RowNumber
		FROM Audit_Companies t WITH(NOLOCK) where t.CompanyID  in (select items from #TempPrimaryKeyId)
		) 
select  cte.CompanyID,Isnull(CompanyName1,'') as CompanyName1 ,Isnull(CompanyName2,'') CompanyName2,hrzC.Data as PartnershipTypeID,cr.CountryName CountryOfRegistration,
TIN,tt.Data TINType,FTIN,RFC,
PrimaryPhoneNumber,ppt.Data PrimaryPhoneType,'+'+cast(cc.[DialingCode] as varchar(max))+ ' - '+ cc.[CountryName] PrimaryCountryCode,
SecondaryPhoneNumber,spt.Data SecondaryPhoneType,
		'+'+cast(Scc.[DialingCode] as varchar(max))+ ' - '+ Scc.[CountryName] SecondaryCountryCode,
cte.Website,cte.EmailAddress
into #temp_audit_Companytable from cte
Left Join   [hrz].ComboValues hrzC WITH (NOLOCK) on hrzC.Rec_id = cte.CompanyTypeID and   [key] in ('CompanyType')
LEFT JOIN [master].[Country] cr WITH (NOLOCK) on cte.CountryOfRegistrationID=cr.CountryId
LEFT JOIN [hrz].ComboValues tt WITH (NOLOCK) on cte.TINType=tt.Rec_id and  tt.[key] =  'TaxIDType'  
--LEFT JOIN [hrz].ComboValues bt WITH (NOLOCK) on cte.BusinessTypeID=bt.Rec_id and  bt.[key] like  '%BusinessType%'  
LEFT JOIN [hrz].ComboValues ppt WITH (NOLOCK) on cte.PrimaryPhoneTypeID=ppt.Rec_id and  ppt.[key] like  '%PhoneType%'
LEFT JOIN [hrz].ComboValues spt WITH (NOLOCK) on cte.SecondaryPhoneTypeID=spt.Rec_id and  spt.[key] like  '%PhoneType%'

LEFT JOIN [master].CountryCodes cc WITH (NOLOCK) on cte.PrimaryCountryCode=cc.CountryCodeID

LEFT JOIN [master].CountryCodes Scc WITH (NOLOCK) on cte.SecondaryCountryCode=Scc.CountryCodeID
where cte.CompanyID in (select items from #TempPrimaryKeyId)

 and   RowNumber=1

 
 --set @precisionColumns='CompanyID,CompanyName2,EntityType,CountryOfRegistration,TIN,TINType,BusinessType,IsDomestic,PrimaryPhoneNumber,PrimaryPhoneType,PrimaryCountryCode,SecondaryPhoneNumber,SecondaryPhoneType,SecondaryCountryCode,Website,EmailAddress,FsDate'
 select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='Companies'
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='CompanyID'
set @ParentColumn ='CompanyID'

set @TempLMSTableName='#Temp_LMSCompanyTable'
set @TempAuditLMSTableName='#temp_audit_Companytable'
End

ELSE
IF(@LmsTableName='Customer')
Begin
delete from #TempPrimaryKeyId
insert into #TempPrimaryKeyId select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType='P' and IsExistingParty=1 


IF OBJECT_ID('TEMPDB..#Temp_LMSCustomerTable') IS NOT NULL
	    DROP TABLE #Temp_LMSCustomerTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_Customertable') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_Customertable

		select lcd.CustomerId,FirstName,LastName,
		ps.Data Suffix,lcd.Birthdate,
		[dbo].[fnFormatPhoneNumber]((case when PrimaryPhoneNumber like '%#%' then  RIGHT(PrimaryPhoneNumber, 10) 
		ELSE  PrimaryPhoneNumber end)) as PrimaryPhoneNumber,ppt.Data PrimaryPhoneType,
				'+'+cast(cc.[DialingCode] as varchar(max))+ ' - '+ cc.[CountryName] PrimaryCountryCode,
				[dbo].[fnFormatPhoneNumber]((case when SecondaryPhoneNumber like '%#%' then  RIGHT(SecondaryPhoneNumber, 10) 
				ELSE  SecondaryPhoneNumber end)) as SecondaryPhoneNumber,spt.Data SecondaryPhoneType,
				'+'+cast(Scc.[DialingCode] as varchar(max))+ ' - '+ Scc.[CountryName] SecondaryCountryCode,
				lcd.EmailAddress,(CASE WHEN SSN='000000000' THEN null else SSN end) as SSN,
				Case when lcd.CountryOfResidence<>'165' and lcd.IsForeign=1 then isnull(lcd.FTIN,'') else '' end as FTIN,
				Case when lcd.CountryOfResidence='165' and lcd.IsForeign=1 then isnull(lcd.RFC,'') else '' end as RFC,
				Case when lcd.CountryOfResidence='165' and lcd.IsForeign=1 then isnull(lcd.CURP,'') else '' end as CURP,
				ppi.Data PrimaryID,lcd.PrimaryIDNumber,lcd.PrimaryIDIssued,lcd.PrimaryIDExpiration,
				pst.StateProvinceCode as PrimaryStateID
				,spi.Data SecondaryId,lcd.SecondaryIDNumber,lcd.SecondaryIDIssued,lcd.SecondaryIDExpiration,
				sst.StateProvinceCode SecondaryStateID
				,cr.CountryName CountryOfResidence
				,pcr.CountryName PassportCountry
		into  #Temp_LMSCustomerTable from Customer lcd
		LEFT JOIN [hrz].ComboValues ps WITH(NOLOCK) on lcd.SuffixID=ps.Rec_id and  ps.[key] like  '%PersonSuffix%' 

		LEFT JOIN [master].CountryCodes cc WITH (NOLOCK) on lcd.PrimaryCountryCode=cc.CountryCodeID
		LEFT JOIN [hrz].ComboValues ppt WITH (NOLOCK) on lcd.PrimaryPhoneTypeID=ppt.Rec_id and  ppt.[key] like  '%PhoneType%'
		LEFT JOIN [hrz].ComboValues spt WITH (NOLOCK) on lcd.SecondaryPhoneTypeID=spt.Rec_id and  spt.[key] like  '%PhoneType%'
		LEFT JOIN [master].CountryCodes Scc WITH (NOLOCK) on lcd.SecondaryCountryCode=Scc.CountryCodeID
		LEFT JOIN [hrz].ComboValues ppi WITH (NOLOCK) on lcd.PrimaryID=spt.Rec_id and  ppi.[key] like  '%PersonPrimaryID%'
		LEFT JOIN [hrz].[State] pst WITH (NOLOCK) on lcd.PrimaryStateID=pst.StateID

		LEFT JOIN [hrz].ComboValues spi WITH (NOLOCK) on lcd.SecondaryID=spt.Rec_id and  ppi.[key] =  'PersonSecondaryID'  and ppi.Rec_id<>3190  
		LEFT JOIN [hrz].[State] sst WITH (NOLOCK) on lcd.SecondaryStateID=sst.StateID
		LEFT JOIN [master].[Country] cr WITH (NOLOCK) on lcd.CountryOfResidence=cr.CountryId
		LEFT JOIN [master].[Country] pcr WITH (NOLOCK) on TRY_CAST(lcd.PassportCountry AS INT)=pcr.CountryId
		where lcd.CustomerId in (select items from #TempPrimaryKeyId)

;with cte as
		(
		SELECT t.CustomerId,t.FirstName,t.LastName,
		t.SuffixID,t.Birthdate,
[dbo].[fnFormatPhoneNumber]((case when PrimaryPhoneNumber like '%#%' then  RIGHT(PrimaryPhoneNumber, 10) 
ELSE  PrimaryPhoneNumber end)) as PrimaryPhoneNumber,t.PrimaryPhoneTypeID,
		t.PrimaryCountryCode,
		[dbo].[fnFormatPhoneNumber]((case when SecondaryPhoneNumber like '%#%' then  RIGHT(SecondaryPhoneNumber, 10) 
ELSE  SecondaryPhoneNumber end)) as SecondaryPhoneNumber,t.SecondaryPhoneTypeID,
		t.SecondaryCountryCode,
		t.EmailAddress,(CASE WHEN SSN='000000000' THEN null else SSN end) as SSN,
		Case when t.CountryOfResidence<>'165' and t.IsForeign=1 then isnull(t.FTIN,'') else '' end as FTIN,
		Case when t.CountryOfResidence='165' and t.IsForeign=1 then isnull(t.RFC,'') else '' end as RFC,
		Case when t.CountryOfResidence='165' and t.IsForeign=1 then isnull(t.CURP,'') else '' end as CURP,
		t.PrimaryID,t.PrimaryIDNumber,t.PrimaryIDIssued,t.PrimaryIDExpiration,
		t.PrimaryStateID
		,t.SecondaryID,t.SecondaryIDNumber,t.SecondaryIDIssued,t.SecondaryIDExpiration,t.SecondaryStateID
		,t.CountryOfResidence
		,t.PassportCountry
		,t.IsEmailVerified
		
		,ROW_NUMBER() OVER(partition by CustomerId ORDER BY CreatedDate asc) AS RowNumber
		FROM Audit_Customer t WITH (NOLOCK) where t.CustomerId  in (select items from #TempPrimaryKeyId)
		) 
SELECT  cte.CustomerId,cte.FirstName,cte.LastName,
		ps.Data Suffix,cte.Birthdate,
		PrimaryPhoneNumber,ppt.Data PrimaryPhoneType,
		'+'+cast(cc.[DialingCode] as varchar(max))+ ' - '+ cc.[CountryName] PrimaryCountryCode,
		SecondaryPhoneNumber,spt.Data SecondaryPhoneType,
		'+'+cast(Scc.[DialingCode] as varchar(max))+ ' - '+ Scc.[CountryName] SecondaryCountryCode,
		cte.EmailAddress,(CASE WHEN SSN='000000000' THEN null else SSN end) as SSN,
		cte.FTIN,cte.RFC,cte.CURP,
		ppi.Data PrimaryID,cte.PrimaryIDNumber,cte.PrimaryIDIssued,cte.PrimaryIDExpiration,
		pst.StateProvinceCode PrimaryStateID
		,spi.Data SecondaryId,cte.SecondaryIDNumber,cte.SecondaryIDIssued,cte.SecondaryIDExpiration,
		sst.StateProvinceCode SecondaryStateID
		,cr.CountryName CountryOfResidence
		,pcr.CountryName PassportCountry
into #temp_audit_Customertable from cte
LEFT JOIN [hrz].ComboValues ps WITH (NOLOCK) on cte.SuffixID=ps.Rec_id and  ps.[key] like  '%PersonSuffix%' 
LEFT JOIN [master].CountryCodes cc WITH (NOLOCK) on cte.PrimaryCountryCode=cc.CountryCodeID
LEFT JOIN [hrz].ComboValues ppt WITH (NOLOCK) on cte.PrimaryPhoneTypeID=ppt.Rec_id and  ppt.[key] like  '%PhoneType%'
LEFT JOIN [hrz].ComboValues spt WITH (NOLOCK) on cte.SecondaryPhoneTypeID=spt.Rec_id and  spt.[key] like  '%PhoneType%'
LEFT JOIN [master].CountryCodes Scc WITH (NOLOCK) on cte.SecondaryCountryCode=Scc.CountryCodeID
LEFT JOIN [hrz].ComboValues ppi WITH (NOLOCK) on cte.PrimaryID=spt.Rec_id and  ppi.[key] like  '%PersonPrimaryID%'
LEFT JOIN [hrz].[State] pst WITH (NOLOCK) on cte.PrimaryStateID=pst.StateID
LEFT JOIN [hrz].ComboValues spi WITH (NOLOCK) on cte.SecondaryID=spt.Rec_id and  ppi.[key] =  'PersonSecondaryID'  and ppi.Rec_id<>3190  
LEFT JOIN [hrz].[State] sst WITH (NOLOCK) on cte.SecondaryStateID=sst.StateID
LEFT JOIN [master].[Country] cr WITH (NOLOCK) on cte.CountryOfResidence=cr.CountryId
LEFT JOIN [master].[Country] pcr WITH (NOLOCK)  on TRY_CAST(cte.PassportCountry AS INT)=pcr.CountryId
where cte.CustomerId in (select items from #TempPrimaryKeyId)
and   RowNumber=1
--SET @precisionColumns='CustomerId,FirstName,LastName,Suffix,Birthdate,PrimaryPhoneNumber,PrimaryPhoneType,PrimaryCountryCode,SecondaryPhoneNumber,SecondaryPhoneType,SecondaryCountryCode,EmailAddress,SSN,PrimaryID,PrimaryIDNumber,PrimaryIDIssued,PrimaryIDExpiration,PrimaryState,SecondaryId,SecondaryIDNumber,SecondaryIDIssued,SecondaryIDExpiration,SecondaryState,CountryOfResidence,PassportCountry,EmailVerification'
select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='Customer'
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='CustomerId'
set @ParentColumn ='CustomerId'

set @TempLMSTableName='#Temp_LMSCustomerTable'
set @TempAuditLMSTableName='#temp_audit_Customertable'
End

ELSE IF(@LmsTableName='PartyPhysicalAddress')
Begin
delete from #TempPrimaryKeyId

insert into #TempPrimaryKeyId select AddressId from [Address] WITH (NOLOCK) where IsActive = 1  and  ParentID in(select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType in('C','P') and IsExistingParty=1)

 IF OBJECT_ID('TEMPDB..#Temp_LMSPartyAddressTable') IS NOT NULL
	    DROP TABLE #Temp_LMSPartyAddressTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_PartyAddresstable') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_PartyAddresstable

select lcd.AddressId,lcd.ParentID,Address1,Address2,City,State,Zip,Country, rg.Name Region,
IsMailing,AddressType
into  #Temp_LMSPartyAddressTable from Address lcd WITH(NOLOCK)
LEFT JOIN [master].Region rg WITH(NOLOCK) on lcd.Region=rg.Id  
where lcd.IsMailing <> 1 and  lcd.IsActive=1 and  ApplicationId=@LoanApplicationId and lcd.AddressId in (select items from #TempPrimaryKeyId)

;with cte as
		(
		SELECT t.AddressId,t.ParentID,Address1,Address2,City,State,Zip,Country,Region,IsMailing, AddressType,ROW_NUMBER() OVER(partition by AddressId ORDER BY CreatedDate asc) AS RowNumber
		FROM Audit_Address t WITH (NOLOCK) where t.IsActive=1 and t.IsMailing <> 1 and t.ApplicationId=@LoanApplicationId and  t.AddressId  in (select items from #TempPrimaryKeyId)
		) 
select  cte.AddressId,cte.ParentID,cte.Address1,Address2,City,State,Zip,Country,rg.Name Region,IsMailing ,AddressType
into #temp_audit_PartyAddresstable from cte
LEFT JOIN [master].Region rg WITH(NOLOCK) on cte.Region=rg.Id

where cte.AddressId in (select items from #TempPrimaryKeyId)

 and   RowNumber=1

 Update #Temp_LMSPartyAddressTable set Addressid  = Adt.addressid
from #temp_audit_PartyAddresstable Adt where  #Temp_LMSPartyAddressTable.parentid = adt.parentId and  #Temp_LMSPartyAddressTable.AddressType = adt.AddressType

 --set @precisionColumns='AddressId,Address1,Address2,City,State,Zip,Country,Region,IsMailing'
 select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='PartyPhysicalAddress'
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='AddressId'
set @ParentColumn ='ParentID'

set @TempLMSTableName='#Temp_LMSPartyAddressTable'
set @TempAuditLMSTableName='#temp_audit_PartyAddresstable'
End
ELSE IF(@LmsTableName='PartyMailingAddress')
Begin

delete from #TempPrimaryKeyId
insert into #TempPrimaryKeyId 
select AddressId from [Address] WITH (NOLOCK) where   ParentID in(select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType in('C','P') and IsExistingParty=1)
--select AddressId from [Address] WITH (NOLOCK) where  isactive =1  and ParentID in(select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType in('C','P') and IsExistingParty=1)

 IF OBJECT_ID('TEMPDB..#Temp_LMSPartyMailingAddress') IS NOT NULL
	    DROP TABLE #Temp_LMSPartyAddressTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_PartyMailingAddresstable') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_PartyMailingAddresstable

select lcd.AddressId,lcd.ParentID,lcd.Address1 MailingAddress1,Address2 MailingAddress2,City MailingCity,State MailingState,Zip MailingZip,cnt.CountryName as  MailingCountry,rg.Name MailingRegion,
IsMailing,AddressType
into  #Temp_LMSPartyMailingAddress from Address lcd WITH(NOLOCK)
LEFT JOIN [master].Region rg WITH(NOLOCK) on lcd.Region=rg.Id
LEFT JOIN [master].Country cnt WITH(NOLOCK) on cnt.CountryID=lcd.Country
where lcd.IsMailing = 1 and  ApplicationId=@LoanApplicationId and lcd.AddressId in (select items from #TempPrimaryKeyId) and lcd.IsActive=1

;with cte as
		(
		SELECT t.AddressId,t.ParentID,Address1,Address2,City,State,Zip,cnt.CountryName as Country,Region,IsMailing, AddressType,
ROW_NUMBER() OVER(partition by ParentId ORDER BY t.CreatedDate asc) AS RowNumber
		FROM Audit_Address t WITH (NOLOCK) 
		LEFT JOIN [master].Country cnt WITH(NOLOCK) on cnt.CountryID=t.Country
		where t.IsActive=1 and t.IsMailing = 1 and  t.ApplicationId=@LoanApplicationId  

		and t.AddressId  in (select AddressId from [Address] WITH (NOLOCK) where   ParentID in(select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType in('C','P') and IsExistingParty=1))
		) 
select  cte.AddressId,cte.ParentID,cte.Address1 MailingAddress1,Address2 MailingAddress2,City MailingCity,State MailingState,Zip MailingZip,Country MailingCountry,rg.Name MailingRegion,IsMailing ,AddressType
into #temp_audit_PartyMailingAddresstable from cte
LEFT JOIN [master].Region rg WITH(NOLOCK) on isnull(cte.Region,0)=rg.Id
where cte.AddressId 
in (select AddressId from [Address] WITH (NOLOCK) where   ParentID in(select PartyID FROM Vw_AllLoanParties where ApplicationID=@LoanApplicationId and CustomerType in('C','P') and IsExistingParty=1))
 and   RowNumber=1

 Update #temp_audit_PartyMailingAddresstable set Addressid  = Adt.addressid
from #Temp_LMSPartyMailingAddress Adt where  #temp_audit_PartyMailingAddresstable.parentid = adt.parentId and  #temp_audit_PartyMailingAddresstable.AddressType = adt.AddressType

 --set @precisionColumns='AddressId,MailingAddress1,MailingAddress2,MailingCity,MailingState,MailingZip,MailingCountry,MailingRegion,IsMailing'
select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='PartyMailingAddress'
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='AddressId'
set @ParentColumn ='ParentID'



set @TempLMSTableName='#Temp_LMSPartyMailingAddress'
set @TempAuditLMSTableName='#temp_audit_PartyMailingAddresstable'

--select * from #Temp_LMSPartyMailingAddress
--select * from  #temp_audit_PartyMailingAddresstable
End

--------------------------------Collateral----------------------------
ELSE If(@LmsTableName='LoanCollateralDetail')
Begin

IF OBJECT_ID('TEMPDB..#Temp_LMSCollateralTable') IS NOT NULL
	    DROP TABLE TEMPDB..#Temp_LMSCollateralTable

		
IF OBJECT_ID('TEMPDB..#temp_audit_Collateraltable') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_Collateraltable

insert into #TempPrimaryKeyId select Id FROM [DealCapture.LoanCollateralDetail] WITH(NOLOCK) where ApplicationID=@LoanApplicationId  and ISNULL(IsNew,0)=0 
and IsDeleted=0 and isNull(IsExclude,0)=0 and isnull(IsAbundanceofCaution,0)=0


select lcd.Id,
--mpo.Name as PropertyOccupancy,
lcd.CollateralAmount,
lcd.ValuationDate,lcd.MaxLoanToVal,
lco.Name Ownership,lcd.IsNew,lcd.Comments,
lcpt.Name ProductTypeID
,lcSpt.Name SubProductID,
lcpd.[Description] DescriptionID,
lcd.ProductCode,lcd.LTV,lcd.[Address] Address,
cr.CountryName Country,lcd.State,lcd.City,lcd.ZipCode,
--lcd.IsMailAddressSame,
lcd.Neighborhood,lcd.Seq,lcd.NonIBCDebtAmount,
--lcd.IBCNetDebt,
lcd.SquareFootage,REPLACE(lcd.APNNumber,'-','') as APNNumber,lcd.CensusTract
,lcd.County,lcd.Acres,lcd.TillableAcres,lcd.NumberofUnits
into #Temp_LMSCollateralTable from [DealCapture.LoanCollateralDetail] lcd WITH (NOLOCK)
--LEFT JOIN [Master].[LoanCollPropertyOccupancy] mpo WITH (NOLOCK) on lcd.PropertyOccupanyId=mpo.Id
LEFT JOIN [Master].[LoanCollProductType] lcpt WITH (NOLOCK) on lcd.ProductTypeId=lcpt.Id
LEFT JOIN [master].[LoanCollOwnership] lco WITH (NOLOCK) on lcd.OwnershipId=lco.Id
LEFT JOIN [master].[LoanCollProductType] lcSpt WITH (NOLOCK) on lcd.SubProductId=lcSpt.Id
LEFT JOIN [master].[LoanCollProductDescription] lcpd WITH (NOLOCK) on lcd.DescriptionId=lcpd.Id
LEFT JOIN [master].[Country] cr WITH(NOLOCK) on lcd.Country=cr.CountryID
where lcd.id in (select items from #TempPrimaryKeyId) and ISNULL(lcd.IsNew,0)=0 and lcd.IsDeleted=0

;with cte as
		(
		SELECT t.Id,t.PropertyOccupanyId,
t.CollateralAmount,
t.ValuationDate,t.MaxLoanToVal,
t.OwnershipId,t.IsNew,t.Comments,
t.ProductTypeId,t.SubProductId,t.DescriptionId,
t.ProductCode,t.LTV,t.[Address] Address,
t.Country,t.State,t.City,t.ZipCode,
--t.IsMailAddressSame,
t.Neighborhood,t.Seq,ISNULL(t.NonIBCDebtAmount,0.00) as NonIBCDebtAmount,
--t.IBCNetDebt,
t.SquareFootage,REPLACE(t.APNNumber,'-','') as APNNumber,t.CensusTract
,t.County,t.Acres,t.TillableAcres,t.NumberofUnits
		,ROW_NUMBER() OVER(partition by id ORDER BY CreatedDate asc) AS RowNumber

		FROM [AuditDealCapture.LoanCollateralDetail] t WITH (NOLOCK) where t.Id in(select items from #TempPrimaryKeyId)
		) 
select  
cte.Id,
--mpo.Name as PropertyOccupancy,
cte.CollateralAmount,
cte.ValuationDate,cte.MaxLoanToVal,
lco.Name Ownership,cte.IsNew,cte.Comments,
lcpt.Name ProductTypeID ,lcSpt.Name SubProductID,
lcpd.[Description] DescriptionID,
cte.ProductCode,cte.LTV,cte.[Address] Address,
cr.CountryName Country,cte.State,cte.City,cte.ZipCode,
--cte.IsMailAddressSame,
cte.Neighborhood,cte.Seq,cte.NonIBCDebtAmount,
--cte.IBCNetDebt,
cte.SquareFootage,cte.APNNumber,cte.CensusTract
,cte.County,cte.Acres,cte.TillableAcres,cte.NumberofUnits
into #temp_audit_Collateraltable from cte
--LEFT JOIN [Master].[LoanCollPropertyOccupancy] mpo WITH (NOLOCK) on cte.PropertyOccupanyId=mpo.Id
LEFT JOIN [Master].[LoanCollProductType] lcpt WITH (NOLOCK) on cte.ProductTypeId=lcpt.Id
LEFT JOIN [master].[LoanCollOwnership] lco WITH (NOLOCK) on cte.OwnershipId=lco.Id
LEFT JOIN [master].[LoanCollProductType] lcSpt WITH (NOLOCK) on cte.SubProductId=lcSpt.Id
LEFT JOIN [master].[LoanCollProductDescription] lcpd WITH (NOLOCK) on cte.DescriptionId=lcpd.Id
LEFT JOIN [master].[Country] cr WITH(NOLOCK) on cte.Country=cr.CountryID

where cte.id in (select items from #TempPrimaryKeyId)
 and   RowNumber=1

 --set @precisionColumns='Id,PropertyOccupancy,CollateralAmount,ValuationSource,CollateralCode,ValuationDate,MaxLoanToVal,Ownershp,IsNew,CollateralNarrative,IsPrimaryCollateral,ProductType,SubProduct,Description,ProductCode,LTV,Address,Country,State,City,ZipCode,IsMailAddressSame,Neighborhood,Seq,NonIBCDebtAmount,IBCNetDebt'
select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='LoanCollateralDetail' and fieldname<>'CollateralCode'
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='Id'
set @ParentColumn ='Id'

set @TempLMSTableName='#Temp_LMSCollateralTable'
set @TempAuditLMSTableName='#temp_audit_Collateraltable'
End 
--------------------------------LoanDetails----------------------------
ELSE If(@LmsTableName='LoanDetails')
Begin

 IF OBJECT_ID('TEMPDB..#Temp_LoanCreditMemoTable') IS NOT NULL
	    DROP TABLE TEMPDB..#Temp_LoanCreditMemoTable

		
 IF OBJECT_ID('TEMPDB..#temp_audit_LoanCreditMemo') IS NOT NULL
	    DROP TABLE TEMPDB..#temp_audit_LoanCreditMemo



insert into #TempPrimaryKeyId select l.Loanapplicationid FROM [DealCapture.LoanCreditMemo] l WITH(NOLOCK) 

INNER JOIN Application A WITH(NOLOCK) ON A.ApplicationID = l.LoanApplicationId
where Loanapplicationid=@LoanApplicationId  and A.LoanRequestTypeId=1167


select lcd.Loanapplicationid Id,lcd.LoanAmount,
mpo.Name as AdvanceTypeID ,
lp.Name as LoanPurposeID,uof.Name as UseOfFundsID,
lcd.LetterofCredit, (Case when lcd.ExistingLetterId=1 then 'Yes' else 'No' end) ExistingLetter,
af.AttorneyFirmName AttorneyLawFirm,A.LoanAccountNumber,
ddi.Name DepositoryInstitutionTypeID, (Case when lcd.ISCommitmentChanged=1 then 'Yes' else 'No' end) ISCommitmentChanged,lcd.NewTotalCommitment
,cc.Name AS CreditCodeId, 
st.Code as SpecialTrackingCode,
OB.RiskWeight,
--(Case when isnull(OB.RiskWeight,0)=0 THEN 'NA' ELSE OB.RiskWeight end)as RiskWeight,
OB.[LRGRelationshipCode]
,OB.[GrossAnnualRevenue]
,OB.AmoritizationPeriod
,reg.Code [Region]
,OB.PesoRisk
,[InterestCarry]
,[FHLBIneligible]
,OB.[REPurpose]
,OB.[supervisoryLtv]
,OB.[PartInvestorLoanNumber]
,OB.[CDCollateralRate]
,[origLnAmt]
,OB.[LCAmt]
,OB.[BalloonMaturityDate]
,OB.[BalloonAmortizationTerm]
,OB.[RepaymentMethodId]
,OB.[DateNewPaymentDue]

,OB.[NoticeCode]
,OBA.Address1
,OBA.[City],OBA.[State],OBA.[ZipCode]
,MS.Code as [MiscCodeId] 
,clt.Name as CRAloantypeID
,crc.Name as CRArevcodeID
,rpm.Name as RePaymentMethod
,cpf.Name as ChangeInPaymentFrequencyID
,NSC.Name as  NAICSCodeID
,OB.purpose
,AC.LoanOfficer
into #Temp_LoanCreditMemoTable 
from [DealCapture.LoanCreditMemo] lcd WITH (NOLOCK)
INNER JOIN Application A WITH(NOLOCK) ON A.ApplicationID = lcd.LoanApplicationId
Left Join [Master].[Loanadvancetype] mpo WITH (NOLOCK) on lcd.AdvanceTypeId=mpo.Id
Left Join [Master].[LoanPurpose] lp WITH (NOLOCK) on lcd.LoanPurposeID=lp.Id and lp.Isactive=1
Left Join [Master].UseofFunds uof WITH (NOLOCK) on lcd.UseofFundsId=uof.Id and uof.Isactive=1
Left Join [Master].AttorneyFirm af WITH (NOLOCK) on A.AttorneyLawFirmID=af.Id and af.Isactive=1
Left Join [Master].[LoanDomesticDepositoryInstitutionType] ddi WITH (NOLOCK) on lcd.DepositoryInstitutionTypeID=ddi.Id
LEFT JOIN [PreFunding.AdditionalOnboarding]  OB WITH(NOLOCK) ON lcd.LoanApplicationId=OB.LoanApplicationId
LEFT JOIN [AdditionalOnboardingAddress]  OBA WITH(NOLOCK) ON lcd.LoanApplicationId=OBA.ApplicationId
LEFT JOIN [Master].CreditCode cc WITH(NOLOCK) ON OB.CreditCodeId=CC.Id 
LEFT JOIN [Master].SpecialTracking st WITH(NOLOCK) ON OB.SpecialTrackingId=st.Id 
LEFT JOIN [Master].MiscCode MS WITH(NOLOCK) ON OB.MiscCodeId=MS.Id 
LEFT JOIN [Master.CRAloantype] clt WITH(NOLOCK) ON OB.CraLoanTypeId=clt.Id 
LEFT JOIN [Master].ChangeInPaymentFrequency cpf WITH(NOLOCK) ON OB.ChangeInPaymentFrequencyId=cpf.Id 
LEFT JOIN [Master.CRArevcode] crc WITH(NOLOCK) ON OB.CraRevCodeId=crc.Id 
LEFT JOIN [Master].RepaymentMethods rpm WITH(NOLOCK) ON OB.RepaymentMethodId=rpm.Id 
LEFT JOIN [Master].[Region] reg WITH(NOLOCK) ON OB.Region=reg.Id 
LEFT join Master.NAICSCode NSC on NSC.Id =LCD.NAICSCodeID
LEFT JOIN Account AC on AC.ApplicationID=A.ApplicationID
where lcd.Loanapplicationid=@LoanApplicationId and A.LoanRequestTypeId=1167

drop table if exists #Team_LoansToMature
select top 1 Accountnumber,ApplicationID,LM.IntitalLoanOfficer  into #Team_LoansToMature from
Account AC JOIN
LoansToMature LM on AC.AccountNumber=LM.LoanAccountNumber
where Ac.ApplicationID=@LoanApplicationId

;with cte as
		(
		SELECT t.Loanapplicationid Id,t.LoanAmount,
t.AdditionalDetails,t.AdvanceTypeId,t.LoanPurposeId,t.UseofFundsId,
t.LetterofCredit, (Case when t.ExistingLetterid=1 then 'Yes' else 'No' end) ExistingLetter
,t.DepositoryInstitutionTypeID,t.Loanapplicationid,cc.Name AS CreditCodeId, 
OBt.RiskWeight,
OBt.SpecialtrackingId,
OBt.[LRGRelationshipCode]
,OBt.[MiscCodeId]
,  [CraLoanTypeId]
,OBt.[CraRevCodeId] 
,OBt.[GrossAnnualRevenue]
,OBt.AmoritizationPeriod
,OBt.[Region]
,OBt.PesoRisk
,[InterestCarry]
,[FHLBIneligible]
,OBt.[REPurpose]
,OBt.[supervisoryLtv]
,OBt.[PartInvestorLoanNumber]
,OBt.[CDCollateralRate]
,OBt.[origLnAmt]
,OBt.[LCAmt]
,OBt.[BalloonMaturityDate]
,OBt.[BalloonAmortizationTerm]
,OBt.[RepaymentMethodId]
,OBt.[DateNewPaymentDue]
,OBt.[ChangeInPaymentFrequencyId]
,OBt.[NoticeCode]
,OBA.Address1
,OBA.[City],OBA.[State],OBA.[ZipCode]
,t.NAICSCodeID
,(Case when t.ISCommitmentChanged=1 then 'Yes' else 'No' end) ISCommitmentChanged,
t.NewTotalCommitment,		
OBT.Purpose,
		ROW_NUMBER() OVER(partition by T.Loanapplicationid ORDER BY T.CreatedDate asc) AS RowNumber
		
		FROM [AuditDealCapture.LoanCreditMemo] t WITH (NOLOCK)
		INNER JOIN Application A WITH(NOLOCK) ON A.ApplicationID = t.LoanApplicationId
		LEFT JOIN [Audit_PreFunding.AdditionalOnboarding]  OBt WITH(NOLOCK) ON A.ApplicationID=OBt.LoanApplicationId
		LEFT JOIN [Audit_AdditionalOnboardingAddress]  OBA WITH(NOLOCK) ON A.ApplicationID=OBA.ApplicationId
		LEFT JOIN [Master].CreditCode cc WITH(NOLOCK) ON OBT.CreditCodeId=CC.Id 

		where t.Loanapplicationid =@Loanapplicationid and A.LoanRequestTypeId=1167
		) 

select cte.Id,cte.LoanAmount,
mpo.Name as AdvanceTypeID,lp.Name as LoanPurposeID,uof.Name as UseOfFundsID,
cte.LetterofCredit,cte.ExistingLetter ,
af.AttorneyFirmName AttorneyLawFirm,A.LoanAccountNumber,
ddi.Name DepositoryInstitutionTypeID,ISCommitmentChanged,cte.NewTotalCommitment,
cte.CreditCodeId, 
st.Code as SpecialTrackingCode,
(Case when isnull(cte.RiskWeight,0)=0 THEN 'NA' ELSE cte.RiskWeight end)as RiskWeight,
cte.[LRGRelationshipCode] 
,cte.[GrossAnnualRevenue]
,cte.AmoritizationPeriod
,reg.Code [Region]
,cte.PesoRisk
,[InterestCarry]
,[FHLBIneligible]
,cte.[REPurpose]
,cte.[supervisoryLtv]
,cte.[PartInvestorLoanNumber]
,cte.[CDCollateralRate]
,cte.[origLnAmt]
,cte.[LCAmt]
,cte.[BalloonMaturityDate]
,cte.[BalloonAmortizationTerm]
,cte.[DateNewPaymentDue]
,cte.[NoticeCode]
,cte.Address1
,cte.[City],cte.[State],cte.[ZipCode]
,MS.Code as [MiscCodeId] 
,clt.Code as CRAloantypeID
,crc.Name as CRArevcodeID
,rpm.Code as RePaymentMethodID
,cpf.Name as ChangeInPaymentFrequencyID
,NSc.Name as NAICSCodeID
,CTE.Purpose as purpose
,LT.IntitalLoanOfficer as LoanOfficer
into #temp_audit_LoanCreditMemo from cte
INNER JOIN Application A WITH(NOLOCK) ON A.ApplicationID = cte.LoanApplicationId
Left Join [Master].[Loanadvancetype] mpo WITH (NOLOCK) on cte.AdvanceTypeId=mpo.Id
Left Join [Master].[LoanPurpose] lp WITH (NOLOCK) on cte.LoanPurposeID=lp.Id and lp.Isactive=1
Left Join [Master].UseofFunds uof WITH (NOLOCK) on cte.UseofFundsId=uof.Id and uof.Isactive=1
Left Join [Master].AttorneyFirm af WITH (NOLOCK) on A.AttorneyLawFirmID=af.Id and af.Isactive=1 
LEFT JOIN [Master].SpecialTracking st WITH(NOLOCK) ON cte.SpecialTrackingId=st.Id 
LEFT JOIN [Master].MiscCode MS WITH(NOLOCK) ON cte.MiscCodeId=MS.Id 
LEFT JOIN [Master.CRAloantype] clt WITH(NOLOCK) ON cte.CraLoanTypeId=clt.Id 
LEFT JOIN [Master].ChangeInPaymentFrequency cpf WITH(NOLOCK) ON cte.ChangeInPaymentFrequencyId=cpf.Id 
LEFT JOIN [Master.CRArevcode] crc WITH(NOLOCK) ON cte.CraRevCodeId=crc.Id 
LEFT JOIN [Master].RepaymentMethods rpm WITH(NOLOCK) ON cte.RepaymentMethodId=rpm.Id 
LEFT JOIN [Master].[Region] reg WITH(NOLOCK) ON cte.Region=reg.Id 
Left Join [Master].[LoanDomesticDepositoryInstitutionType] ddi WITH (NOLOCK) on cte.DepositoryInstitutionTypeID=ddi.Id
LEFT join Master.NAICSCode NSC on NSC.Id =cte.NAICSCodeID
LEFT JOIN #Team_LoansToMature LT on LT.ApplicationID=cte.LoanApplicationId

where cte.Loanapplicationid in (@Loanapplicationid)
 and   RowNumber=1

 --set @precisionColumns='Id,LoanAmount,UseoFFundnarrative,AdvanceType,LoanPurpose,UseOfFunds,LetterofCredit,ExistingLetter,AttorneyLawFirm,LoanAccountNumber,COVID19Impact,DepositoryInstitutionType,ISCommitmentChanged,NewTotalCommitment'
 select @PrecisionColumns = COALESCE(@PrecisionColumns + ',', '') + FieldName FROM [master].[precisionFields] where TableName='LoanDetails' and  IsActive=1
select @precisionColumns = 'A.' + replace(@precisionColumns, ',', ',A.');
set @PrimaryKeyColumn='Id'
set @ParentColumn ='Id'

set @TempLMSTableName='#Temp_LoanCreditMemoTable'
set @TempAuditLMSTableName='#temp_audit_LoanCreditMemo'
End

	set @query =N'
	select * into #Temp_LMSTable from '+@TempLMSTableName+' 
	select * into #Temp_audit_Table from '+@TempAuditLMSTableName+' 
	drop  table '+@TempLMSTableName+' 
	drop table '+@TempAuditLMSTableName+' 
		Select  '+ @PrimaryKeyColumn +
      ' Id, ParentId,[key] FieldName
      ,Org_Value = max( case when Src=2 then Isnull(Value,'''') end)
      ,New_Value = max( case when Src=1 then Isnull(Value,'''') end)
	  ,null DisplayField
 From (
        Select Src=1
              ,'+ @PrimaryKeyColumn +' 
			  ,'+@ParentColumn+' ParentId
              ,B.*
         From   #Temp_LMSTable A 
		
         Cross Apply ( Select [Key] 
                             ,Value
                       From OpenJson( (Select '+@precisionColumns+' For JSON Path,Without_Array_Wrapper,INCLUDE_NULL_VALUES  ) ) 
                     )  B
					 where A.'+ @PrimaryKeyColumn +' in(select items from #TempPrimaryKeyId)
					 
        Union All
	 Select Src=2
              ,'+ @PrimaryKeyColumn +' 
			   ,'+@ParentColumn+' ParentId
              ,B.*
         From #temp_audit_table A 
         Cross Apply ( Select [Key] 
                             ,Value
                       From OpenJson( (Select '+@precisionColumns+' For JSON Path,Without_Array_Wrapper,INCLUDE_NULL_VALUES  ) ) 
                     )  B
      ) A where A.'+ @PrimaryKeyColumn +' in(select items from #TempPrimaryKeyId)
 Group By '+ @PrimaryKeyColumn +',[key] ,ParentId
 Having max( case when Src=1 then Isnull(Value,'''') end)
     <> max( case when Src=2 then Isnull(Value,'''') end)
 Order By '+ @PrimaryKeyColumn +',[key]
 
 drop table #Temp_LMSTable
 drop table #temp_audit_table'
	exec(@query)
END TRY
BEGIN CATCH
	EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_GetCoreMaintenanceComapareFieldsWithData]',NULL,@requestObject
	END CATCH
end
GO

