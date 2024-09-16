-- Author: Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description: DealCapture_LoanApplication_UpdateCollateral Stored Procedure
-- ETA < 1 min
--==========================================================================================================================================================
--Created Date        	Created By      	Review Date		ETA	  		Comments  														EXECUTE
--========================================================================================================================================================== 
--10/03/2023			Tejal Patel			10/17/2023		1M			BUG: 7897 Change CustomerID for floodcert documents               Execute on LMS database
--11/29/2023			Tejal Patel			11/29/2023		1M			BUG: 8581 Change CustomerID for floodcert documents               Execute on LMS database
--1/29/2023			    Tejal Patel		   02/23/2023		1M			BUG: 8772  for floodcert documents                                 Execute on LMS database
--03/11/2024			Pawan Shukla       05/03/2024		1M		    Bug:6094 : Abundance of caution collateral
--06/26/2024		    Pawan      		    07/23/2024   	1M  		 Bug: 10842 Rrefreshing Collateral Information- Part 6 Field Level Change Report
--==========================================================================================================================================================
CREATE   OR ALTER    PROCEDURE [dbo].[DealCapture_LoanApplication_UpdateCollateral]     
@AddressNumber varchar(10) =null,   
@LoanCollatrelID int,              
@LoanApplicationId int,              
@ProductTypeId int ,              
@CollateralAmount decimal(18, 2) ,              
@ValuationSourceId int ,              
@CollateralCode int ,              
@ValuationDate datetime ,              
@MaxLoanToVal decimal(18, 2) ,              
@OwnershipId int ,              
@IsNew bit ,              
@CollateralNarrative nvarchar(MAX) ,              
@IsPrimaryCollateral bit ,              
@SubProductId int ,              
@DescriptionId int ,              
@ProductCode int ,              
@PropertyOccupanyId int ,              
@CreatedBy nvarchar(200) ,              
@UpdatedBy nvarchar(200) ,              
@IsThisFirstLien bit,              
@IsNonIBCDebt  bit,              
@IBCNetDebt decimal(18,2),              
@NonIBCDebtAmount decimal(18,2),              
@ISsecured bit,              
@Address varchar(100),              
@Country varchar(100),              
@State varchar(100),              
@City  varchar(100),              
@ZipCode varchar(100),              
@Neighborhood varchar(100),              
@IsMailAddressSame bit              
,@CIF Varchar(100),              
 @seq int,              
 @Version nvarchar(max),              
   -- New Parmeter Add for US 4171              
                
--Life Insurance              
@PolicyNumber varchar(50)=null,               
@PolicyHolderName  varchar(50) =null,              
@PolicyValue Decimal(18,2)=0.00,              
@InsuranceCompany  varchar(50) =null,              
              
--End of Life Insurance              
              
--Start for Manufactured  Housing              
@Manufacturer  varchar(50) =null,              
@ModelName  varchar(50) =null,              
@Year int =0,              
              
--End  Manufactured  Housing              
              
-- Other/ Unclassified              
                         
@VIN  varchar(50) =null,              
              
--End  Other/ Unclassified              
              
--Start for Stock              
@IssuerName  varchar(50) =null ,              
@NumberofShares decimal(18,2) =0,              
@CUSIPNumber  varchar(50) =null,              
              
              
--End  Stock              
              
              
--Start for  Title Vehicle              
@VehicleMake  varchar(50) =null,              
@VehicleModel  varchar(50) =null,              
@LicensePlat  varchar(50) =null,              
--End  for  Title Vehicle              
--End of 4171 changes               
-- End of new Parameter for               
@PrimaryOwnerId bigint =0,            
@IsPledgor bit =null,           
@IsGrantor bit =null,           
@AdditionalOwners varchar(100)=NULL,            
            
