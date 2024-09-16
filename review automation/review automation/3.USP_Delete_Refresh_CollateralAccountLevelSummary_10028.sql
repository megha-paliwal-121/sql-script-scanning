-- Author: Y&L
-- Server on which the code is to be executed: 9901PSQLLMSV01
-- Database on which the code is to be executed: LMS
-- Application that the code will support: LMS
-- Description: dbo].[USP_Delete_Refresh_CollateralAccountLevelSummary] Stored Procedure
-- ETA < 1 min

CREATE   PROCEDURE [dbo].[USP_Delete_Refresh_CollateralAccountLevelSummary]     
       @ApplicationID BIGINT
      ,@LoginUser VARCHAR(100)
AS              
BEGIN              
BEGIN TRY              
 BEGIN TRANSACTION   
    select * from [DealCapture.LoanCollateralDetail]
    UPDATE [DealCapture.LoanCollateralDetail] SET IsDeleted=1 WHERE ApplicationId=@ApplicationID AND IsExclude=1
	UPDATE Refresh_CollateralAccountLevelSummary SET IsActive=0,UpdatedBy=@LoginUser,UpdatedDate=GETDATE() WHERE ApplicationId=@ApplicationID
 COMMIT TRAN
 SELECT 1
 END TRY            
            
 BEGIN CATCH       
   ROLLBACK TRAN
   EXECUTE [dbo].[uspLogError] '[dbo].[USP_Insert_Refresh_CollateralAccountLevelSummary]',NULL,''         
 END CATCH                    
END
GO



