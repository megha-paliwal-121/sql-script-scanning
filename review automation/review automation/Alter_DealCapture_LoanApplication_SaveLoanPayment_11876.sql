-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description:    - this  is  sp  for getting the save loan payment
-- ETA < 1 min
---==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--05/30/2024	        soma     		    05/30/2024   	1M				11876-Amortization increase in processing
--==========================================================================================================================================================
CREATE OR ALTER  PROCEDURE [dbo].[DealCapture_LoanApplication_SaveLoanPayment]        
@LoanPaymentID int,        
@LoanApplicationID  int ,        
@IsDaysPerYear int,        
@IsAutoPaymentLoan bit,        
@BankTypeId int,        
@AccountNumber varchar(100),        
@RoutingNumber varchar(100),        
@BankName varchar(100),        
@AccountTypeId int,        
@CreatedBy nvarchar(200),        
@UpdatedBy nvarchar(200),         
@BankId int,        
@Version nvarchar(200)      
,@OverridePaymentScheduleDetail Varchar(MAX)=null    
,@OverrideMaturityDate Datetime=null    
,@IsLeaveDateBlankDocuments Bit=0    
,@IsOverrideMaturityDate Bit=0    
,@IsOverridePaymentScheduleDetail Bit=0    
,@ISAmortization bit =0  
,@AmortizationUnitinMonth decimal  (18,1) 
,@AccountType varchar(500)  
,@DateOfNote Datetime = null
,@PrimaryOwner varchar(200) = null  
        
AS         
Begin         
BEGIN TRY        
BEGIN TRANSACTION  
     DECLARE  @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_LoanApplication_SaveLoanPayment] ',@LoanApplicationId)  
  
 declare @NewVersionId uniqueIdentifier        
 declare @ErrorCode nvarchar(5) = '0'        
 set @NewVersionId = newid()   
 declare @oldDateNote Datetime  
 declare @emptyGuid uniqueIdentifier
 Set @emptyGuid = (select cast(cast(0 as binary) as uniqueidentifier))
 if Not exists(select 1 from [DealCapture.LoanPayment]  WITH(NOLOCK) where LoanApplicationId = @LoanApplicationID and IsDeleted =0)        
  Begin        
        
  Insert into [dbo].[DealCapture.LoanPayment]         
   ( [LoanApplicationId], [DaysPerYearId], [IsAutoPaymentLoan], [BankTypeId], [AccountNumber], [RoutingNumber], [BankName], [AccountTypeId], [CreatedBy], [CreatedDate], [UpdatedBy], [UpdatedDate], [IsDeleted],BankId,[OverridePaymentScheduleDetail]
   ,[OverrideMaturityDate],[IsLeaveDateBlankDocuments],[IsOverrideMaturityDate],[IsOverridePaymentScheduleDetail],[ISAmortization] ,[AmortizationUnitinMonth] ,[AccountType],[DateOfNote],[PrimaryOwner] )    
  Values        
   (@LoanApplicationId, @IsDaysPerYear, @IsAutoPaymentLoan, @BankTypeId, @AccountNumber, @RoutingNumber, @BankName, @AccountTypeId, @CreatedBy, Getdate(), @UpdatedBy, Getdate(), 0,@BankId, @OverridePaymentScheduleDetail, @OverrideMaturityDate,
   @IsLeaveDateBlankDocuments, @IsOverrideMaturityDate, @IsOverridePaymentScheduleDetail,@ISAmortization,@AmortizationUnitinMonth,@AccountType,@DateOfNote,@PrimaryOwner)  
     END         
  ELSE         
  BEGIN   
  
   IF NOT EXISTS ( SELECT * FROM [dbo].[DealCapture.LoanPayment] with(nolock) WHERE LoanApplicationId = @LoanApplicationId AND [Version]=@version )
   AND     
      ((SELECT TOP 1 ApplicationValue FROM ApplicationSettings with(nolock) 
	  WHERE ApplicationKey='IsVersionEnable' AND IsActive=1) = '1') 
	  AND @version != @emptyGuid
    BEGIN        
       SET @ErrorCode='99'        
   RAISERROR('This application has been updated before submitting your changes. Please refresh the page and try again.',16,2)        
    END        
        
  IF(@IsAutoPaymentLoan =1)      
  BEGIN      
   Update [DealCapture.LoanPayment] SET        
   [DaysPerYearId] = @IsDaysPerYear ,         
   IsAutoPaymentLoan=@IsAutoPaymentLoan,        
   BankTypeId=@BankTypeId,        
   AccountNumber= @AccountNumber ,         
   RoutingNumber= @RoutingNumber ,         
   BankName= @BankName ,         
   AccountTypeId= @AccountTypeId ,         
   UpdatedBy= @UpdatedBy ,         
   UpdatedDate= Getdate(),        
   [Version] = @NewVersionId   ,    
   OverridePaymentScheduleDetail = @OverridePaymentScheduleDetail,     
   OverrideMaturityDate = @OverrideMaturityDate,     
   IsLeaveDateBlankDocuments = @IsLeaveDateBlankDocuments,     
   IsOverrideMaturityDate = @IsOverrideMaturityDate,     
   IsOverridePaymentScheduleDetail = @IsOverridePaymentScheduleDetail  ,  
   ISAmortization=@ISAmortization,  
   AmortizationUnitinMonth=@AmortizationUnitinMonth,  
   AccountType=@AccountType,  
   DateOfNote=@DateOfNote  
   ,[PrimaryOwner]=@PrimaryOwner
   Where [LoanApplicationId]=@LoanApplicationID        
   END      
   ELSE      
   BEGIN      
  Update [DealCapture.LoanPayment] SET        
    [DaysPerYearId] = @IsDaysPerYear ,         
    IsAutoPaymentLoan=@IsAutoPaymentLoan,        
    BankTypeId=NULL,        
  AccountNumber= NULL ,         
    RoutingNumber= NULL ,         
    BankName= NULL ,         
    AccountTypeId= NULL ,         
    UpdatedBy= @UpdatedBy ,         
    UpdatedDate= Getdate(),        
    [Version] = @NewVersionId   ,    
    OverridePaymentScheduleDetail = @OverridePaymentScheduleDetail,     
   OverrideMaturityDate = @OverrideMaturityDate,     
   IsLeaveDateBlankDocuments = @IsLeaveDateBlankDocuments,     
   IsOverrideMaturityDate = @IsOverrideMaturityDate,     
   IsOverridePaymentScheduleDetail = @IsOverridePaymentScheduleDetail,    
    ISAmortization=@ISAmortization,  
   AmortizationUnitinMonth=@AmortizationUnitinMonth,  
   AccountType=@AccountType,  
   DateOfNote=@DateOfNote  
      ,[PrimaryOwner]=@PrimaryOwner
    Where [LoanApplicationId]=@LoanApplicationID       
   END      
  END        
        
          
  Declare @UpdatedByUSer Varchar(100)        