@Comments varchar(250) =null,              
@DateManufactured datetime =null,            
@SerialNumber varchar(50) =null,              
@CertificateNumber varchar(50) =null,              
@LabelSealNo varchar(50) =null,              
@StateDoingBusinessIn int =null,              
@StateInc int =null,              
@FilingNumber varchar(50) =null,              
@FilingDateState varchar(50) =null,              
@County varchar(50) =null,              
@InstrumentNumber varchar(50) =null,              
@FilingDateCounty varchar(50) =null,              
@Type varchar(50) =null,              
@TypeDescription varchar(50) =null,              
@FilingDate  datetime =null,            
@IssueDate datetime =null,            
@Acres Decimal(18,2)=NULL,            
@TillableAcres Decimal(18,2)=NULL,            
@SquareFootage int =null,              
@NumberofUnits int =null,              
@APNNumber varchar(50) =null,              
@CensusTract varchar(50) =null,              
@FloodHazardStatusID int =null ,  
@LienPositionId int =null,   
@SubordinatePositionId int =null,  
@LtvLimit DECIMAL(18,2)=null,  
@NewRemainingEquityCv DECIMAL(18,2)=null,  
@NewRemainingEquityLtvLimit DECIMAL(18,2)=null,  
@NewAllocatedAmount DECIMAL(18,2)=null,  
@PreviousAllocatedAmount decimal(18,2)=null,  
@InitialRemainingEquityCv DECIMAL(18,2)= NULL,  
@LoanLevelLTV DECIMAL(18,2)= NULL,  
@IsAbundanceofCaution BIT=NULL,
@additionalOwnerList  AS CollateralAdditionalOwner readonly   
  
As              
BEGIN              
BEGIN TRY              
 BEGIN TRANSACTION              
 declare @NewVersionId uniqueIdentifier              
 declare @ErrorCode nvarchar(5) = '0'              
 set @NewVersionId = newid()              
              
Declare @LTV decimal(18,2)              
Declare @loanAmount decimal(18,2)              
Declare @netDebt decimal(18,2)              
Declare @ColleralAmountCalc decimal(18,2)    
Declare @loanRequestTypeId int ,
		@oldPrimaryOwnerID BIGINT
  DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('exec[dbo].[DealCapture_LoanApplication_UpdateCollateral]  ',@LoanApplicationId)  
              
SET @LTV = null;              
SET  @netDebt=isnull(@NonIBCDebtAmount,0)   

IF @IsAbundanceofCaution='true' AND EXISTS (SELECT TOP 1 Id FROM [DealCapture.LoanCollateralDetail] WHERE ApplicationId=@LoanApplicationId AND Id=@LoanCollatrelID AND IsNew=0 AND IsDeleted=0)
BEGIN
		-------Updating  Status Queue--------------------------------------------------------
	EXEC  [DealCapture_ApprovalQueue_StatusUpdate] 2,@LoanApplicationId,'','Decline'

	UPDATE CompareCoreMaintenance SET [Status]='Rejected' ,UpdatedBy='Delete Collatral-'+@UpdatedBy ,UpdatedDate=getdate() where PageScreenName='Collateral' 
	AND ApplicationId=@LoanApplicationId and ParentId=@LoanCollatrelID  

	IF NOT EXISTS (SELECT TOP 1 ApplicationId FROM CompareCoreMaintenance WHERE  ApplicationId=@LoanApplicationId  AND  ISNULL(Status,'Pending')='Pending')
	BEgin
		EXEC [dbo].[DealCapture_ApprovalQueue_StatusUpdate]  4, @LoanApplicationId,@UpdatedBy,'Approve'
	END
END
                   
SELECT @loanAmount = dbo.[fn_GetLoanAmount](@LoanApplicationId)      
SELECT @loanRequestTypeId =LoanRequestTypeId  FROM Application WITH(NOLOCK) WHERE   ApplicationID =@LoanApplicationId AND IsActive=1  
      
	--making Existing collateral as New if Abundance of Caution
     IF @IsAbundanceofCaution=1
	 BEGIN
		SET @CollateralAmount=0;
		SET @CIF=NULL;
		SET @IsNew=1  
		DELETE FROM CompareCoreMaintenance WHERE ApplicationId=@LoanApplicationId AND ParentId=@LoanCollatrelID AND PageScreenName='Collateral'
	 END
	 ELSE
	 BEGIN
	 IF( @CollateralAmount IS NULL OR  @CollateralAmount =0)              
		BEGIN               
		 SET @CollateralAmount = ( @loanAmount/@MaxLoanToVal)*100  
		END 
	 END
              
