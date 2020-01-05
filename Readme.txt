	SQL Update Manager
	---------------------------------------------
	To get manual in the shell use [manual] command.
	---------------------------------------------
	This program was made for automatically update stored procedures in SQL Server.
	Program looks like shell and are runned by the input commands. Most of commands have parameters.
	Commands look like special text. Command example: help
	Parameters represent a additional information for commands. Paramter example: 
	Manager has two work modes: Installation Mode (Install shortcut) and Update Mode (Run shortcut).
	In SQL Update Manager shell all information is marked by different colours:
		green - means succussefull process or command executing
		yellow - means additional information about current process and information you need to necessarily read
		red - means, that on some of step error apeared and usually contains information about error
		cyan - displays current process and actions with files
		white - all other information
	---------------------------------------------
	Installation Mode/Install:
	This mode provided for configure Update Manager with your own SQL Server parameters.

	Update Mode/Run:
	This mode is used for update procedures.
	---------------------------------------------
	Instruction for using SQL Update Manager.
	Shortcuts:
		# - remember, additional information
		! - warning
		[, ] - symbols, signifying Update Manager commands
		<, > - symbols, signifying command parameters

	After you downloaded SQL Update Manager you need to provide installation - set Update Manager configuration based on your SQL Server parameters.

	To run Installation Mode use "Install" shortcut in SQLUpdateManager directory. The shell windows will appear.
		#To control installation process use available commands. To get information about all commands available use [help] command.

	After you runned installation mode you need to start installation process. Use command [install] to start installation.
		#During the installation process you will enter your database connection parameters and program will automatically validate it by sending SQL query to the server.
		#If you want to disable validation step use parameter <-novalidation> in [install] command. Example: install -novalidation
		!Normally you shouldn not disable validation! Disabling validation may produce errors in update process, if you entered wrong connection parameters!

	When installation will start you will have to enter required information, like SQL server name, username, password.
		!Update Manager works with SQL Server, with authentification type seted up as "SQL Server Authentification" only. In other case Update Manager CANNOT be used!
		#During installation process you will be asked for authentification data. To enter data just follow the notices appeared.
		#After you will enter Servername, Username, Password, Database names and paths to procedures of each database, program will automatically create directories, named as database names with required files.
		#Also, after you will enter required data, program will create T_Build_Info table in each database. In this table after every update will be writen log information.

	After you will enter all of data required installation will be finished. You can use Update Mode. To run Update Mode use "Run" shortcut or use [goto] command.
		!If after you finished installation you will see red text/error message - re-install manager. But before re-installation clear existing parameters by using [hardreset] command.

	In the Update Mode you can start updating procedures by using [update] command.
		#Update Manager update only those files, which has been updated later, then last time you SUCCESSFULLY runned [update].

	To start update obsolete procedures type [update] with following parameter: <database name>, where "database_name" is the name of database you want to update and which you installed early.
		#[update] command have other parameters, that will help you update database as you want. To get list of these parameters use [help] command.

	After you start update program will show you list of procedures, that will be updated and TableUpdates query, that will be executed. Here you need to confirm or cancel update.
		!Normally, if TableUpdates query execution failed (SQL error), updating process will be interrupted. But if you to ignore TableUpdates use <-notu> parameter with [update] command.
		#If current executing procedure failed, you will see the SQL error and will be asked for continue. If you want to ignore procedure errors use <-ignoreproc> parameter with [update] command.
	
	After update process will be finished you can exit from manager by using [quit] command or by closing window.

	Beside [update] command you can use [deploy], to execute ALL procedures.
		#Usually, [deploy] takes some time.
		#[deploy] has almost the same parameters [update] has. To get list of all [deploy] parameters use [help] command.
	---------------------------------------------