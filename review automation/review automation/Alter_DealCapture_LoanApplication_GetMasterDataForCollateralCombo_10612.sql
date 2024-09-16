/***************************************************************************************                                          
Name                 : [DealCapture.LoanApplication_selectApplicationNumber]       
Date Written         : 20-01-2020      
Author               : Ritesh Diyawar      
Project/System       : LMS Bank      
Description          : Get Master records       
Tables Used          : Horizon table       
Return Status        : Lsit                                   
========================================================================================*/  
--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--06/22/2024	        Soma     		07/23/2024   	1M  		 Bug: 10612  Rrefreshing Collateral Information -Part 4 Swap Collaterals.
--==========================================================================================================================================================
CREATE  OR ALTER  PROCEDURE [dbo].[DealCapture_LoanApplication_GetMasterDataForCollateralCombo]      
@applicationId bigint       
as      
Begin       
  BEGIN TRY  
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('[dbo].[DealCapture_LoanApplication_GetMasterDataForCollateralCombo] ',@applicationId)         
---------------------------------------------------------------------------      
SELECT Id  ValueId, [Name]  as ValueText, 'CollProductType' as TableName FROM [Master].[LoanCollProductType] WITH(NOLOCK) where IsActive = 1      
SELECT Id  ValueId, [Name]  as ValueText, 'CollSubProductType' as TableName FROM [Master].[LoanCollSubProductType] WITH(NOLOCK) where IsActive = 1      
SELECT Id  ValueId,[Name]  as ValueText, 'CollProductDescription' as TableName FROM [Master].[LoanCollProductDescription]  WITH(NOLOCK)  where IsActive = 1  order by [Name] asc   
SELECT Id  ValueId, [Name]  as ValueText, 'CollPropertyOccupancy' as TableName FROM [Master].[LoanCollPropertyOccupancy] WITH(NOLOCK) where IsActive = 1      
SELECT Id  ValueId, [Name]  as ValueText, 'CollOwnership' as TableName FROM [Master].[LoanCollOwnership] WITH(NOLOCK) where IsActive = 1      
SELECT Id  ValueId, [Name]  as ValueText, 'CollSourceOfValuation' as TableName FROM [Master].[LoanCollSourceOfValuation] WITH(NOLOCK) where IsActive = 1      
SELECT CountryID  ValueId, CountryName  as ValueText, 'CountryOfResidance' as TableName FROM [Master].[Country] WITH(NOLOCK) where IsActive = 1       
SELECT Id  ValueId, [Value]  as ValueText, 'CollFloodHazardStatus' as TableName FROM [Master].[LoanCollFloodHazardStatus] WITH(NOLOCK) where IsActive = 1      
SELECT CountryID  ValueId, CountryCode  as ValueText, 'CountryCodes' as TableName FROM [Master].[Country] WITH(NOLOCK) where IsActive = 1       
    
DROP TABLE IF EXISTS #Temp_CollateralOwners                    
    SELECT                 
    PartyID,          
    CustomerName,        
    IsAdditionalParty,
	CNUM
 INTO #Temp_CollateralOwners                
  from (              
SELECT             
C.CustomerID as PartyID,            
 isnull(C.FirstName,'') +' '+ isnull(C.LastName,'')  as CustomerName,            
 C.IsAdditionalParty,
 c.CNUM
from             
[dbo].[Application]  as A  WITH(NOLOCK)            
inner join AccountParty as AP with(nolock) on A.ApplicationID=AP.ApplicationId AND ap.IsPersonal = 1            
inner join Customer as C with(nolock) on AP.CustomerID=C.CustomerID  
inner join [Master].[LoanPartyRole] as LP with(nolock) on LP.id=AP.PartyRoleId  
Where  A.ApplicationID = @applicationId                  
and AP.IsActive = 1                
union all            
select            
C.CompanyID as PartyID,            
 isnull(CompanyName1,'') +' '+ isnull(CompanyName2,'')  as CustomerName,            
C.IsAdditionalParty,
c.CNUM
from             
[dbo].[Application]  as A  WITH(NOLOCK)            
inner join AccountParty as AP with(nolock) on A.ApplicationID=AP.ApplicationId  AND ap.IsPersonal = 0            
inner join Companies as C with(nolock) on AP.CustomerID=C.CompanyID  
inner join [Master].[LoanPartyRole] as LP with(nolock) on LP.id=AP.PartyRoleId  
Where  A.ApplicationID = @applicationId and AP.IsActive = 1          
 ) ctemp      
    
    
    
    
    
