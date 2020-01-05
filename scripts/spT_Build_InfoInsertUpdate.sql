CREATE PROCEDURE spT_Build_InfoInsertUpdate
	@Update_Date VARCHAR(MAX),
	@Procedures_Updated VARCHAR(MAX),
	@TableUpdates_Query NVARCHAR(MAX),
	@Error_Log NVARCHAR(MAX)
AS
	INSERT INTO T_Build_Info (Update_Date, Procedures_Updated, TableUpdates_Query, Error_Log, Last_Scripts_Revision_Applied, Last_Code_Revision_Applied)
	VALUES (
		@Update_Date,
		@Procedures_Updated,
		@TableUpdates_Query,
		@Error_Log,
		NULL,
		NULL);
GO