set @UpdatedByUSer = isnull(@CreatedBy,@UpdatedBy)      
    
execute DealCapture_LoanApplication_UpdatePaymentMaturityDate @LoanApplicationID    
exec [DealCapture_LoanApplication_UpdateModifiedDate]  @LoanApplicationID,@UpdatedByUSer        
   
 /* Is Form flag Reset Code */    
 execute dbo.usp_IsFormFlagReset  @LoanApplicationID , 5    
/* Is Form flag Reset Code */    
    
  -- BEGIN INSERT INTO AUDIT TABLE    
  DECLARE @LoanStageId INT, @StageId INT, @Oldrecord INT    
  SELECT @LoanStageId = StageId, @StageId = ApplicationStatus FROM [Application]with(nolock)  where ApplicationId = @LoanApplicationId    
  --SELECT @StageId = ApplicationStatus FROM [Application] with(nolock) where ApplicationId = @LoanApplicationId    
     
    
 Insert into [dbo].[AuditDealCapture.LoanPayment]         
   ( [LoanApplicationId], [DaysPerYearId], [IsAutoPaymentLoan], [BankTypeId], [AccountNumber], [RoutingNumber], [BankName], [AccountTypeId], [CreatedBy],CreatedDate, [IsDeleted],[LoanStageId], [StatusId])        
  Values        
   (@LoanApplicationId, @IsDaysPerYear, @IsAutoPaymentLoan, @BankTypeId, @AccountNumber, @RoutingNumber, @BankName, @AccountTypeId,@UpdatedByUSer, Getdate(), 0,@LoanStageId, @StageId)        
       
   --- END OF AUDIT TABLE    
  ----------------------------Update  Created date as pper  discussed with Vikram---- Change by Ritesh  
    
   Declare @accountID int   
 select @accountID = ObjectIdentity from ApplicationContents WITH(NOLOCK) where ObjectType = 'Account' and ApplicationName =@LoanApplicationID  
 --Add NULL condition by : Balaji - due to not saving loan payment  
 IF @DateOfNote IS NOT NULL  
 BEGIN  
  Update Account set DateOpened=@DateOfNote where AccountID = @accountID  
 END  
  
 /* Start Date of note change logic */  
  
 select top 1 @oldDateNote=DateOfNote from [DealCapture.LoanPayment]  WITH(NOLOCK) where LoanApplicationId = @LoanApplicationID and IsDeleted =0  
  
 if((@oldDateNote is null or @oldDateNote = '') and @DateOfNote <>'' and @DateOfNote  is not null)  
 begin  
  
 exec usp_resetdocumentsByTriggers 'Updated due to date of note change',@LoanApplicationId  
  
 end  
 else if(@oldDateNote is not null and @oldDateNote <> '' and @DateOfNote <>@oldDateNote)  
 begin  
  
 exec usp_resetdocumentsByTriggers 'Updated due to date of note change',@LoanApplicationId  
  
 end  
  
  
 /* End Date of note change logic */  
  
 -------------------------------------------------------------------------------------------------  
 set  @ErrorCode =1        
 COMMIT TRANSACTION        
 END TRY        
        
 BEGIN CATCH        
 --set @ErrorCode = 0        
          
  ROLLBACK TRANSACTION        
  EXECUTE [dbo].[uspLogError]  ' [dbo].[DealCapture_LoanApplication_SaveLoanPayment]',NULL,@requestObject            
 END CATCH        
 select @ErrorCode as 'ErrorCode',@NewVersionId as 'Version' , @LoanApplicationId as 'LoanApplicationId', @LoanApplicationID as 'ApplicationId', @LoanPaymentID as ID        
END
GO

