-- Author: Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description : This is sp for DealCapture_LoanApplication_GetAllCollatrel
-- Modified By: Tejal Patel
-- Modified Date: 11 August 2023
-- Bug: 7363 : Removed Floodcert join and columns to avoid duplicate collateral record
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--04/28/2024	        soma     		    05/03/2024   	1M  		 Bug: 8999 add some extra field 
--06/02/2024		    Soma      		    --07/23/2024  	1M  		 Bug: 12176 Draw Enhancements for May Release
--==========================================================================================================================================================
CREATE  OR ALTER   PROCEDURE [dbo].[DealCapture_LoanApplication_GetAllCollatrel] --37680       
@applicationId int           
         
as           
Begin   
BEGIN TRY
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_LoanApplication_GetAllCollatrel] ',@applicationId) 

Select           
LC.[Id],           
LC.[ApplicationId] as loanApplicationId,           
[ProductTypeId],           
LC.CIF, LC.Seq,          
[CollateralAmount],          
[ValuationSourceId],           
[CollateralCode],           
[ValuationDate], [MaxLoanToVal],          
[OwnershipId], [IsNew],           
[IsUploadedToPrecision], [CollateralNarrative],          
[IsPrimaryCollateral], [SubProductId],          
[DescriptionId], [ProductCode], [PropertyOccupanyId],           
LC.[CreatedBy], LC.[CreatedDate], [UpdatedBy], [UpdatedDate],           
[IsDeleted], [Address],          
IsThisFirstLien,          
IsNonIBCDebt,       
PAccount AS PAccount,
trackseq AS TrackSeq,
AcctSeq AS acctSeq,
BankId,
NonIBCDebtAmount,  PolicyNumber ,PolicyHolderName ,PolicyValue   ,InsuranceCompany ,
Manufacturer 	,ModelName ,[Year],VIN  ,IssuerName  ,NumberofShares ,CUSIPNumber ,IssueDate,
VehicleMake ,VehicleModel ,LicensePlat ,County, Acres, TillableAcres, SquareFootage,
NumberofUnits, APNNumber, CensusTract, FloodHazardStatusID,
Comments,OwnershipId,IsNonIBCDebt,CollateralAmount,ValuationSourceId,ValuationDate,MaxLoanToVal,
[Address],Neighborhood,[State],City,ZipCode,Country,ProductTypeId,SubProductId,DescriptionId,ProductCode,PropertyOccupanyId,

CDPT.[Name] as productTypeDesc,          
CDSVC.[Name] as valuationSourceDesc ,          
 CDPsT.[Name] as subProductDesc,          
 CDD.[Name] as description,          
  CDOS.[Name] as propertyOccupanyDesc ,          
  1 as IsEdit,  
  iif(isnull(IsRenewalRecord,0)=1 and isnull(IsExclude,0)=0,1,0) as IsExclude,
  iif(isnull(IsRenewalRecord,0)=1 and isnull(IsExclude,0)=1,1,0) as IsInclude,
  iif(isnull(IsRenewalRecord,0)=0,1,0) as IsDelete          
   ,1 IsEditable          
   , Version           
   ,1 as CanSetPrimaryCollateral 
   ,IsRenewalRecord,
   SNo,
   AddressNumber,
    LienPositionId,
   SubordinatePositionId,
   IsAbundanceofCaution,
   [dbo].[fn_GetLtvExceedsMessage](LC.PreviousAllocatedAmount,LC.NewAllocatedAmount,LC.NonIBCDebtAmount,LC.LtvLimit,LC.CollateralAmount) AS LtvExceedsMessage 
   --,CASE WHEN fc.FloodCertStatus='Complete' then 0 else 1 END as IsFloodInProgress
   --,CASE WHEN fc.FloodCertID>0 THEN 1 ELSE 0 END as IsFloodApplicable
	from [DealCapture.LoanCollateralDetail] LC WITH (NOLOCK)          
  Left outer join  [Master].[LoanCollProductType] CDPT WITH (NOLOCK) on  CDPT.Id = LC.ProductTypeId and CDPT.IsActive=1          
 Left outer join  [Master].LoanCollSourceOfValuation CDSVC WITH (NOLOCK) on  CDSVC.Id = LC.ValuationSourceId  and CDSVC.IsActive=1         
 Left outer join  [Master].LoanCollSubProductType CDPsT WITH (NOLOCK) on CDPsT.Id = LC.SubProductId and CDPsT.IsActive=1         
 Left outer join  [Master].LoanCollProductDescription CDD WITH (NOLOCK) on  CDD.Id = LC.DescriptionId   and CDD.IsActive=1       
 Left outer join  [Master].LoanCollOwnership CDOS WITH (NOLOCK) on  CDOS.Id = LC.OwnershipId          
 --left join FloodCert as fc on lc.Id =fc.CollateralID    and fc.IsActive=1        
where lc.ApplicationId =@applicationId and  IsDeleted = 0 and lc.ProductCode<>1 --and isnull(IsExclude,0)=0

grant execute on to public
END TRY

BEGIN CATCH
EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_LoanApplication_GetAllCollatrel]',NULL,@requestObject
END CATCH
End
GO

