param([switch]$lazymode, [string]$lazymodedb)
clear-host
write-host "SQL Update Manager" -foregroundcolor yellow
$path
$test=$false
$db
$force
$ignoretu
$ignoreproc

function buildInfo {
    param([string]$dbname, [array]$list, [array]$erorrlog, [array]$query)
    $params=GetParams
    $date=get-date
    $newList=[string]$list
    $newQuery=[string]$query
    if($newQuery.Contains('''')) {
        $newQuery = $newQuery.Replace('''', '')
    }
    $newErrorLog=([string]$erorrlog).replace("'", "")
    $query="EXEC spT_Build_InfoInsertUpdate @Update_Date = '$date',
    @Procedures_Updated = '$newList',
    @TableUpdates_Query = '''$newQuery''',
    @Error_Log = '''$newErrorLog'''"
    tableTemp -query $query
    $errorText=sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -b -I -d $dbname -i "lib\$dbname\temp.sql" 2>&1
    tableTemp -remove
    if($LASTEXITCODE -gt 0) {
        write-host "Error appeared while adding record to T_Build_Info!" -foregroundcolor red
        write-host $errorText
        return $false
    }
    else {
        return $true
    }
}

function deployExecute {
    param([array]$params, [array]$list, [string]$dbname)
    $logList=@()
    $tempLocation=get-location
    set-location $path
    $logList+="DEPLOYEMENT"
    foreach($el in $list) {
        write-host "Updating"$el"..." -foregroundcolor cyan
        $errorText=sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -b -I -d $dbname -i $el 2>&1
        $logList+=$el
        if($LASTEXITCODE -gt 0) {
            write-host "Execution failed!" -foregroundcolor red
            write-host $errorText
            $logList+="Faled!", $errorText, ""
            if($force -eq $false -and $ignoreproc -eq $false) {
                while($true) {
                    write-host "Continue deployement? [yes/no/ignore]" -foregroundcolor white
                    $readHost=read-host
                    if($readHost -like "yes") {
                        break
                    }
                    if($readHost -like "no") {
                        set-location $tempLocation
                        return $false
                    }
                    if($readHost -like "ignore") {
                        $force=$true
                        break
                    }
                    else {
                        write-host "Command not found!" -foregroundcolor red
                        continue
                    }
                }
            }
        }
        else {
            $logList+="Success!", ""
            write-host "Success!" -foregroundcolor green
        }
    }
    set-location $tempLocation
    updateLog -log $logList
    return $true
}

function GetParams {
    $cnt=get-content config.ini
    $servername=($cnt[0].split("="))[1]
    $username=($cnt[1].split("="))[1]
    $password=($cnt[2].split("="))[1]
    return $servername, $username, $password    
}

function getLastWriteTime {
    $dirList=(get-childitem $path -file) | where-object {$_.extension -like ".sql"}
    $dirList=$dirList | sort-object {$_.lastwritetime}
    $lastProcUpd=(($dirList| select-object -last 1).lastwritetime)
    return $lastProcUpd
}

function getDiffContent {
    $notab=test-path "lib\$db\tableUpdatesTemplate.data"
    if($notab -eq $true) {
        $oldTab=get-content "lib\$db\tableUpdatesTemplate.data"
        $newTab=get-content $path\TableUpdates.sql
        $diff=compare-object $oldTab $newTab
        return $diff.inputobject
    }
    else {
        return ""
    }
}

function tableTemp {
    param([array]$query, [switch]$remove)
    if(test-path lib\$db\temp.sql) {
        remove-item lib\$db\temp.sql -force
    }
    if($remove -eq $false) {
        new-item lib\$db\temp.sql -type file -force
        set-content lib\$db\temp.sql -value $query
    }
    if($rmeove -eq $true) {
        remove-item lib\$db\temp.sql -force
    }
}

function updateDate {
    param([string]$pathU, [int]$d_month, [int]$d_day, [int]$d_year, [int]$d_hour, [int]$d_minute, [int]$d_second)
    $dateUpdate=$d_month.ToString() + "/" + $d_day + "/" + $d_year + " " + $d_hour + ":" + $d_minute + ":" + $d_second
    if($test -eq $false) {
        set-content $pathU -value $dateUpdate
    }
}

function saveUpdate {
    $tempData=get-content $path\TableUpdates.sql
    $notab=!(test-path "lib\$db\tableUpdatesTemplate.data")
    if($test -eq $false -and $notab -eq $false) {
        set-content "lib\$db\tableUpdatesTemplate.data" -value $tempData
    }
    write-host "tableUpdatesTemplate.data has been updated" -foregroundcolor cyan
    $tempDate=get-date
    updateDate -path "lib\$db\lastUpdate.data" -d_month ($tempDate.month) -d_day ($tempDate.day) -d_year ($tempDate.year) -d_hour ($tempDate.hour) -d_minute ($tempDate.minute) -d_second ($tempDate.second)
    write-host "lastUpdate.data has been updated" -foregroundcolor cyan
}

function updateLog {
    param([array]$log)
    $temp=get-date
    $val="<---Update date: " + $temp + "--->"
    if($test -eq $false) {
        add-content -path "lib\$db\log.txt" -value $val
        add-content -path "lib\$db\log.txt" -value "Updated procedures:"
        foreach($el in $log) {
            add-content -path "lib\$db\log.txt" -value $el
        }
        add-content -path "lib\$db\log.txt" -value ""
    }
}

function getOldFiles {
    param([datetime]$upd)
    $pile=(get-childitem $path -file)
    return $pile | where-object {$_.extension -like ".sql"} | where-object {$_.lastwritetime -gt $upd}
}

function executeProcedures {
    param([array]$list)
    $logList=@()
    $params=GetParams
    $biErrorLog
    $biQuery
    $go=$force
    $notab=test-path "lib\$db\tableUpdatesTemplate.data"
    $tempList=$list.name
    for ($i=0; $i -lt ($list.length); $i++) {
        if($list[$i].name -notlike "TableUpdates.sql") {
            write-host $list[$i].name "will be updated." -foregroundcolor cyan
        }
    }
    if($tempList -contains "TableUpdates.sql" -and $notab -eq $true) {
        $query=getDiffContent
        tableTemp -query $query
        $query=get-content lib\$db\temp.sql
        $biQuery=$query
        write-host "Start of query" -foregroundcolor yellow
        foreach ($el in $query) {
            write-host $el
        }
        write-host "End of query" -foregroundcolor yellow
        if($force -eq $false) {
            write-host "Update database? [yes/no]" -foregroundcolor white
            if((read-host) -like "yes") {
                $go=$true
            }
            else {
                tableTemp -remove
                return $false
            }
        }
        if($go -eq $true) {
            if($test -eq $false) {
                $errorText=sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -b -I -d $db -i lib\$db\temp.sql
                if($LASTEXITCODE -gt 0) {
                    $biErrorLog+=$errorText
                    write-host "Execution failed!" -foregroundcolor red
                    write-host $errorText
                    if($ignoretu -eq $false) {
                        tableTemp -remove
                        return $false
                    }
                }
                write-host "Tables has been updated!" -foregroundcolor green
            }
        }
        tableTemp -remove
    }
    if($tempList -notcontains "TableUpdates.sql" -or $notab -eq $false) {
        if($force -eq $false) {
            write-host "Update database? [yes/no]" -foregroundcolor white
            if((read-host) -like "yes") {
                $go=$true
            }
            else {
                return $false
            }
        }
    }
    if($go -eq $true) {
        $temp=get-location
        set-location $path
        $rList=$list | where-object {$_.name -notlike "TableUpdates.sql"}
        if($test -eq $false -and $rList.length -gt 0) {
            write-host "Executing procedures. This can take few minutes. Please, wait..." -foregroundcolor yellow
            foreach ($el in $rList.name) {
                write-host "Updating" $el"..." -foregroundcolor cyan
                $errorText=sqlcmd.exe -S $params[0] -U $params[1] -P $params[2] -b -I -d $db -i $el 2>&1
                $logList+=$el
                if($LASTEXITCODE -gt 0) {
                    $biErrorLog+=$errorText
                    $logList+="Failed!", $errorText, ""
                    write-host "Failed! Error text: " -foregroundcolor red
                    write-host $errorText
                    if($force -eq $false -and $ignoreproc -eq $false) {
                        while($true) {
                            write-host "Continue execution? [yes/no/ignore]" -foregroundcolor white
                            $readHost=read-host
                            if($readHost -like "yes") {
                                break
                            }
                            if($readHost -like "no") {
                                set-location $temp
                                return $false
                            }
                            if($readHost -like "ignore") {
                                $force=$true
                                break
                            }
                            else {
                                write-host "Command not found!" -foregroundcolor red
                                continue
                            }
                        }
                    }
                    else {
                        continue
                    }
                }
                else {
                    $logList+="Success!", ""
                    write-host "Success!" -foregroundcolor green
                }
            }
        }
        set-location $temp
        updateLog -log $logList
        return buildInfo -dbname $dbname -query $biQuery -list $rList.name -erorrlog $biErrorLog
    }
}

function deploy {
    param([string]$dbname, [switch]$force, [switch]$test, [switch]$ignoreproc)
    $force=$force
    $ignoreproc=$ignoreproc
    $db=$dbname
    $test=$test
    $content=get-content "config.ini"
    for ($i=0; ; $i++) {
        if(($content | out-string).Contains($dbname) -eq $false) {
            write-host "Entered database name does not exist!" -foregroundcolor red
            write-host "Checkout config.ini for mistakes." -foregroundcolor yellow
            $force=$false
            $ignoreproc=$false
            return
        }
        if($content[$i].contains($dbname)) {
            $path=$content[$i].split("=")[1]
            break
        }
    }
    $list=get-childitem $path -file | where-object {$_.name -like "spT*.sql" -or $_.name -like "spL*.sql" -or $_.name -like "udf*sql"}
    $fileList=$list.name
    foreach($el in $fileList) {
        write-host $el -foregroundcolor yellow
    }
    if($force -eq $false) {
        while($true) {
            write-host "Deploy database? [yes/no]" -foregroundcolor white
            $readHost=read-host
            if($readHost -like "yes") {
                break
            }
            if($readHost -like "no") {
                $force=$false
                $ignoreproc=$false
                write-host "Deplyement has been cancelled!" -foregroundcolor red
                return
            }
            else {
                write-host "Command not found!" -foregroundcolor red
                continue
            }
        }
    }
    $params=GetParams
    if($test -eq $true) {
        return
    }
    else {
        $result=deployExecute -params $params -list $fileList -dbname $dbname
        if($result -eq $true) {
            $force=$false
            $ignoreproc=$false
            $logList=""
            write-host "Deployement has been successfully finished!" -foregroundcolor green
            return
        }
        if($result -eq $false) {
            $force=$false
            $ignoreproc=$false
            $logList=""
            write-host "Deployement has been failed!" -foregroundcolor red
            return
        }
    }
}

function update {
    param([string]$dbname, [switch]$test, [switch]$force, [switch]$notu, [switch]$ignoreproc, [switch]$ignoretu)
    if($dbname -ne "") {
        $test=$test
        $force=$force
        $ignoreproc=$ignoreproc
        $ignoretu=$ignoretu
        if(!(test-path ".\config.ini")) {
            write-host "Config.ini is missing! You need to set settings, before starting to use Update Manager." -foregroundcolor red
            write-host "Use command [goto], to redirect to Install Manager." -foregroundcolor yellow
        }
        else {
            if(!(test-path "lib\$dbname")) {
                write-host "Database not found! Checkout config.ini!" -foregroundcolor red
            }
            else {
                $db=$dbname
                $lastUpdate=get-content "lib\$db\lastUpdate.data"
                $content=get-content "config.ini"
                for ($i=0; ; $i++) {
                    if(($content | out-string).Contains($db) -eq $false) {
                        write-host "Entered database name does not exist!" -foregroundcolor red
                        write-host "Checkout config.ini for mistakes." -foregroundcolor yellow
                        return $false
                    }
                    if($content[$i].contains($db)) {
                        $path=$content[$i].split("=")[1]
                        break
                    }
                }
                $notab=test-path "lib\$db\tableUpdatesTemplate.data"
                $temp=getLastWriteTime
                $filesList=getOldFiles -upd $lastUpdate
                if($notab -eq $false -or (getDiffContent).length -lt 2 -or $notu -eq $true) {
                    $filesList=$filesList | where-object {$_.name -notlike "TableUpdates.sql"}
                }
                if($notab -eq $false -and $filesList -ne $NULL -and $filesList.gettype() -like 'System.IO.FileInfo' -and $filesList.name -contains "TableUpdates.sql" -or $filesList.length -eq 0) {
                    write-host $db "contains last versions of files" -foregroundcolor yellow
                }
                elseif($temp -gt $lastUpdate) {
                    write-host $db "contains not executed files" -foregroundcolor yellow
                    $result=executeProcedures -list $filesList
                    $force=$false
                    $ignoreproc=$false
                    $ignoretu=$false
                    if($result -eq $true) {                                                                   
                        start-sleep -s 2
                        write-host $db "has been successfully updated." -foregroundcolor green
                        saveUpdate
                    }
                    else {
                        $force=$false
                        $ignoreproc=$false
                        write-host "Update has been interrupted!" -foregroundcolor red
                    }
                }
                else {
                    write-host $db "contains last versions of files" -foregroundcolor yellow
                }
            }
        }
    }
    else {
        write-host "Error! You have to enter param [-dbname] to start update!" -foregroundcolor red
    }
}

function goto {
    invoke-expression ".\updateDatabase.ps1 -install"
}

function help {
    foreach ($ele in (get-content helpupdate.txt)) {
        write-host $ele
    }
}

function manual {
    foreach ($el in (get-content Readme.txt)) {
        write-host $el
    }
}

function examples {
    foreach ($el in (get-content Examples.txt)) {
        write-host $el
    }
}

function quit {
    stop-process -name "powershell"
}

for ( ; ; ) {
    if($lazymode -eq $true) {
        update -db $lazymodedb -force -ignoreproc -ignoretu
        start-sleep -s 1
        quit
    }
    $readHost=read-host
    invoke-expression $readHost
}