if(@IsPrimaryCollateral=1)              
    BEGIN   
  
	--  
 --Start Update IsPrimaryCollatreralChanged logic   
   
  DECLARE @IsPCollateral BIT=0  
 --Check is IsPrimaryCollateral Chnaged or not   
  select @IsPCollateral=IsPrimaryCollateral,@oldPrimaryOwnerID=PrimaryOwnerID  
  FROM [dbo].[DealCapture.LoanCollateralDetail]  
  WITH(NOLOCK) WHERE  ApplicationId = @LoanApplicationId  AND ID=@LoanCollatrelID  
    
  DECLARE @IsRenewal bit=0  
  select @IsRenewal =iif( LoanRequestTypeId=1167,1,0)  from Application with(nolock) where   ApplicationID =@LoanApplicationId AND IsActive=1  
  
  	
  
  IF @IsPCollateral=0 AND @IsRenewal=1  
  BEGIN   
  
     Declare @accountID int =0  
  select @accountID = ObjectIdentity   
  from ApplicationContents WITH(NOLOCK)  
  where ObjectType = 'Account' and ApplicationName =@LoanApplicationId  
  
  UPDATE Account SET IsPrimaryCollatreralChanged=1 WHERE AccountID=@accountID  
  
  END  
  --End Update IsPrimaryCollatreralChanged logic   
  
    Update [dbo].[DealCapture.LoanCollateralDetail] set IsPrimaryCollateral = 0  where ApplicationId = @LoanApplicationId              
    END              
             
    IF (NOT EXISTS ( SELECT * FROM [dbo].[DealCapture.LoanCollateralDetail] with(nolock)  WHERE ApplicationId = @LoanApplicationId AND [Version]=@version) AND               
      (SELECT TOP 1 ApplicationValue FROM ApplicationSettings with(nolock) WHERE ApplicationKey='IsVersionEnable' AND IsActive=1) = '1')              
    BEGIN              
   SET @ErrorCode='99'              
   RAISERROR('This application has been updated before submitting your changes. Please refresh the page and try again.',16,2)              
    END              
  
  
 declare @oldAddress varchar(500)  
 declare @OldProductCode  int 
  
 select @oldAddress=Address from [DealCapture.LoanCollateralDetail] with(nolock) where Id=@LoanCollatrelID 
 select @OldProductCode=ProductCode from [DealCapture.LoanCollateralDetail] with(nolock) where Id=@LoanCollatrelID  
  
Update [DealCapture.LoanCollateralDetail] set               
              
    AddressNumber =@AddressNumber,          
ProductTypeId = @ProductTypeId,              
CollateralAmount = @CollateralAmount,              
ValuationSourceId = @ValuationSourceId,              
CollateralCode=@CollateralCode,              
ValuationDate=@ValuationDate,              
MaxLoanToVal =@MaxLoanToVal,              
OwnershipId=@OwnershipId,              
IsNew=(case when Isnull(@isAbundanceofCaution,0)=1 then 1 else IsNew end), --//Commenting this as it is updating new collateral to existing  
--Changes made by Pallavi and ritesh            
              
CollateralNarrative=@CollateralNarrative,              
IsPrimaryCollateral=@IsPrimaryCollateral,              
SubProductId=@SubProductId,              
DescriptionId=@DescriptionId,              
ProductCode=@ProductCode,              
PropertyOccupanyId=@PropertyOccupanyId,              
UpdatedBy=@UpdatedBy,              
UpdatedDate=Getdate(),              
              
IsThisFirstLien =@IsThisFirstLien,              
IsNonIBCDebt  = @IsNonIBCDebt,              
IBCNetDebt=@IBCNetDebt,              
NonIBCDebtAmount = @NonIBCDebtAmount,              
              
Address = @Address ,              
Country=@Country  ,              
State=@State  ,              
City=@City ,              
ZipCode=@ZipCode  ,              
Neighborhood=@Neighborhood  ,              
IsMailAddressSame=@IsMailAddressSame,              
ltv=@LTV ,               
 [Version] = @NewVersionId,              
  [PolicyNumber] =@PolicyNumber              
           ,[PolicyHolderName] =@PolicyHolderName              
           ,[PolicyValue] =@PolicyValue              
           ,[InsuranceCompany] =@InsuranceCompany              
           ,[Manufacturer] =@Manufacturer              
           ,[ModelName] =@ModelName              
           ,[Year] =@Year              
           ,[VIN] =@VIN              
           ,[IssuerName] =@IssuerName              
           ,[NumberofShares] =@NumberofShares              
           ,[CUSIPNumber] =@CUSIPNumber              
           ,[VehicleMake] =@VehicleMake              
           ,[VehicleModel] =@VehicleModel              
           ,[LicensePlat] =@LicensePlat            
     ,[PrimaryOwnerId]=@PrimaryOwnerId            
     ,[IsPledgor]=@IsPledgor,            
    [Comments]= @Comments,              
