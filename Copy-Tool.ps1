<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Copy Tool
.SYNOPSIS
    Utilizing the build-in robocopy command to copy data with a progress bar
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$CopyTool                        = New-Object system.Windows.Forms.Form
$CopyTool.ClientSize             = New-Object System.Drawing.Point(705,400)
$CopyTool.text                   = "Copy Tool"
$CopyTool.TopMost                = $false

$sourceBox                       = New-Object system.Windows.Forms.TextBox
$sourceBox.multiline             = $false
$sourceBox.text                  = "Type or browse for source..."
$sourceBox.width                 = 450
$sourceBox.height                = 20
$sourceBox.location              = New-Object System.Drawing.Point(30,90)
$sourceBox.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$destinationBox                  = New-Object system.Windows.Forms.TextBox
$destinationBox.multiline        = $false
$destinationBox.text             = "Type or browse for destination..."
$destinationBox.width            = 450
$destinationBox.height           = 20
$destinationBox.location         = New-Object System.Drawing.Point(30,219)
$destinationBox.Font             = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$sourceButton                    = New-Object system.Windows.Forms.Button
$sourceButton.text               = "Browse"
$sourceButton.width              = 60
$sourceButton.height             = 30
$sourceButton.location           = New-Object System.Drawing.Point(503,83)
$sourceButton.Font               = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$destinationButton               = New-Object system.Windows.Forms.Button
$destinationButton.text          = "Browse"
$destinationButton.width         = 60
$destinationButton.height        = 30
$destinationButton.location      = New-Object System.Drawing.Point(502,215)
$destinationButton.Font          = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$startCopy                       = New-Object system.Windows.Forms.Button
$startCopy.text                  = "Start Copy"
$startCopy.width                 = 60
$startCopy.height                = 30
$startCopy.location              = New-Object System.Drawing.Point(494,333)
$startCopy.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)

$ProgressBar1                    = New-Object system.Windows.Forms.ProgressBar
$ProgressBar1.width              = 449
$ProgressBar1.height             = 60
$ProgressBar1.location           = New-Object System.Drawing.Point(31,314)

$CopyTool.controls.AddRange(@($sourceBox,$destinationBox,$sourceButton,$destinationButton,$startCopy,$ProgressBar1))

# Resize PowerShell window
$psHost = Get-Host
$psWindow = $psHost.UI.RawUI
$psWindow.WindowTitle = "Copy Tool Output"

# Self-elevate script if not running as Administrator
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

# Write your logic code here


$startCopy.Add_Click{
    Copy-WithProgress -Source "C:\Program Files" -Destination "C:\Users\User\Desktop\folder fdss 'fds;"
}

#End code

#Functions start

