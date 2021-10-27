param (

    # location of extracted data
    $sourcePath =    $PWD

)


<#
.COPYRIGHT
Copyright (c) Microsoft Corporation. All rights reserved. Licensed under the MIT license.
See LICENSE in the project root for license information.
#>
 

function Get-RegPath {
    param (
            $RegFilePath 
        )
         

    $regFile = Join-Path $RegFilePath "export.reg"

    # get the first line that start with [HKEY...    

    foreach($line in [System.IO.File]::ReadLines($regFile) ) {
            if ($line -match "^\[HKEY_" ) { 
                $parsedLine = ""
                # remove square brackets
                $parsedLine = $line -replace "[\[\]]", ""
                $parsedLine = $parsedLine -replace "\\", "_"
                $parsedLine = $parsedLine -replace " ", "_"
                $parsedLine += ".reg"
                $parsedLine
                break
                }
        }
    
     
}


function Parse_Outputlog {
    param (
        $outputlogPath
    )

    $ParsedFilename = "unknown_Output.log"

    $fileContents = Get-Content $outputlogPath

    if ($fileContents -match "AzureAdPrt :") {
        $ParsedFilename = "dsregcmd_status.txt"
    }
    elseif ($fileContents -match   "================ Certificate") {
        $ParsedFilename = "certificates_machine.txt"
    }
    # TODO - validate this.  Blank in sample data
    elseif ($fileContents -match   "my `"Personal`"") {
        $ParsedFilename = "certificates_user.txt"
    }

    elseif ($fileContents -match   "Pinging .*with 32 bytes of data:") {
        $ParsedFilename = "ping_test.txt"
    }
    elseif ($fileContents -match   "Current WinHTTP proxy settings:") {
        $ParsedFilename = "proxy_settings.txt"
    }
    elseif ($fileContents -match   "Windows IP Configuration") {
        $ParsedFilename = "ipconfig.txt"
    }

    elseif ($fileContents -match   "AuthzComputerGrpTransport") {
        $ParsedFilename = "Firewall_Global_settings.txt"
    }
    # TODO - verify netsh commands - 
    # failure 
    elseif ($fileContents -match   "The Wired AutoConfig Service \(dot3svc\) is not running.") {
        $ParsedFilename = "netsh_wlan_show_profiles.txt"
    }
    # success
    elseif ($fileContents -match   "Profiles on interface Wi-Fi:" ) {
        $ParsedFilename = "netsh_wlan_show_profiles.txt"
    }
    # firewall  settings
    elseif ($fileContents -match "LocalFirewallRules"){
        $ParsedFilename = "firewall_profiles.txt"
    }                     

    # skip utility output
    elseif ( ($fileContents -match "Battery life report saved ")    -or  `
        ($fileContents -match "Generating report ... ")             -or
        ($fileContents -match "Enabling tracing for 60 seconds...") -or
        ($fileContents -match "MpCmdRun.exe`" -GetFiles")           -or
        ($fileContents -match "Succeeded to CollectLog")            -or 
        ($fileContents -match "Collecting licensing information.")  # license diag        
       
    ) { 
        $ParsedFilename = "metadata_" + $(Get-Random -Maximum 10000000 -Minimum 1000000) + ".txt"
        
        }
    
    else {
        $ParsedFilename = "Unknow_Command_Result_" + $(Get-Random -Maximum 10000000 -Minimum 1000000) + ".txt"
    }


    


    $ParsedFilename
    
}

function New-DiagFolderStructure {
    param( 
        $tempfolder
    )
    
    # Cleanup if results left from previous run
    if (test-path $tempfolder ) { $x = del $tempfolder -Recurse -Force }
    $x = mkdir $tempfolder -Force

    $x = mkdir $tempfolder\Registry  -Force
    $x = mkdir $tempfolder\EventLogs -Force
    $x = mkdir $tempfolder\MetaData  -Force

}

# REGION Main
$tempfolder =  Join-Path $env:temp "IntuneDeviceData"
$x = New-DiagFolderStructure -tempfolder $tempfolder 

$diagfolders = @()
$diagfolders = Get-ChildItem $sourcePath -Directory
 
$session  = New-Object -TypeName System.Diagnostics.Eventing.Reader.EventLogSession  

foreach ( $diagfolder  in $diagfolders) {
    
    # ### Registry keys
    $fullDiagPath = $diagfolder.FullName

    if (Test-Path "$fullDiagPath\export.reg") {
        $ParsedFileName = Get-RegPath -RegFilePath $fullDiagPath
        $destinationFile = Join-Path "$tempfolder\Registry" $ParsedFileName

        copy "$fullDiagPath\export.reg" $destinationFile
    }

    # ### Event Logs

    elseif (Test-Path "$fullDiagPath\Events.evtx") {
        $evtx = join-path $fullDiagPath "Events.evtx"
 
        # 2 = open saved evtx file mode
        $LogInfo= $session.GetLogInformation($evtx, 2)
        if ( $LogInfo.RecordCount -eq 0) {
            Write-Output "Skipping empty event log $evtx"
            }
        else {
             $logName = (Get-WinEvent -Path $evtx -Oldest -MaxEvents 1).LogName
             $logName = $logName -replace "\/", "-"              
             $destination = (Join-Path "$tempfolder\EventLogs" "$logName"  ) + ".evtx"
             
             copy $evtx $destination
        }
        
    }

    # ### Windows Update

    elseif (Test-Path "$fullDiagPath\windowsupdate.*.etl") {
      $x =  Get-WindowsUpdateLog -ETLPath $fullDiagPath -LogPath $tempfolder\WindowsUpdate.log 1> null
    }

    # ### ConfigMgr client logs
    elseif (Test-Path "$fullDiagPath\ccmexec.log") {
        $ccmClientFolder = Join-Path $tempfolder ConfigMgr_client_logs
        $x = mkdir $ccmClientFolder
        copy $fullDiagPath\* $ccmClientFolder
    }

    # ### ConfigMgr setup

    elseif (Test-Path "$fullDiagPath\ccmsetup*.log") {
        $ccmClientSetupFolder = Join-Path $tempfolder ConfigMgr_client_setup_logs
        $x = mkdir $ccmClientSetupFolder
        copy $fullDiagPath\* $ccmClientSetupFolder
    }

    # ### measuredboot logs

    elseif (Test-Path "$fullDiagPath\00000*-00000*.log") {
        $MeasuredBoot = Join-Path $tempfolder MeasuredBoot_Logs
        $x = mkdir $MeasuredBoot
        copy $fullDiagPath\* $MeasuredBoot
    }

    # ### IME (SideCar) logs

    elseif (Test-Path "$fullDiagPath\intunemanagementextension.log") {
        $SideCar = Join-Path $tempfolder Intune_Management_Extension_Logs
        $x = mkdir $SideCar
        copy $fullDiagPath\* $SideCar
    }

    # ### Autopilot ETLs

    elseif (Test-Path "$fullDiagPath\diagnosticlogcsp_collector_autopilot*.etl") {
        $ApETLs = Join-Path $tempfolder Autopilot_ETL_Logs
        $x = mkdir $ApETLs
        copy $fullDiagPath\* $ApETLs
    }

    # ### Miscellaneous files

    elseif ( (Test-Path "$fullDiagPath\*.html") -or (Test-Path "$fullDiagPath\msinfo32.log") -or (Test-Path "$fullDiagPath\cbs.log") 
             ) {
         
        copy $fullDiagPath\*   $tempfolder
    }

    # ### Cab files.  Automatically extract
    elseif (Test-Path "$fullDiagPath\*.cab") {
        $cabFolder = ""
        $cabName = ""
        $baseName = ""

        $cabName = (Get-ChildItem "$fullDiagPath\*.cab").Name
        $baseName =  $cabName -replace ".cab", ""

        $cabFolder = Join-Path $tempfolder $( $basename + "_extracted")
        $x = mkdir $cabFolder     
         
        $x = expand $fullDiagPath\$cabName -I -F:* $cabFolder 
        

        # mdmlogs has embedded CAB

        if (Test-Path $cabFolder\*.cab) {
            $x = expand $cabFolder\*.cab   -F:* $cabFolder 
        } 
    }


    # ### Command output

    elseif (Test-Path "$fullDiagPath\output.log") {
       # type $fullDiagPath\output.log
       $newFileName = ""
       $newFileName = Parse_Outputlog -outputlogPath "$fullDiagPath\output.log"

       if ( ($newFileName -match "metadata_") -or ($newFileName -match "Unknow_Command_Result") ){
            copy "$fullDiagPath\output.log" "$tempfolder\MetaData\$newFileName"  
            }
       else {
            copy "$fullDiagPath\output.log" "$tempfolder\$newFileName"
            }
    }

}

start $tempfolder