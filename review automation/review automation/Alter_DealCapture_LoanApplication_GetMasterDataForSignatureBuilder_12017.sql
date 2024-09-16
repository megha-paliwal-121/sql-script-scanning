 -- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 06 March 2024
-- Description:   Data Script
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date		Modified By      	Review Date		ETA	  	Comments  	
--========================================================================================================================================================== 
--09/14/22		    Tejal Patel         09/14/2023		1M      Bug:7858 - Remove withAddress for Company Type that don't exist in LMSCompanyType table
--09/14/22		    Tejal Patel         11/11/2023		1M      Bug:8115 - Notary block on guaranty agreement
--06/10/24				Soma	    	06/10/2024		1M      Bug:12017 - Signature Preview loan #2180044917
--==========================================================================================================================================================
CREATE OR ALTER  PROCEDURE [dbo].[DealCapture_LoanApplication_GetMasterDataForSignatureBuilder]  --35671 -- 36345 --33928
@ApplicationID bigint  
as   
BEGIN   
BEGIN TRY 
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT(' EXEC [dbo].[DealCapture_LoanApplication_GetMasterDataForSignatureBuilder] ',@ApplicationID)         

select * from [master].Titles WITH(NOLOCK)   order by TitleName
SELECT   
@ApplicationID as ApplicationId,  
PartyId,  
CustomerFullName  as CustomerName,    --6746 LMS Adding Punctuation after the Name , previously it was fullname
RoleName,  
CustomerType,   
IsPrimaryBorrower,  
0 as IsAdditionalParty,  
--isnull(adr.Address1,'')  + ' ' + isnull(adr.Address2,'') + ' ' +  isnull(adr.City,'') + ' ' +   
Case  
when Isnull(ct.DocCompanyName,'') ='' OR ct.CompanyTypeID IN(3789,3790)  then  ''
when substring(St.StateName,1,1) ='a'  then  'An '+ isnull (St.StateName,'  ')+ ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='i'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='o'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='u'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='e'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when St.StateName  is not null     then  'A ' + isnull (St.StateName,'  ')  + ' ' + Isnull(ct.DocCompanyName,'')  
Else ' '  
end  
  
as withAddress,  
  
isnull(adr.Address1,'')  + ' ' + isnull(adr.Address2,'') + ' ' +  isnull(adr.City,'') + ' ' + isnull (AST.StateName,'  ')  
--Case   
--when substring(St.StateName,1,1) ='a'  then  'An '+ isnull (St.StateName,'  ')--+ ' ' + Isnull(CompanyType,'')  
--when substring(St.StateName,1,1) ='i'  then  'An '+ isnull (St.StateName,'  ')-- + ' ' + Isnull(CompanyType,'')  
--when substring(St.StateName,1,1) ='o'  then  'An '+ isnull (St.StateName,'  ')-- + ' ' + Isnull(CompanyType,'')  
--when substring(St.StateName,1,1) ='u'  then  'An '+ isnull (St.StateName,'  ')-- + ' ' + Isnull(CompanyType,'')  
--when substring(St.StateName,1,1) ='e'  then  'An '+ isnull (St.StateName,'  ') --+ ' ' + Isnull(CompanyType,'')  
--when St.StateName  is not null     then  'A ' + isnull  (St.StateName,'  ')  --+ ' ' + Isnull(CompanyType,'')  
--Else ' '  
--end  
  
as Address,  
  
  
  
ct.DocCompanyName As CompanyType,  
Vw_LoanParty.CompanyTypeId  ,
adr.IsMailing,
Adr.CreatedDate,
adr.AddressID
into #Temp
FROM  Vw_LoanParty   
Left outer join  Address adr WITH(NOLOCK) on adr.ApplicationId= Vw_LoanParty.ApplicationID and adr.IsActive=1 and Vw_LoanParty.PartyID = ParentID and IsMailing=0 and adr.LocationCode is not null
Left  outer Join [HRZ].State St WITH(NOLOCK) on St.StateID  = Vw_LoanParty.StateOfOrganization
Left  outer Join [HRZ].State AST WITH(NOLOCK) on (TRIM(AST.StateProvinceCode)=TRIM(adr.State)) OR (TRIM(AST.StateName)=TRIM(adr.State))
Left  outer Join master.LmscompanyType ct WITH(NOLOCK) On ct.CompanyTypeID = Vw_LoanParty.CompanyTypeId
where Vw_LoanParty.ApplicationID =@ApplicationID and Vw_LoanParty.IsActive=1  
UNION   
SELECT   
@ApplicationID as ApplicationId,  
PartyId,  
CustomerFullName as  CustomerName,    --6746 LMS Adding Punctuation after the Name , previously it was fullname
'',  
CustomerType,   
IsPrimaryBorrower,  
1 as IsAdditionalParty,  
  
