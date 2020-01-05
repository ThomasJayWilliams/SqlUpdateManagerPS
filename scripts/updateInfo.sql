CREATE TABLE T_Build_Info (
	PK_Build_Info INT IDENTITY PRIMARY KEY NOT NULL,
	Update_Date VARCHAR(MAX) NOT NULL,
	Procedures_Updated VARCHAR(MAX) NULL,
	TableUpdates_Query NVARCHAR(MAX) NULL,
	Error_Log NVARCHAR(MAX) NULL,
	Last_Scripts_Revision_Applied NVARCHAR(MAX) NULL,
	Last_Code_Revision_Applied NVARCHAR(MAX) NULL);