[DateManufactured] = @DateManufactured ,            
SerialNumber= @SerialNumber,              
CertificateNumber= @CertificateNumber ,              
LabelSealNo= @LabelSealNo ,              
StateDoingBusinessInID= @StateDoingBusinessIn ,              
StateIncID = @StateInc ,              
FilingNumber = @FilingNumber,              
FilingDateState= @FilingDateState,              
County = @County ,              
InstrumentNumber = @InstrumentNumber,     
FilingDateCounty = @FilingDateCounty ,              
OtherType= @Type ,              
OtherTypeDescription= @TypeDescription ,              
FilingDate= @FilingDate  ,            
IssueDate= @IssueDate ,            
Acres= @Acres ,            
TillableAcres= @TillableAcres ,            
SquareFootage= @SquareFootage ,              
NumberofUnits= @NumberofUnits ,              
APNNumber= @APNNumber ,              
CensusTract= @CensusTract ,              
FloodHazardStatusID = @FloodHazardStatusID,   
LienPositionId =@LienPositionId,   
SubordinatePositionId  =@SubordinatePositionId,  
LtvLimit=@LtvLimit ,  
NewRemainingEquityCv=@NewRemainingEquityCv ,  
NewRemainingEquityLtvLimit=@NewRemainingEquityLtvLimit ,  
NewAllocatedAmount=@NewAllocatedAmount ,  
IsAbundanceofCaution=@IsAbundanceofCaution,
PreviousAllocatedAmount=@PreviousAllocatedAmount,  
InitialRemainingEquityCv=@InitialRemainingEquityCv  

--Abundance of caaution
,Seq=(Case when @IsAbundanceofCaution=1 then 0 else Seq END)
,Pkey=(Case when @IsAbundanceofCaution=1 then null else Pkey END)
,PAccount=(Case when @IsAbundanceofCaution=1 then 0 else PAccount END)
,trackseq=(Case when @IsAbundanceofCaution=1 then null else trackseq END)
,AcctSeq=(Case when @IsAbundanceofCaution=1 then null else AcctSeq END)

where               
--ApplicationId=@LoanApplicationId AND               
ID = @LoanCollatrelID              
             
--Update [DealCapture.LoanCollateralDetail] set IsSecuredLoanCollateral = @ISsecured where ApplicationId = @LoanApplicationId              
              
              
  Declare @UpdatedByUSer Varchar(100)              