Case  
when Isnull(ct.DocCompanyName,'') =''  OR ct.CompanyTypeID IN(3789,3790)  then  ''
when substring(St.StateName,1,1) ='a'  then  'An '+ isnull (St.StateName,'  ')+ ' '  + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='i'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='o'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='u'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when substring(St.StateName,1,1) ='e'  then  'An '+ isnull (St.StateName,'  ') + ' ' + Isnull(ct.DocCompanyName,'')  
when St.StateName  is not null     then  'A ' + isnull  (St.StateName,'  ')  + ' ' + Isnull(ct.DocCompanyName,'')  
Else ' '  
end  
  
as withAddress,  
  
isnull(adr.Address1,'')  + ' ' + isnull(adr.Address2,'') + ' ' +  isnull(adr.City,'') + ', ' +   
--Case   
--when substring(AST.StateName,1,1) ='a'  then  'An '+ isnull (AST.StateName,'  ')-- + ' ' + Isnull(CompanyType,'')  
--when substring(AST.StateName,1,1) ='i'  then  'An '+ isnull (AST.StateName,'  ') --+ ' ' + Isnull(CompanyType,'')  
--when substring(AST.StateName,1,1) ='o'  then  'An '+ isnull (AST.StateName,'  ') --+ ' ' + Isnull(CompanyType,'')  
--when substring(AST.StateName,1,1) ='u'  then  'An '+ isnull (AST.StateName,'  ') --+ ' ' + Isnull(CompanyType,'')  
--when substring(AST.StateName,1,1) ='e'  then  'An '+ isnull (AST.StateName,'  ')  --+ ' ' + Isnull(CompanyType,'')  
--when AST.StateName  is not null     then  'A ' + isnull  (AST.StateName,'  ')  --+ ' ' + Isnull(CompanyType,'')  
--Else ' '  
--end 
+isnull(AST.StateName,'')
Address,  
ct.DocCompanyName CompanyType, 

vw_LoanAdditionalPartyOnly.CompanyTypeId , 
IsMailing,
Adr.CreatedDate,
adr.AddressID
FROM  vw_LoanAdditionalPartyOnly   
Left outer join  Address adr WITH(NOLOCK) on adr.ApplicationId= vw_LoanAdditionalPartyOnly.ApplicationID and adr.IsActive=1 and vw_LoanAdditionalPartyOnly.PartyID = ParentID and IsMailing=0  --and adr.LocationCode is not null
and ((adr.AddressType = 4 and vw_LoanAdditionalPartyOnly.CustomerType = 'C') OR (adr.AddressType = 2 and vw_LoanAdditionalPartyOnly.CustomerType = 'P'))
Left  outer Join [HRZ].State St WITH(NOLOCK) on St.StateID  = vw_LoanAdditionalPartyOnly.StateOfOrganization
Left  outer Join [HRZ].State AST WITH(NOLOCK) on (TRIM(AST.StateProvinceCode)=TRIM(adr.State)) OR (TRIM(AST.StateName)=TRIM(adr.State))
Left  outer Join master.LmscompanyType ct WITH(NOLOCK) On ct.CompanyTypeID = vw_LoanAdditionalPartyOnly.CompanyTypeId
--Left outer join  Address adr WITH(NOLOCK) on adr.ApplicationId= vw_LoanAdditionalPartyOnly.ApplicationID and adr.IsActive=1 and vw_LoanAdditionalPartyOnly.PartyID = ParentID and IsMailing=0  
--Left outer Join [HRZ].State St WITH(NOLOCK) on St.StateID  = vw_LoanAdditionalPartyOnly.StateOfOrganization
--Left outer Join [HRZ].State AST WITH(NOLOCK) on (TRIM(AST.StateProvinceCode)=TRIM(adr.State)) OR (TRIM(AST.StateName)=TRIM(adr.State))  
--and vw_LoanAdditionalPartyOnly.PartyID= ParentID and IsMailing=0 and adr.IsActive=1  
where vw_LoanAdditionalPartyOnly.ApplicationID =@ApplicationID and vw_LoanAdditionalPartyOnly.IsActive=1 Order By CustomerName 


---Ritesh  this change because of in address table we have multiple records so  taking  first record 
select *, ROW_NUMBER() OVER(PARTITION BY partyId ORDER BY addressid DESC) AS  rnm into #result from #Temp --where  IsMailing=0
           
select * from #result where rnm=1

			   END TRY   

BEGIN CATCH              
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_GetMasterDataForSignatureBuilder]',NULL,@requestObject              
END CATCH   
  
END
GO

