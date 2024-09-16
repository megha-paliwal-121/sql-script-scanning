-- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- ETA < 1 min
--==========================================================================================================================================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  	
--========================================================================================================================================================== 
--05/12/2024		    Soma      			05/12/2024  	1M  		 Bug: 7294 :
--==========================================================================================================================================================

CREATE   procedure [dbo].[usp_SaveDrawDocumentFinalization]
(
@DrawRequestId int,
@IMSIds UDTBigInt READONLY 
)
as
begin
 BEGIN TRY    
   DECLARE  @requestObject VARCHAR(200)='EXEC [dbo].[usp_SaveDrawDocumentFinalization]' 

update d set d.IsFinal=1,UpdatedBy='DrawDocumentFinalization',UpdatedDate=GETDATE() 
from [Draw.DocumentDetails] as d with(nolock) 
inner join  @IMSIds as U on U.Id=d.IMSDocumentID 
where DrawRequestId=@DrawRequestId

   SELECT 1  
  
   END TRY    
      
BEGIN CATCH    
EXECUTE [dbo].[uspLogError] '[dbo].[usp_SaveDrawDocumentFinalization]',NULL,@requestObject    
SELECT 0 
END CATCH  
end
GO