SELECT PartyID  ValueId, CustomerName  as ValueText,CNUM, 'PrimaryOwner' as TableName FROM #Temp_CollateralOwners WITH(NOLOCK) where IsAdditionalParty<>1      
SELECT PartyID  ValueId, CustomerName  as ValueText,CNUM, 'AdditionalOwner' as TableName FROM #Temp_CollateralOwners WITH(NOLOCK)   


SELECT           
 CDPT.Name as productTypeDesc,          
 CDPsT.Name as subProductDesc,          
 CDD.Name as description,          
 CDSVC.Name as valuationSourceDesc,          
 Lc.TypeId  as  ProductTypeId,          
 Lc.SubTypeId as ProductSubTypeId,          
 Lc.Description as ProductDescriptionId,          
 Lc.Code as ProductCode,          
 LC.Description as ID ,          
  CDD.Name as data          
 into #temp          
  From [dbo].[DealCapture.CollateralTypeMapping] LC WITH (NOLOCK)          
 --Inner join  [Common.ComboData] CDPT WITH (NOLOCK) on CDPT.MasterDataName ='CollProductType' and CDPT.Id = LC.TypeId           
 -- Left outer join  [Common.ComboData] CDPsT WITH (NOLOCK) on CDPsT.MasterDataName ='CollSubProductType' and CDPsT.Id = LC.SubTypeId          
 --Inner join  [Common.ComboData] CDD WITH (NOLOCK) on CDD.MasterDataName ='CollProductDescription' and CDD.Id = LC.Description          
 --Inner join  [Common.ComboData] CDSVC WITH (NOLOCK) on CDSVC.MasterDataName ='CollSourceOfValuation' and CDSVC.Id = LC.SourceEvalutionId          
 Inner join  [Master].[LoanCollProductType] CDPT WITH (NOLOCK) on  CDPT.Id = LC.TypeId   and CDPT.IsActive=1        
  Left outer join  [Master].[LoanCollSubProductType] CDPsT WITH (NOLOCK) on  CDPsT.Id = LC.SubTypeId  and CDPsT.IsActive=1        
 Inner join   [Master].[LoanCollProductDescription] CDD WITH (NOLOCK) on CDD.Id = LC.Description   and cdd.IsActive=1       
 Left outer join   [Master].[LoanCollSourceOfValuation] CDSVC WITH (NOLOCK) on CDSVC.Id = LC.SourceEvalutionId   and CDSVC.IsActive=1    
   
 select distinct   ID,data +'     '+ cast(ProductCode as varchar(100)) as DATA,ProductCode as code, 'CollProductMaster'  as TableName from #temp          
 Drop  table #temp     

 

  
SELECT Id  ValueId, [Name]  as ValueText, 'LienPosition' as TableName FROM [Master].[LienPosition] WITH(NOLOCK) where IsActive = 1      
SELECT Id  ValueId, [Position]  as ValueText, 'SubordinatePosition' as TableName FROM [Master].[SubordinatePosition] WITH(NOLOCK) where IsActive = 1      

 SELECT  [StateID] AS ValueId   ,TRIM([StateProvinceCode]) AS ValueText  from [HRZ].[State] WITH(NOLOCK) WHERE  CountryID=264
 SELECT  [StateID] AS ValueId   ,[StateName] AS ValueText  from [HRZ].[State] WITH(NOLOCK) WHERE  CountryID=45
 SELECT [StateID] AS ValueId   ,[StateName] AS ValueText  from [HRZ].[State] WITH(NOLOCK) WHERE  CountryID=165

--where  IsAdditionalParty=1     
-------------------------------------------------------------------     

select * from LoanCollSubProductType
END TRY  
  
BEGIN CATCH  
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_GetMasterDataForCollateralCombo]',NULL,@requestObject  
END CATCH  
      
End
GO

