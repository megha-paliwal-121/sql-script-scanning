-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 July 2023
-- Description: BUG: 7376 Stopping regeneration of Loan Memo Package after approval
--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--09/11/22		     	Thorani      		09/11/2023   	1M  		Bug: 7796: return  status stoping the loan memo regenration 
--10/05/2023			Tejal Patel        10/05/2023		1M			Bug: 7826: on reapproval show Flood documents 
--10/20/2023			Tejal Patel        10/20/2023		1M			Bug: 8226: Loan Memo regeneration
--11/20/2023			Tejal Patel        02/23/2024		1M			Bug: 8754: Approval Queue
--05/22/2024	        pawan     		07/23/2024   	1M  		 Bug: 12253 Bug 7294 : Draw enhancements
--==========================================================================================================================================================


CREATE  OR ALTER  PROCEDURE [dbo].[DealCapture_Approval_ApproveApplication]  
(  
 @LoanApplicationId int,   
 @Notes varchar(max),   
 @ToStatusName varchar(100),  
 @UserName varchar(100)  
 )    
as  
begin   
BEGIN TRY   
-- BEGIN TRAN  
-------Fetch Old Data  
        DECLARE @requestObject NVARCHAR(MAX)=CONCAT('EXEC [dbo].[DealCapture_Approval_ApproveApplication] ',@LoanApplicationId,',','''',@Notes,',','''',@ToStatusName,',','''',@UserName)  
   Declare @OldApplicationStageID int  
   ,@OldApplicationStatusId INT  
   ,@OldAssignedTo Varchar(1000)  
   ,@NewAssignedTo Varchar(1000)
   ,@LoanAccountNumber Varchar(100)
   ,@LoanOfficerBankId INT
  select @OldApplicationStageID= StageId,@LoanOfficerBankId=LoanOfficerBankId, @OldApplicationStatusId = ApplicationStatus, @OldAssignedTo=WorkflowAssignedTo,@LoanAccountNumber=LoanAccountNumber  from  Application WITH(NOLOCK) where @LoanApplicationID = ApplicationID  
--------End Fetch  
  
  Declare @LoanOfficer varchar(max)  
  Declare @historyType Varchar(Max)  
  DECLARE @AssignTo VARCHAR(150)

  select top  1 @LoanOfficer=LoanOfficer from vw_LoanPartyData WITH(NOLOCK) where ApplicationID= @LoanApplicationId  
  
   -- IF (@LoanOfficer=@UserName)  
 Begin   
  if exists(select * from Application WITH(NOLOCK) where ApplicationId  = @LoanApplicationId)    
 begin    
  --regarding notification    
  
  declare @LoanApplicationNumber varchar(100) = (select top 1 ApplicationNumber from vw_LoanPartyData where ApplicationId = @LoanApplicationId)  
  declare @WorkflowCode varchar(100) = (select WorkflowCode from master.Workflows WITH(NOLOCK) where Id in (select WorkflowID from Application WITH(NOLOCK) where ApplicationId = @LoanApplicationId))    
  declare @ApplicationLoanOfficer varchar(100) = (select top 1 LoanOfficer from vw_LoanPartyData WITH(NOLOCK) where ApplicationID = @LoanApplicationId)    
  declare @rid bigint ;  
  declare @CustomerName varchar(100);  
  declare @AssignedFrom varchar(100)   
  if exists(select * from master.LoanStatus WITH(NOLOCK) where Name = @ToStatusName)    
  begin    
   declare @ToStatusId int = (select Id from master.LoanStatus WITH(NOLOCK) where Name = @ToStatusName)    
   declare @IsStatusChanged bit = 0    
      
   --for self approval    
   if @WorkflowCode = 'SLO'    
   begin    
    if @ToStatusName = 'Approved'    
    begin    
     update dbo.Application set ApplicationStatus = @ToStatusId, UpdatedDate = GETDATE(), UpdatedBy = @Username   
     ,FinalApprovalDate=getdate()  
     where ApplicationId = @LoanApplicationId    
    
     --update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId   
      EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, WorkflowAssignedTo, WorkflowAssignedTo, @Notes, GETDATE(), @Username, 1,   1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
      --updating flag for reapproval process 
	  exec DealCapture_Approval_UpdatePartyFlagForReApproval @LoanApplicationId,1

	  -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

     set @IsStatusChanged = 1    
    end    
    else    
    begin    
     select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
       @ApplicationLoanOfficer as AssignedToLoanOfficer,A.LoanAccountNumber, 0 as ErrorCode, 'For Self Approval Flow Status cannot be another than Approved' as ResponseMessage     
      from Application A WITH(NOLOCK) inner join master.LoanStatus S WITH(NOLOCK) on S.Id = A.ApplicationStatus    
     where ApplicationId = @LoanApplicationId    
    end    
   end  
    
   --for other single loan officer    
   else if @WorkflowCode = 'OSLO'    
   begin    
    --regarding notification    
    Set @CustomerName  = (select CustomerName from vw_LoanPartyData WITH(NOLOCK) where ApplicationID = @LoanApplicationId and PartyRoleId = 1)      
    Set  @AssignedFrom  = (select WorkflowAssignedTo from Application WITH(NOLOCK) where ApplicationId = @LoanApplicationId)    
    
    if @ToStatusName = 'Approved'    
    begin    
     update dbo.Application set ApplicationStatus = @ToStatusId, UpdatedDate = GETDATE(), UpdatedBy = @Username ,FinalApprovalDate=getdate()     
     where ApplicationId = @LoanApplicationId    
        
      --for notification after changing status    

	  EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OSLO','Approved','',@CustomerName,1

      
      EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
    
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, WorkflowAssignedTo, WorkflowAssignedTo, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
    
	set @IsStatusChanged = 1   
	 -----------------------------------------update  the queue-----------------------------------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------
      
    end    
    else if @ToStatusName = 'Declined'    
    begin    

	--for notification after changing status    
	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OSLO','Declined','',@CustomerName,1

     update dbo.Application set ApplicationStatus = @ToStatusId, WorkflowAssignedTo = @ApplicationLoanOfficer, WorkflowAssignedDate = getdate(),     
      UpdatedDate = GETDATE(), UpdatedBy = @Username  ,DeclineDate=getdate()    
     where ApplicationId = @LoanApplicationId    
         

     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
       
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, WorkflowAssignedTo, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
    
	
     set @IsStatusChanged = 1  
	 -----------------------------------------update  the queue----------------------

	    exec [DealCapture_ApprovalQueue_StatusUpdate] 1, @LoanApplicationId,@UserName,@ToStatusName

	   -- Decline Document Waiver -Pawan

	    UPDATE [LoansToMature] SET loanApplicationId=NULL WHERE loanApplicationId=@LoanApplicationID
		
		SET  @AssignTo = (SELECT  DISTINCT TOP  1 GroupName from vw_UserProfilewithMarketExtenstion where BankId = @LoanOfficerBankId AND ADGroupID IN (1006)) --Prefunding 

		UPDATE [DealCapture.DocumentWaiverReviwerDetails] SET Status='Decline',UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName

		WHERE DocumentWaiverID IN (SELECT ID FROM [DealCapture.DocumentWaiverDetails] WHERE ApplicationID=@LoanApplicationID)

		UPDATE 
		[DealCapture.LoanApprovalQueue] SET Isactive=0,UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2
		UPDATE [DealCapture.LoanApprovalQueueAssigmentDetail] SET Isactive=0 WHERE RecordId
		IN (SELECT RecordId FROM [DealCapture.LoanApprovalQueue] WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2)

		EXEC [DealCapture_ApprovalQueue_StatusUpdate] 5, @LoanApplicationID,@AssignTo,'Ack'
		UPDATE CompareCoreMaintenance set [Status]='Rejected' , UpdatedBy=@UserName, UpdatedDate=GETDATE()  WHERE  ApplicationId=@LoanApplicationId  AND Status='Pending'
		--Pawan
	  --------------------------------------------------------------------------------------------------------

    end    
    else if @ToStatusName = 'Returned'    
    begin    

	--for notification after changing status    
	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OSLO','Returned','',@CustomerName,1

     update dbo.Application set ApplicationStatus = @ToStatusId, WorkflowAssignedTo = @ApplicationLoanOfficer, WorkflowAssignedDate = getdate(),    
      UpdatedDate = GETDATE(), UpdatedBy = @Username      
     where ApplicationId = @LoanApplicationId    
        
     
     
     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
       
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, WorkflowAssignedTo, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
 
     set @IsStatusChanged = 1    
	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------
    end    
    else    
    begin    
     select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
      @ApplicationLoanOfficer as AssignedToLoanOfficer,A.LoanAccountNumber, 0 as ErrorCode, 'For Other Single Loan Officer Flow. Status cannot be another than Approved/Returned/Declined' as ResponseMessage     
     from Application A WITH(NOLOCK) inner join master.LoanStatus S WITH(NOLOCK) on S.Id = A.ApplicationStatus    
      where ApplicationId = @LoanApplicationId    
    end    
   end    
   else if( @WorkflowCode = 'OMLO'  OR @WorkflowCode = 'SMLO')     
   begin    
    if @ToStatusName = 'Approved'    
    begin   
     -- To Do need to check the status of all users is approved  
  
     DEclare  @WorkflowAssignedTo varchar(MAX)=''  
     Declare @IsApprvalReady bit   
 --need o check with Ritesh  
  
     update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId  and AssignedTo=@UserName  
    
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
     IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId,@UserName , @WorkflowAssignedTo, @Notes, GETDATE(), @Username, 1,    
     1, getdate(),  0, @ToStatusName,2 from Application WITH (NOLOCK) where ApplicationID = @LoanApplicationId    
  
     -- --if all active is zero then its ready for procressing  this code will move to Processing sp  
      Select @IsApprvalReady =case when count(*)= 0 then 1 else 0 end  from  ApprovalWorkflowAssignment WITH(NOLOCK) where ApplicationId=@LoanApplicationId and  StatusId= 1167 and IsActive=1  
	  and  LoanAssginmentTypeId=2 -- this  condition  added 7424
  
      IF (@IsApprvalReady=1)  
      BEGIN  
		EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OMLO','ApprovedALL','',@CustomerName,1
		update dbo.Application set FinalApprovalDate=getdate(),ApplicationStatus = @ToStatusId, UpdatedDate = GETDATE(), UpdatedBy = @Username     where ApplicationId = @LoanApplicationId    
 
      END  
	  ELSE 
	  BEGIN
     --for notification after changing status	 
		EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OMLO','ApprovalInProgress',@UserName,@CustomerName,1
	  END
    
    
     set @IsStatusChanged = 1    

	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

    end    
    else if @ToStatusName = 'Declined'    
    begin    
	  
	--for notification after changing status 
	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OMLO','Declined','',@CustomerName,1
   
     update dbo.Application set ApplicationStatus = @ToStatusId, WorkflowAssignedTo = @ApplicationLoanOfficer, WorkflowAssignedDate = getdate(),     
     UpdatedDate = GETDATE(), UpdatedBy = @Username  ,DeclineDate=getdate()    
     where ApplicationId = @LoanApplicationId    
         
     
     update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId    
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
     IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, @LoanOfficer, @Notes, GETDATE(), @Username, 1,    
     1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
     
	 set @IsStatusChanged = 1    
	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

	   -- Decline Document Waiver -Pawan

	    UPDATE [LoansToMature] SET loanApplicationId=NULL WHERE loanApplicationId=@LoanApplicationID

		SET  @AssignTo = (SELECT  DISTINCT TOP  1 GroupName from vw_UserProfilewithMarketExtenstion where BankId = @LoanOfficerBankId AND ADGroupID IN (1006)) --Prefunding 

		UPDATE [DealCapture.DocumentWaiverReviwerDetails] SET Status='Decline',UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName

		WHERE DocumentWaiverID IN (SELECT ID FROM [DealCapture.DocumentWaiverDetails] WHERE ApplicationID=@LoanApplicationID)

		UPDATE 
		[DealCapture.LoanApprovalQueue] SET Isactive=0,UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2
		UPDATE [DealCapture.LoanApprovalQueueAssigmentDetail] SET Isactive=0 WHERE RecordId
		IN (SELECT RecordId FROM [DealCapture.LoanApprovalQueue] WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2)

		EXEC [DealCapture_ApprovalQueue_StatusUpdate] 5, @LoanApplicationID,@AssignTo,'Ack'
		UPDATE CompareCoreMaintenance set [Status]='Rejected' , UpdatedBy=@UserName, UpdatedDate=GETDATE()  WHERE  ApplicationId=@LoanApplicationId  AND Status='Pending'
		--Pawan

    end    
    else if (@ToStatusName = 'Return From LoanOfficer'  OR @ToStatusName = 'Returned'  )  
    begin    
     --select * from master.LoanStatus  

	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'OMLO','Returned','',@CustomerName,1

     update dbo.Application set ApplicationStatus = 1170, WorkflowAssignedTo = @LoanOfficer, WorkflowAssignedDate = getdate(),    
     UpdatedDate = GETDATE(), UpdatedBy = @Username      
     where ApplicationId = @LoanApplicationId    
        
   
     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
      
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
     IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @UserName, @LoanOfficer, @Notes, GETDATE(), @Username, 1,    
     1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
    
     set @IsStatusChanged = 1 
	 
	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------


    end    
    else    
    begin    
     select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
     @ApplicationLoanOfficer as AssignedToLoanOfficer,A.LoanAccountNumber, 0 as ErrorCode, 'For Other Single Loan Officer Flow. Status cannot be another than Approved/Returned/Declined' as ResponseMessage     
     from Application A inner join master.LoanStatus S on S.Id = A.ApplicationStatus    
     where ApplicationId = @LoanApplicationId    
    end    
   end    
   --for ec/bod flow  
   else if (@WorkflowCode = 'EC' OR @WorkflowCode = 'BOD')  
   begin  
    --regarding notification    
    Set @CustomerName  = (select CustomerName from vw_LoanPartyData WITH(NOLOCK) where ApplicationID = @LoanApplicationId and PartyRoleId = 1)      
    Set @AssignedFrom  = (select AssignedTo from ApprovalWorkflowAssignment WITH(NOLOCK) where ApplicationId = @LoanApplicationId and IsActive = 1 and LoanAssginmentTypeId=2)  
    
    if @ToStatusName = 'Approved'  
    begin    
     update dbo.Application set ApplicationStatus = 1162, UpdatedDate = GETDATE(), UpdatedBy = @Username    
     ,FinalApprovalDate=getdate()  
     where ApplicationId = @LoanApplicationId    
        
     --for notification after changing status    
     SET @rid =dbo.Fngetuniquenumber()    
     EXECUTE [dbo].[Usp_savelmsnotifications]    
     @RecordId = @rid,    
     @AccountNumber = '',    
     --@ApplicationID = @LoanApplicationNumber,    
	 @ApplicationID = @LoanApplicationId, 
     @Module = N'LMS',    
     @Feature = 'Approval',    
     @Type = 1001,    
     @status = N'Approved',    
     @LoginUserId = @ApplicationLoanOfficer,    
     @IsFinal = 1,    
     @CustomerName = @CustomerName,    
     @DocumentType=''  
    
	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'BOD','Approval',@ApplicationLoanOfficer,@CustomerName,0
     --update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId    
     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
    
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action, LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, @AssignedFrom, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, 'Approved', 2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
	   
     set @IsStatusChanged = 1   
	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

    end    
    else if @ToStatusName = 'Declined'    
    begin  
     update dbo.Application set ApplicationStatus = @ToStatusId, WorkflowAssignedTo = @ApplicationLoanOfficer, WorkflowAssignedDate = getdate(),     
      UpdatedDate = GETDATE(), UpdatedBy = @Username  ,DeclineDate=getdate()    
     where ApplicationId = @LoanApplicationId    
         
     --for notification after changing status    
     SET @rid =dbo.Fngetuniquenumber()    
     EXECUTE [dbo].[Usp_savelmsnotifications]    
     @RecordId = @rid,    
     @AccountNumber = '',    
     @ApplicationID = @LoanApplicationId,    
     @Module = N'LMS',    
     @Feature = 'Approval',    
     @Type = 1001,    
     @status = N'Declined',    
     @LoginUserId = @ApplicationLoanOfficer,    
     @IsFinal = 1,    
     @CustomerName=@CustomerName,    
     @DocumentType=''    
    
	--Send Notification to  ECBD for Denial
	EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'BOD','Declined',@ApplicationLoanOfficer,@CustomerName,0
     --update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId  
     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
       
     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, @ApplicationLoanOfficer, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, 'Declined',2 from Application  WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
    
     set @IsStatusChanged = 1    

	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

	   -- Decline Document Waiver -Pawan

	    UPDATE [LoansToMature] SET loanApplicationId=NULL WHERE loanApplicationId=@LoanApplicationID
		
		SET  @AssignTo = (SELECT  DISTINCT TOP  1 GroupName from vw_UserProfilewithMarketExtenstion where BankId = @LoanOfficerBankId AND ADGroupID IN (1006)) --Prefunding 

		UPDATE [DealCapture.DocumentWaiverReviwerDetails] SET Status='Decline',UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName

		WHERE DocumentWaiverID IN (SELECT ID FROM [DealCapture.DocumentWaiverDetails] WHERE ApplicationID=@LoanApplicationID)

		UPDATE 
		[DealCapture.LoanApprovalQueue] SET Isactive=0,UpdatedDate=GETDATE(),UpdatedBy='Withdrwan-'+@UserName WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2
		UPDATE [DealCapture.LoanApprovalQueueAssigmentDetail] SET Isactive=0 WHERE RecordId
		IN (SELECT RecordId FROM [DealCapture.LoanApprovalQueue] WHERE ReferenceID=@LoanApplicationID AND ApprovalQueueTypeID=2)

		EXEC [DealCapture_ApprovalQueue_StatusUpdate] 5, @LoanApplicationID,@AssignTo,'Ack'
		UPDATE CompareCoreMaintenance set [Status]='Rejected' , UpdatedBy=@UserName, UpdatedDate=GETDATE()  WHERE  ApplicationId=@LoanApplicationId  AND Status='Pending'
		--Pawan

    end    
    else if @ToStatusName = 'Returned'    
    begin    
     update dbo.Application set ApplicationStatus = @ToStatusId, WorkflowAssignedTo = @ApplicationLoanOfficer, WorkflowAssignedDate = getdate(),    
      UpdatedDate = GETDATE(), UpdatedBy = @Username      
     where ApplicationId = @LoanApplicationId    
        
     --for notification after changing status    
     SET @rid =dbo.Fngetuniquenumber()    
     EXECUTE [dbo].[Usp_savelmsnotifications]    
     @RecordId = @rid,    
     @AccountNumber = '',    
     @ApplicationID = @LoanApplicationId,    
     @Module = N'LMS',    
     @Feature = 'Approval',    
     @Type = 1001,    
     @status = N'Returned',    
     @LoginUserId = @ApplicationLoanOfficer,    
     @IsFinal = 1,    
     @CustomerName = @CustomerName,    
     @DocumentType=''    
         
     --update ApprovalWorkflowAssignment set IsActive = 0 where ApplicationId = @LoanApplicationId  
     EXECUTE DealCapt_Approval_DeActiveWorkflowAssigmentByApplicationID @LoanApplicationId  
     
	 EXEC DealCapture_Approval_SendNotificationForStage1 @loanApplicationID,'BOD','Returned',@ApplicationLoanOfficer,@CustomerName,0

     insert into ApprovalWorkflowAssignment(ApplicationId, StatusId, AssignedFrom, AssignedTo, Notes, CreatedDate, CreatedBy, IsActive,     
      IsshowInDisburstment, ActionDate, IsGroupAssigment, Action,LoanAssginmentTypeId)    
     select @LoanApplicationId, @ToStatusId, @AssignedFrom, @ApplicationLoanOfficer, @Notes, GETDATE(), @Username, 1,    
      1, getdate(),  0, @ToStatusName,2 from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
    
     set @IsStatusChanged = 1    

	 -----------------------------------------update  the queue----------------------

	  exec [DealCapture_ApprovalQueue_StatusUpdate]  1, @LoanApplicationId,@UserName,@ToStatusName
	  --------------------------------------------------------------------------------------------------------

    end    
    else    
    begin    
     select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
      @ApplicationLoanOfficer as AssignedToLoanOfficer,A.LoanAccountNumber, 0 as ErrorCode, 'For EC/BOD Flow. Status cannot be another than Approved/Returned/Declined' as ResponseMessage     
     from Application A WITH(NOLOCK) inner join master.LoanStatus S WITH(NOLOCK) on S.Id = A.ApplicationStatus    
      where ApplicationId = @LoanApplicationId    
    end    
   end  
  
   if @IsStatusChanged = 1    
   begin    
    select WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, ApplicationStatus as ApplicationStatusId, @ToStatusName as ApplicationStatusName,     
     WorkflowAssignedTo as AssignedToLoanOfficer,LoanAccountNumber, 1 as ErrorCode, 'Successfully Status changed' as ResponseMessage  ,
	   LoanOfficerBankId as BankId,'Commercial' as LoanProductType
    from Application WITH(NOLOCK) where ApplicationID = @LoanApplicationId    
     
   IF (@WorkflowCode='SLO')  
    SET @historyType='6'  
   else   
    SET @historyType='4'  
  
    EXECUTE [dbo].[DealCapture_LoanApplication_InsertLoanApplicationHistory] @LoanApplicationID,0,@notes,@UserName,@historyType,@OldApplicationStageID,@OldApplicationStatusId,@NewAssignedTo,@OldAssignedTo  
  
   end    
  end  
  else    
  begin    
   select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
    @ApplicationLoanOfficer as AssignedToLoanOfficer,A.LoanAccountNumber, 0 as ErrorCode, 'To Status Name not found in master table' as ResponseMessage     
    from Application A WITH(NOLOCK) inner join master.LoanStatus S WITH(NOLOCK) on S.Id = A.ApplicationStatus    
   where ApplicationId = @LoanApplicationId    
  end    
 end    
 else    
 begin    
 select 0 as WorkflowId, '' as WorkflowCode, 0 as ApplicationStatusId, '' as ApplicationStatusName, '' as AssignedToLoanOfficer,'' as LoanAccountNumber     
  ,0 as ErrorCode, 'Application Not Exists' as ResponseMessage    
 end    
 END  
 -- we need to stop reload the documents after the loan is approved.  
 --if exists ( select * from application WITH(NOLOCK) where applicationid=@LoanApplicationId and applicationstatus='1162')  
 --begin  

 ----exec usp_StopDocumentReloadAfterApproval @LoanApplicationId  
  
 --end  
 --ELSE   
 --BEGIN  
 --  select A.WorkflowID as WorkflowId, @WorkflowCode as WorkflowCode, A.ApplicationStatus as ApplicationStatusId, S.Name as ApplicationStatusName,     
 --      @ApplicationLoanOfficer as AssignedToLoanOfficer, 0 as ErrorCode, 'Loan Officer should  only  approve' as ResponseMessage     
 --     from Application A inner join master.LoanStatus S on S.Id = A.ApplicationStatus    
 --    where ApplicationId = @LoanApplicationId   
 --END   
 --COMMIT TRAN  

 --REAPPROVAL LOGIC
	--IF @ToStatusName = 'Approved' --(@OldApplicationStatusId = 1162)
	--BEGIN
	--	--EXEC [dbo].[usp_AddApprovedDataToReApproval] @LoanApplicationId,@UserName
	--	--     --updating flag for reapproval process 
	-- -- exec DealCapture_Approval_UpdatePartyFlagForReApproval @LoanApplicationId,1

	-- -- update FolderDocuments set IsStopReload=1 where ApplicationId= @LoanApplicationId and DocumentID in (16,209,15) and IsActive=1
	Declare @CurentApplicationStatus int=(SELECT Top 1  ApplicationStatus  from  Application WITH(NOLOCK) where @LoanApplicationID = ApplicationID )
	--END
		--REAPPROVAL LOGIC END
		--7495
		IF (@OldApplicationStatusId  <> (@CurentApplicationStatus))
		BEGIN 
		-- start 3254 Loan Timeline by Narendra
			 EXEC [dbo].[InsertLoanStatusHistoryTimeline] @LoanApplicationID
		-- end 3254 Loan Timeline by Narendra

		If(@CurentApplicationStatus=1162)---Apprived  Status 
		BEGIN

			EXEC [dbo].[usp_AddApprovedDataToReApproval] @LoanApplicationId,@UserName
		     --updating flag for reapproval process 
			exec DealCapture_Approval_UpdatePartyFlagForReApproval @LoanApplicationId,1

			update FolderDocuments set IsStopReload=1,UpdatedBy='Approve SP', UpdatedDate=getdate() where ApplicationId= @LoanApplicationId and DocumentID in (16,209,15,8) and IsActive=1
		
			--EXEC [dbo].[ShowFloodDocumentsOnReApproval] @LoanApplicationId,NULL
	
			END
			
		END 
	
 --COMMIT TRAN  


 END TRY  
 BEGIN CATCH  
 --ROLLBACK TRAN  
  EXECUTE [dbo].[uspLogError] '[dbo].[DealCapture_Approval_ApproveApplication]',NULL,@requestObject  
 END CATCH  
end
GO