set @UpdatedByUSer = isnull(@CreatedBy,@UpdatedBy)              
-- Loan Application  updte               
exec [DealCapture_LoanApplication_UpdateModifiedDate]  @LoanApplicationId, @UpdatedByUSer              
  --Select 1              
  /* Is Form flag Reset Code */              
  execute dbo.usp_IsFormFlagReset  @LoanApplicationId , 6              
  /* Is Form flag Reset Code */  
  
  Update FolderDocuments set IsActive=0 , UpdatedBy = 'DealCapture_LoanApplication_UpdateCollateral' where ApplicationId=@LoanApplicationId and CollateralId=@LoanCollatrelID   
  and DocumentID Not In(Select DocumentID from Documents where CompostionTypeId=2 or DocumentID in (224)) and isnull(IsExcluded,0) <> 1 ---DocumentID not in (83,84,92,93,189) and   
       
   Declare @LoanStatusId int     
   Declare @FloodNoticeDocumentID int,
			@OldProductTypeID int,
			@OldCollateralCode int

	Select @OldProductTypeID=ProductTypeId,@OldCollateralCode=CollateralCode from [AuditDealCapture.LoanCollateralDetail] where ApplicationId=@LoanApplicationId and ProductCode=@OldProductCode
   
  if  @OldProductTypeID<>@ProductTypeId AND @ProductTypeId<>1037
  begin  
   set @LoanStatusId = (SELECT ApplicationStatus from dbo.[Application] WITH(NOLOCK) where ApplicationID = @LoanApplicationId)      
   --set @FloodNoticeDocumentID=(SELECT CASE WHEN @loanRequestTypeId=1167 THEN 224 ELSE 93 END)  
    if (@LoanStatusId not in (1154,1156,1157,1158,1160,1170)) 
	--if (@ProductTypeId = 1037 AND @LoanStatusId not in (1154,1156,1157,1158,1160,1170,1167) OR(@LoanStatusId=1167 and @LoanStageId!=1))
   begin  

		Update FolderDocuments set IsActive=0,UpdatedBy='DealCapture_LoanApplication_UpdateCollateral', UpdatedDate=GETDATE()  
		WHERE ApplicationId=@LoanApplicationId and CollateralId=@LoanCollatrelID and DocumentID in (83,84,92,189,224,93)  
 
		Update FloodCert set isactive=0 ,CreatedBy='[dbo].[DealCapture_LoanApplication_UpdateCollateral]',CreatedDate=GETDATE()   
		WHERE ApplicationID=@LoanApplicationId and CollateralID=@LoanCollatrelID  
  
		UPDATE FloodCertDouments SET IsActive=0,CreatedBy='[dbo].[DealCapture_LoanApplication_UpdateCollateral]',CreateDate=GETDATE()  
		WHERE ApplicationID=@LoanApplicationId AND CollateralID=@LoanCollatrelID     

   end  
  end



  --else if  @oldPrimaryOwnerID<>@PrimaryOwnerId
  --BEGIN
		--Update FolderDocuments set CustomerID=@PrimaryOwnerId,UpdatedBy='DealCapture_LoanApplication_UpdateCollateral', UpdatedDate=GETDATE()  
		--WHERE ApplicationId=@LoanApplicationId and CollateralId=@LoanCollatrelID and DocumentID in (83,84,92,189,224,93) 
  --END

   
   
  -- BEGIN INSERT INTO AUDIT TABLE            
  DECLARE @LoanStageId INT, @StageId INT, @Oldrecord INT            
  SELECT @LoanStageId = StageId FROM [Application] with(nolock) where ApplicationId = @LoanApplicationId            
  SELECT @StageId = ApplicationStatus FROM [Application] with(nolock) where ApplicationId = @LoanApplicationId       
            
 
 Insert into               
   [dbo].[AuditDealCapture.LoanCollateralDetail]              
   (Id, [ApplicationId],              
   [ProductTypeId],              
   [CollateralAmount],               
   [ValuationSourceId],              
   [CollateralCode],              
   [ValuationDate],              
   [MaxLoanToVal],               
   [OwnershipId],               
   [IsNew],               
   [CollateralNarrative],              
   [IsPrimaryCollateral],              
   [SubProductId],              
   [DescriptionId],              
   [ProductCode],              
   [PropertyOccupanyId],              
   CreatedBy,            
   CreatedDate,            
   [IsDeleted],              
   [Address],              
   IsThisFirstLien,              
   IsNonIBCDebt,              
   IBCNetDebt,              
   NonIBCDebtAmount,               
   Country ,              
   State ,              
   City  ,              
   ZipCode,              
   Neighborhood ,              
   IsMailAddressSame ,              
   LTV,              
   CIF,              
   Seq,              
    [PolicyNumber]              
           ,[PolicyHolderName]              
           ,[PolicyValue]              
           ,[InsuranceCompany]              
           ,[Manufacturer]              
           ,[ModelName]              
           ,[Year]              
           ,[VIN]              
       ,[IssuerName]              
           ,[NumberofShares]              
           ,[CUSIPNumber]              
           ,[VehicleMake]              
           ,[VehicleModel]              
           ,[LicensePlat]            
     ,[PrimaryOwnerId]            
     ,[IsPledgor],            
     [Comments]            
      ,[DateManufactured]            
      ,[SerialNumber]            
      ,[CertificateNumber]            
      ,[LabelSealNo]            
      ,[StateDoingBusinessInID]            
      ,[StateIncID]            
      ,[FilingNumber]            
      ,[FilingDateState]            
      ,[County]            
      ,[InstrumentNumber]            
      ,[FilingDateCounty]            
      ,[OtherType]            
      ,[OtherTypeDescription]            
      ,[FilingDate]            
      ,[IssueDate]            
      ,[Acres]            
      ,[TillableAcres]            
      ,[SquareFootage]            
      ,[NumberofUnits]            
      ,[APNNumber]            
      ,[CensusTract],            
  [FloodHazardStatusID]            
        ,[LoanStageId], [StatusId],  
  [LienPositionId],  
  [SubordinatePositionId]  
  ,[LtvLimit],  
  [NewRemainingEquityCv],  
  [NewRemainingEquityLtvLimit],  
  [NewAllocatedAmount],[PreviousAllocatedAmount],[InitialRemainingEquityCv],IsAbundanceofCaution)               
   Values(              
   @LoanCollatrelID,            
   @LoanApplicationId,               
   @ProductTypeId,              
   @CollateralAmount,              
   @ValuationSourceId,              
   @CollateralCode,              
   @ValuationDate,               
   @MaxLoanToVal,               
   @OwnershipId,              
   @IsNew,               
   @CollateralNarrative,              
   @IsPrimaryCollateral,              
   @SubProductId,               
   @DescriptionId,              
   @ProductCode,              
   @PropertyOccupanyId,              
   @UpdatedByUSer,            
   GETDATE(),            
   0,               
   @Address,              
   @IsThisFirstLien,              
   @IsNonIBCDebt,              
   @IBCNetDebt,              
   @NonIBCDebtAmount,              
   @Country ,              
   @State ,              
   @City  ,              
   @ZipCode,              
   @Neighborhood ,              
   @IsMailAddressSame,              
   @LTV,              
   @CIF,              
   @Seq,              
  @PolicyNumber              
           ,@PolicyHolderName              
           ,@PolicyValue              
           ,@InsuranceCompany              
           ,@Manufacturer              
           ,@ModelName              
           ,@Year              
           ,@VIN              
           ,@IssuerName              
           ,@NumberofShares              
           ,@CUSIPNumber              
           ,@VehicleMake              
           ,@VehicleModel              
           ,@LicensePlat            
     ,@PrimaryOwnerId             
     ,@IsPledgor            
    ,@Comments,            
     @DateManufactured,            
     @SerialNumber  ,            
     @CertificateNumber,            
@LabelSealNo,            
@StateDoingBusinessIn,            
@StateInc,            
@FilingNumber,            
@FilingDateState,            
@County,            
@InstrumentNumber,            
@FilingDateCounty,            
@Type,            
@TypeDescription,            
@FilingDate,            
@IssueDate,            
@Acres,            
@TillableAcres,            
@SquareFootage,            
@NumberofUnits,            
@APNNumber,            
@CensusTract,            
@FloodHazardStatusID            
,@LoanStageId, @StageId  
,@LienPositionId  
,@SubordinatePositionId  
, @LtvLimit,  
@NewRemainingEquityCv,  
@NewRemainingEquityLtvLimit,  
@NewAllocatedAmount,@PreviousAllocatedAmount,@InitialRemainingEquityCv,@IsAbundanceofCaution)     
  
 UPDATE [DealCapture.LoanCollateral] SET  LoanLevelLTV=@LoanLevelLTV WHERE LoanApplicationId = @LoanApplicationID  
  
    -- EXECUTE [DealCapture_LoanApplication_SaveAdditionalOwners]  @LoanCollatrelID,@LoanApplicationId,@AdditionalOwners, @IsPledgor,@IsGrantor     
 EXECUTE [DealCapture_LoanApplication_SaveAdditionalOwners]         @LoanCollatrelID, @additionalOwnerList    
  
 --update the  loan naretive  
  EXEC DealCapture_DeleteLoanNarretiveBased @LoanApplicationId  

  set @ErrorCode ='1'            
            
  COMMIT TRANSACTION     
   EXEC dbo.usp_IsFormFlagReset  @LoanApplicationId , 6   
   EXEC [dbo].[DealCapture_LoanApplication_InsertUnSecureCollateral]  @LoanApplicationId,@CreatedBy
 END TRY            
            
 BEGIN CATCH            
  --set @ErrorCode ='0'            
   set @NewVersionId= null             
              
  ROLLBACK TRANSACTION            
  EXECUTE [dbo].[uspLogError]    '[dbo].[DealCapture_LoanApplication_UpdateCollateral]',NULL,@requestObject         
 END CATCH            
 SELECT @ErrorCode as 'ErrorCode',@NewVersionId AS 'Version' , @LoanCollatrelID as 'LoanCollatrelID', @LoanApplicationId as 'ApplicationId'            
END
GO

