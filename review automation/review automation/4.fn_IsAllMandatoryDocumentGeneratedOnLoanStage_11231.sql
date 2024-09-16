-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Create date: 16 Jun 2023
-- Description : Please review the LMS Scripts for the 08/01/2023 CAB
-- Modified By: Tejal Patel
-- Modified Date: 10 August 2023
-- Bug: 7376 : Made Loan Memo Package mandatory to be generated  before submitting for approval
-- ETA < 1 min
-- Select [dbo].[fn_IsAllMandatoryDocumentGeneratedOnLoanStage](38671)



--==========================================================================================================================================================
--Created Date        	Created By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--09/25/2023			Ritesh D			09/12/2023		1M			BUG:  7941  Deferral/waiver decline for mandatory document - document is not made mandated
--06/02/2024	        soma     		   07/23/2024   	1M  		 Bug: 11231 Change in the view of sequence period details under rates and fees on Loan Memo 
--==========================================================================================================================================================
  

CREATE OR ALTER FUNCTION [dbo].[fn_IsAllMandatoryDocumentGeneratedOnLoanStage]
(
@ApplicationId bigint
) RETURNS bit

as

begin

DECLARE @IsDocGenerated BIT=0;
DECLARE @DocCount int;
DECLARE @DocCountInFolderDocTable int;
DECLARE @LoanStageId int=0;
DECLARE @LoanStatusId int;
DECLARE @LoanStageApprovalType int;

			IF EXISTS(SELECT  top 1 IsProcessing from  [dbo].[FolderDocuments] WITH (NOLOCK)
			where ApplicationId=@ApplicationId)
			BEGIN
			  



				select @LoanStageId=StageId , @LoanStatusId=ApplicationStatus  from Application WITH (NOLOCK) where ApplicationID =@ApplicationId
				SELECT  @DocCountInFolderDocTable=count(*) from FolderDocuments FD  WITH (NOLOCK) where FD.ApplicationID = @ApplicationId and FD.IsActive =1
		
				SELECT  @DocCount=count(*) from FolderDocuments FD  WITH (NOLOCK)
				INNER JOIN  Documents D  WITH (NOLOCK) on FD.DocumentID = D.DocumentID and D.IsActive =1  and FD.DocumentID NOT IN
				(SELECT DocumentID FROM [Master].[IgnoreDocumentForCheckList]  WITH(NOLOCK))
				WHERE ApplicationID =@ApplicationId and DocumentStatusId in (1,18,19, 3) and IsProcessing  in (0,1,3,4,5,7,10,13,18,19,8)   
				and IsRequired =1 and fd.IsActive =1 and ( RequiredStageId <@LoanStageId or ( RequiredStageId =@LoanStageId 
				and isnull(LoanStageApprovalTypeID,0) > 0 

				and @LoanStatusId in 
				(select items from [dbo].[fn_Split](	
					(case isnull(LoanStageApprovalTypeID,0) when 1   then 
						(SELECT STRING_AGG(   ISNULL(Id, '') , ',')       From Master.LoanStatus  WITH(NOLOCK) where  Name in ('Pending' ,'Draft' ) and IsActive=1 )
					when 2     then  
						( select STRING_AGG(  ISNULL(Id, '') , ',') from  Master.LoanStatus  WITH(NOLOCK) where Name in ('Approved' ) and IsActive =1 ) 
					when 4     then  
						( select STRING_AGG(  ISNULL(Id, '') , ',') from  Master.LoanStatus  WITH(NOLOCK) where Name in ('In Progress' ) and IsActive =1 )
					when 7     then  
						( select STRING_AGG(  ISNULL(Id, '') , ',') from  Master.LoanStatus  WITH(NOLOCK) where Name in ('In Progress' ) and IsActive =1 ) 
					when 5     then  
						( select STRING_AGG(  ISNULL(Id, '') , ',') from  Master.LoanStatus  WITH(NOLOCK) where Name in ('At Closing' ) and IsActive =1 ) 
					when 3  then  
				 		(SELECT STRING_AGG(ISNULL(Id, ''), ',')  From Master.LoanStatus  WITH(NOLOCK) where  Name in ('Pending' ,'Draft' ,'Approved') and IsActive=1 )
					 end)
				,','))))

				and (D.DocumentID not in (select DocumentID from [Master].[IgnoreDocumentForCheckList] WITH(NOLOCK)) --Remover Temp for testing 
				
				and D.DocumentID not in (176)


	 --select *  from  documents where  DocumentName like '%Iden%' and IsActive=1 ))
				or D.DocumentID Not in (
				  --- creating logic for to exclude waiver doc 
			  	    SELECT DocumentID from FolderDocuments FD  WITH(NOLOCK) 
					INNER JOIN [dbo].[DealCapture.DocumentWaiverDetails] DWD  WITH(NOLOCK)
									 ON DWD.ApplicationID = FD.ApplicationId and DWD.FolderDocID = FD.FolderDocumentID
									 ---Added bewlo  condition  by  Ritesh
					INNER Join  [DealCapture.DocumentWaiverReviwerDetails] DRD  WITH(NOLOCK) on DRD.Status=  'Approve' AND DRD.DocumentWaiverID=DWD.ID
					 WHERE FD.ApplicationID = @ApplicationId and FD.IsActive =1 --and DWD.IsWaver =1

			  ----End for creating logic for to exclude waiver doc 
				))  and fd.IsShowOnUI<>0

				--7468:RUSH - Remove ID Requirements Ritesh 
				
				AND  (FD.FolderDocumentID not in (
				select FD.FolderDocumentID
From FolderDocuments  FD inner join  AccountParty LP on LP.ApplicationID= FD.ApplicationId 
and Lp.IsPartyAddedFromPrecision=1 
and FD.IsActive=1 
and FD.CustomerID=LP.CustomerID
INNER join  Documents  D on  D.DocumentID= FD.DocumentID and  d.DocumentID in (77,78) and FD.ApplicationId= @ApplicationId 
				))
				--and RequiredLoanStatusId =@LoanStatusId 
			
				IF (@DocCountInFolderDocTable=0)
				BEGIN
					set @IsDocGenerated=1  --Stop	
				END 
				ELSE IF (@DocCount>0 ) 
				BEGIN
					set @IsDocGenerated=1  --Stop 
				END
				ELSE
				BEGIN
					SET @IsDocGenerated=0  --Proceed 
				END

END
  RETURN @IsDocGenerated
  End
GO

