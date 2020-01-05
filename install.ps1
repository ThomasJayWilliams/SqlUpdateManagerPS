clear-host
write-host "Install Manager" -foregroundcolor yellow
write-host "Use command [help], to get help about all commands available." -foregroundcolor yellow

#GLOBAL VARIABLES
$novalidation
$ignore
#GLOBAL VARIABLES
function updateDate {
    param([string]$path, [int]$d_month, [int]$d_day, [int]$d_year, [int]$d_hour, [int]$d_minute, [int]$d_second)
    $dateUpdate=$d_month.ToString() + "/" + $d_day + "/" + $d_year + " " + $d_hour + ":" + $d_minute + ":" + $d_second
    set-content $path -value $dateUpdate
}

function AddDbPath {
    param([string]$db)
    write-host "Enter path to"$db "procedures: " -nonewline
    $path=read-host
    if (!(test-path $path) -or !(test-path $path\Tableupdates.sql)) {
        if ($ignore -eq $false) {
            write-host "Entered path is invalid! TableUpdates is missing!" -foregroundcolor red
            AddDbPath -db $db
        }
        else {
            write-host "TableUpdates is missing! Continuation installation without TableUpdates!" -foregroundcolor yellow
            AddDbPath -db $db
        }
    }
    else {
        if (testQuery -db $db) {
            add-content config.ini -value $db"="$path
            if (!(test-path "lib\$db") -and !(test-path "lib\$db\lastUpdate.data") -and !(test-path "lib\$db\tableUpdatesTemplate.data") -and !(test-path "lib\$db\log.txt")) {
                new-item lib\$db -type dir
                new-item "lib\$db\log.txt" -type file
                new-item "lib\$db\lastUpdate.data" -type file
                $tempDate=get-date
                updateDate -path "lib\$db\lastUpdate.data" -d_month ($tempDate.month) -d_day ($tempDate.day) -d_year ($tempDate.year) -d_hour ($tempDate.hour) -d_minute ($tempDate.minute) -d_second ($tempDate.second)
                $dropTable="USE $db", "DROP TABLE T_Build_Info"
                $dropProc="DROP PROCEDURE spT_Build_InfoInsertUpdate"
                add-content "scripts\dropTables.sql" -value $dropTable
                add-content "scripts\dropTables.sql" -value $dropProc
                if (!(test-path "$path\TableUpdates.sql") -or $ignore -eq $true) {
                    write-host "Install is successefully finished, but tableUpdatesTemplate has not been created. For updating TableUpdates re-install update manager." -foregroundcolor yellow
                }
                else {
                    new-item "lib\$db\tableUpdatesTemplate.data" -type file
                    $tempData=get-content "$path\TableUpdates.sql"
                    set-content "lib\$db\tableUpdatesTemplate.data" -value $tempData
                }
                write-host "Required files has been successfully created." -foregroundcolor cyan
            }
        }
        else {
            hardreset -noinstall -force
            write-host "Entered data is wrong! Please, re-install SQL Update Manager!" -foregroundcolor red
        }
    }
}

function GetParams {
    $cnt=get-content config.ini
    $params="", "", ""
    $params[0]=($cnt[0].split("="))[1]
    $params[1]=($cnt[1].split("="))[1]
    $params[2]=($cnt[2].split("="))[1] 
    return $params   
}

function testQuery {
    param([string]$db)
    if ($novalidation -eq $true) {
        return $true
    }
    else {
        $params=GetParams
        write-host "Checking database configuration, please, wait..." -foregroundcolor yellow
        sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -d $db -I -i scripts\updateInfo.sql -b
        if ($LASTEXITCODE -gt 0) {
            return $false
        }
        else {
            sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -d $db -I -i scripts\spT_Build_InfoInsertUpdate.sql -b
            write-host "Entered configuration data has been validated." -foregroundcolor green
            return $true
        }
    }
}

########
#COMMANDS
########
function install {
    param([switch]$novalidation, [switch]$notu)
    $ignore=$notu
    if(test-path "config.ini") {
        write-host "SQL Update Manager is already installed." -foregroundcolor yellow
        write-host "Reset current config, if you want ro reinstall program." -foregroundcolor yellow
    }
    else {
        if (!(test-path "config.ini")) {
            new-item "config.ini" -type file
            write-host "config.ini has been created." -foregroundcolor cyan
        }
        write-host "Please, set the configuration." -foregroundcolor white
        write-host "If you've made a mistake, you can edit configuratios in config.ini." -foregroundcolor white
        write-host "Or use command [hardreset] to clear all settings." -foregroundcolor white
        write-host "WARNING! DO NOT CLOSE CONSOLE DURING INSTALLATION PROCESS! THIS MAY CAUSE ERRORS!" -foregroundcolor yellow
        $qArray="SQL Server name:", "Username:", "Password:", "Database names (Split using [space]):"
        $dbs
        for ($i=0; $i -lt 4; $i++) {
            write-host $qArray[$i]"" -nonewline
            if ($i -eq 3) {
                $temp=read-host
                $dbs=$temp.Split(" ")
                break
            }
            $data=read-host
            $param=$qArray[$i]
            add-content config.ini -value $param"="$data
        }
        write-host "Configure paths." -foregroundcolor green
        foreach ($el in $dbs) {
            AddDbPath -db $el
        }
        write-host "Configuration has been finished." -foregroundcolor green
    }
}

function adddatabase {
    param([switch]$notu)
    $ignore=$notu
    write-host "Enter database names (Split using [space]): " -nonewline
    $readHost=read-host
    $dbs=$readHost.split(" ")
    foreach($el in $dbs) {
        AddDbPath -db $el
    }
    $ignore=$false
}

function quit {
    stop-process -name "powershell"
}

function hardreset {
    param([switch]$noinstall, [switch]$force)
    if ($force -eq $false) {
        write-host "Hardreset mode will delete databases folders. Also, you will have to immediately start install process. Do you want to continue? [yes\no]" -foregroundcolor red
    }
    if ($force -eq $true -or (read-host) -like "yes" -and (test-path config.ini)) {
        $params=GetParams
        sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -I -i scripts\dropTables.sql
        clear-content "scripts\dropTables.sql"
        remove-item "config.ini" -ErrorAction SilentlyContinue
        remove-item "lib\*" -recurse -exclude "runUpdate.ps1" -force -erroraction silentlycontinue
        write-host "Temporary data has been removed!" -foregroundcolor green
        if ($noinstall -eq $false) {
            install
        }
    }
    else {
        write-host "Hardreseting has been interrupted!" -foregroundcolor red
    }
}

function help {
    foreach ($ele in (get-content helpinstall.txt)) {
        write-host $ele
    }
}

function manual {
    foreach ($el in (get-content Readme.txt)) {
        write-host $el
    }
}

function goto {
    write-host "Running Update Console..." -foregroundcolor yellow
    invoke-expression ".\updateDatabase.ps1 -upd"
}

function reset {
    if (test-path "config.ini") {
        write-host "All of your settings will be removed. Do you want to continue? [yes/no]" -foregroundcolor white
        if ((read-host) -like "yes") {
            remove-item "config.ini"
            write-host "config.ini has been deleted." -foregroundcolor cyan
        }
        else {
            write-host "You have cancelled reseting." -foregroundcolor red
        }
    }
    else {
        write-host "config.ini is not found. Install is available." -foregroundcolor yellow
    }
}

for ( ; ; ) {
    $readHost=read-host
    if ($readHost -notlike "adddbpath" -and $readHost -notlike "updatedate" -and $readHost -notlike "exit" -and $readHost -notlike "testQuery") {
        invoke-expression $readHost
    }
}