function Copy-WithProgress {
    [CmdletBinding()]
    param (
            [Parameter(Mandatory = $true)]
            [string] $Source
        , [Parameter(Mandatory = $true)]
            [string] $Destination
        , [int] $Gap = 200
        , [int] $ReportGap = 2000
    )
    # Define regular expression that will gather number of bytes copied
    $RegexBytes = '(?<=\s+)\d+(?=\s+)';

    #region Robocopy params
    # MIR = Mirror mode
    # NP  = Don't show progress percentage in log
    # NC  = Don't log file classes (existing, new file, etc.)
    # BYTES = Show file sizes in bytes
    # NJH = Do not display robocopy job header (JH)
    # NJS = Do not display robocopy job summary (JS)
    # TEE = Display log in stdout AND in target log file
    $CommonRobocopyParams = '/MIR /NP /NDL /NC /BYTES /NJH /NJS';
    #endregion Robocopy params

    #region Robocopy Staging
    Write-Verbose -Message 'Analyzing robocopy job ...';
    $StagingLogPath = '{0}\temp\{1} robocopy staging.log' -f $env:windir, (Get-Date -Format 'yyyy-MM-dd HH-mm-ss');

    $StagingArgumentList = '"{0}" "{1}" /LOG:"{2}" /L {3}' -f $Source, $Destination, $StagingLogPath, $CommonRobocopyParams;
    Write-Verbose -Message ('Staging arguments: {0}' -f $StagingArgumentList);
    Start-Process -Wait -FilePath robocopy.exe -ArgumentList $StagingArgumentList -NoNewWindow;
    # Get the total number of files that will be copied
    $StagingContent = Get-Content -Path $StagingLogPath;
    $TotalFileCount = $StagingContent.Count - 1;

    # Get the total number of bytes to be copied
    [RegEx]::Matches(($StagingContent -join "`n"), $RegexBytes) | % { $BytesTotal = 0; } { $BytesTotal += $_.Value; };
    Write-Verbose -Message ('Total bytes to be copied: {0}' -f $BytesTotal);
    #endregion Robocopy Staging

    #region Start Robocopy
    # Begin the robocopy process
    $RobocopyLogPath = '{0}\temp\{1} robocopy.log' -f $env:windir, (Get-Date -Format 'yyyy-MM-dd HH-mm-ss');
    $ArgumentList = '"{0}" "{1}" /LOG:"{2}" /ipg:{3} {4}' -f $Source, $Destination, $RobocopyLogPath, $Gap, $CommonRobocopyParams;
    Write-Verbose -Message ('Beginning the robocopy process with arguments: {0}' -f $ArgumentList);
    $Robocopy = Start-Process -FilePath robocopy.exe -ArgumentList $ArgumentList -Verbose -PassThru -NoNewWindow;
    Start-Sleep -Milliseconds 100;
    #endregion Start Robocopy

    #region Progress bar loop
    while (!$Robocopy.HasExited) {
        Start-Sleep -Milliseconds $ReportGap;
        $BytesCopied = 0;
        $LogContent = Get-Content -Path $RobocopyLogPath;
        $BytesCopied = [Regex]::Matches($LogContent, $RegexBytes) | ForEach-Object -Process { $BytesCopied += $_.Value; } -End { $BytesCopied; };
        $CopiedFileCount = $LogContent.Count - 1;
        Write-Verbose -Message ('Bytes copied: {0}' -f $BytesCopied);
        Write-Verbose -Message ('Files copied: {0}' -f $LogContent.Count);
        $Percentage = 0;
        if ($BytesCopied -gt 0) {
           $Percentage = (($BytesCopied/$BytesTotal)*100)
        }
        Write-Progress -Activity Robocopy -Status ("Copied: {0} of {1} files | Copied: {2} of {3} GB | Percent complete: {4}%" -f $CopiedFileCount, $TotalFileCount, [math]::Round(($BytesCopied/1073741824),2), [math]::Round(($BytesTotal/1073741824),2), [math]::Round($Percentage,2)) -PercentComplete $Percentage
    }
    Write-Progress -Activity Robocopy -Status "Ready" -Completed
    #endregion Progress loop

    #region Function output
    #[PSCustomObject]@{
    #    BytesCopied = $BytesCopied;
    #    FilesCopied = $CopiedFileCount;
    #};
    #endregion Function output
    
    #region Function output

    # Format data for presentation
    $BytesCopied = [math]::Round(($BytesCopied/1073741824),2)
    $BytesTotal = [math]::Round(($BytesTotal/1073741824),2)


    # Display summary
    Clear-Host
    if ($Percentage -gt 1) {
        Write-Host "Done copying!"
        Write-Host
        Write-Host "Summary:"
        Write-Host "Number of files:" $CopiedFileCount "of" $TotalFileCount
        Write-Host "Gigabytes of data:" $BytesCopied "of" $BytesTotal
  
    } else {
        Write-Host "All files are most likely already at the destination, please check the log for details"
    }
    Write-Host
    Write-Host "Check the log at ... for further details"
    #endregion Function output
}
 
#Functions end


#End of script
[void]$CopyTool.ShowDialog()