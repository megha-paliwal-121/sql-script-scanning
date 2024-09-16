 -- Author:        Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Description:   Data Script
-- ETA < 1 min
-- =============================================
--Modified Date        	Modified By      	Review Date		ETA	  		Comments  									                     EXECUTE
--========================================================================================================================================================== 
--12/28/2023	        Soma     			02/23/2023  	1M  		8648 IMS Staging Folder
--06/02/2024	        Thorani     		07/23/2024   	1M  		 Bug: 12219 Survey 'In File'
--==========================================================================================================================================================
 


CREATE OR ALTER  function [dbo].[fn_GetPayLoadTagsByDocId](@DocumentId bigint,@FolderDocumentID bigint)
returns nvarchar(max)
begin

Declare @name nvarchar(max)
DECLARe @LMSID VARCHAR(100)
SET @LMSID =[dbo].[IMSIDFormat](@FolderDocumentID)

SET @name=(SELECT STUFF(    
       (SELECT ', '+    
        CASE when TagName='LMSID' then ''''+@LMSID+''''
		 when TagName='EffectiveDate' then CONVERT(varchar,GETDATE(),101)
		 when TagName='LMS-IMSDocType' then ''''+'LD-CSell-Preview'+''''
		 
        ELSE dbname     
        END+' as ['+TagName+']'     
        FROM [dbo].[DocumentPayloadMapping] X with(nolock)   
        WHERE DocumentID in (@DocumentID,0)      
        ORDER BY x.Id    
        FOR XML PATH('')    
       ),1,1,'') as ProductListset) 
	   

return @name

end
GO

