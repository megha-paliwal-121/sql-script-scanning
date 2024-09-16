
CREATE  OR ALTER PROCEDURE [dbo].[DealCapture_Approval_SubmitToUpload] --12525, ''  
(  
 @LoanApplicationId bigint,  
 @CreatedBy Varchar(1000)  
)  
as  
begin  
 

BEGIN TRY   
 DECLARE @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_Approval_SubmitToUpload] ',@LoanApplicationId,',','''',@CreatedBy)
    declare @ToStatusId int = 1171 --Funded  
    declare @NewstageID int = 4  
-------Fetch Old Data  
   Declare @OldApplicationStageID int, @OldApplicationStatusId INT  
  Declare @OldAssignedTo Varchar(1000)   
  Declare @NewAssignedTo Varchar(1000)   =''
  	Declare @loanRequestTypeID  int=0
  select @OldApplicationStageID= StageId, @OldApplicationStatusId = ApplicationStatus, @OldAssignedTo=WorkflowAssignedTo , @loanRequestTypeID=LoanRequestTypeId  from  Application WITH(NOLOCK) where @LoanApplicationID = ApplicationID  
--------End Fetch  
  --SET @NewAssignedTo =dbo.[fn_GetApplicationSetting]('LMS_Note_Specialist_Test')  
  Declare @historyType Varchar(Max)='13'
  DECLARE @rid BIGINT; 
  DECLARE @CustomerName VARCHAR(100) 
  Declare @LoanOfficerName Varchar(1000)
  SELECT @CustomerName = customername, @LoanOfficerName = LoanOfficer  FROM   Vw_LoanPartyOnlyForList WITH (NOLOCK) WHERE  applicationid = @LoanApplicationId  AND isprimaryborrower = 1  
  
  --select * from ApplicationSettings  
  
    
  --2- ApprovalAssigment   
  --6 AttorneyAssignment    
  Update  ApprovalWorkflowAssignment set IsActive=0 where ApplicationId=@LoanApplicationId and  LoanAssginmentTypeId in (2,6)  
  
  insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
  select @LoanApplicationId, @ToStatusId, @OldAssignedTo, @NewAssignedTo, '', GETDATE(), @CreatedBy, 1,   1, getdate(),  1, 'Uploaded to Core',2      
       
  update dbo.Application   
  set  WorkflowAssignedTo =@NewAssignedTo,  
    ApplicationStatus = @ToStatusId,   
    StageId = @NewstageID,  
    UpdatedDate = GETDATE(),  
    UpdatedBy = @CreatedBy , 
    FundedDate=getdate()   ,
	FundedBy= @CreatedBy
  where ApplicationId = @LoanApplicationId   
  
  EXECUTE [dbo].[DealCapture_LoanApplication_InsertLoanApplicationHistory] @LoanApplicationID,0,'',@CreatedBy,@historyType,@OldApplicationStageID,@OldApplicationStatusId,@NewAssignedTo,@OldAssignedTo  

  --SET @rid = dbo.Fngetuniquenumber()			
  --exec [dbo].[Usp_savelmsnotifications] @RecordId = @rid,@AccountNumber = '', @ApplicationID = @LoanApplicationId, @Module = N'LMS', @Feature = 'UploadToCore',
		--     @Type = 1052, @status = N'UploadToCore', @LoginUserId = @LoanOfficerName, @IsFinal = 1, @CustomerName = @CustomerName, @DocumentType=''
  --Notification
  EXEC [DealCapture_Approval_SendNotificationForStage4] @LoanApplicationID,'UploadToCore',@CreatedBy,1

  	-- start 3254 Loan Timeline by Narendra 
		EXEC [dbo].[InsertLoanStatusHistoryTimeline] @LoanApplicationID
	-- end 3254 Loan Timeline by Narendra
	IF (@loanRequestTypeID=1167)
		BEGIN 
			DECLARE @MaturityDate DATETIME
			 SELECT @MaturityDate=MaturityDate FROM [dbo].[fn_PaymentTermCal](@LoanApplicationId) 
			UPDATE LoansToMature  SET loanApplicationId=NULL,MaturityDate=@MaturityDate WHERE loanApplicationId=@LoanApplicationId
		END

  Select 1  
  END TRY  
 BEGIN CATCH  
 Select 0  
 EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_Approval_SubmitToUpload]',NULL,@requestObject  
 END CATCH  
END
GO

