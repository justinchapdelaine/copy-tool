# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

<# This form was created using POSHGUI.com  a free online gui designer for PowerShell
.NAME
    Untitled
#>

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$staplesmigrationtool            = New-Object system.Windows.Forms.Form
$staplesmigrationtool.ClientSize  = '600,200'
$staplesmigrationtool.text       = "Staples Migration Tool"
$staplesmigrationtool.TopMost    = $false
$staplesmigrationtool.icon       = "img\staples-icon.ico"

$TextBox1                        = New-Object system.Windows.Forms.TextBox
$TextBox1.multiline              = $false
$TextBox1.width                  = 400
$TextBox1.height                 = 20
$TextBox1.location               = New-Object System.Drawing.Point(25,35)
$TextBox1.Font                   = 'Microsoft Sans Serif,10'

$TextBox2                        = New-Object system.Windows.Forms.TextBox
$TextBox2.multiline              = $false
$TextBox2.width                  = 400
$TextBox2.height                 = 20
$TextBox2.location               = New-Object System.Drawing.Point(25,95)
$TextBox2.Font                   = 'Microsoft Sans Serif,10'

$browse                          = New-Object system.Windows.Forms.Button
$browse.text                     = "Browse"
$browse.width                    = 60
$browse.height                   = 30
$browse.location                 = New-Object System.Drawing.Point(440,32)
$browse.Font                     = 'Microsoft Sans Serif,10'

$brow                            = New-Object system.Windows.Forms.Button
$brow.text                       = "Browse"
$brow.width                      = 60
$brow.height                     = 30
$brow.location                   = New-Object System.Drawing.Point(440,92)
$brow.Font                       = 'Microsoft Sans Serif,10'

$cancel                          = New-Object system.Windows.Forms.Button
$cancel.text                     = "Cancel"
$cancel.width                    = 60
$cancel.height                   = 30
$cancel.location                 = New-Object System.Drawing.Point(440,150)
$cancel.Font                     = 'Microsoft Sans Serif,10'

$source                          = New-Object system.Windows.Forms.Label
$source.text                     = "Source"
$source.AutoSize                 = $true
$source.width                    = 25
$source.height                   = 10
$source.location                 = New-Object System.Drawing.Point(25,15)
$source.Font                     = 'Microsoft Sans Serif,10,style=Bold'

$destination                     = New-Object system.Windows.Forms.Label
$destination.text                = "Destination"
$destination.AutoSize            = $true
$destination.width               = 25
$destination.height              = 10
$destination.location            = New-Object System.Drawing.Point(25,75)
$destination.Font                = 'Microsoft Sans Serif,10,style=Bold'

$start                           = New-Object system.Windows.Forms.Button
$start.text                      = "Start"
$start.width                     = 60
$start.height                    = 30
$start.location                  = New-Object System.Drawing.Point(520,150)
$start.Font                      = 'Microsoft Sans Serif,10'

$staplesmigrationtool.controls.AddRange(@($TextBox1,$TextBox2,$browse,$brow,$cancel,$source,$destination,$start))

#################################################################################################################

$browse.Add_Click({
    $folder = New-Object System.Windows.Forms.FolderBrowserDialog
	$folder.ShowDialog()
	$TextBox1.Text = $folder.SelectedPath
})

$brow.Add_Click({
    $folder = New-Object System.Windows.Forms.FolderBrowserDialog
	$folder.ShowDialog()
	$TextBox2.Text = $folder.SelectedPath
})

$cancel.Add_Click({
    $staplesmigrationtool.Close()
})

$start.Add_Click({
    $sourceSize = "{0:N2}" -f ((Get-ChildItem -path $TextBox1.Text -recurse | Measure-Object -property length -sum ).sum /1MB) + " MB"
    Write-Host $sourceSize
    
    $s = $TextBox1.Text    $d = $TextBox2.Text    $f = Split-Path (Split-Path $s -Leaf) -Leaf    Write-Host Source: $s    Write-Host Destination: $d    Write-Host Folder: $f    Start-Process PowerShell -Verb RunAs "-Command robocopy $s $d\$f /e /xj /eta /r:1 /w:0 /zb /efsraw /log:$d\CopyLog-$f.txt /np /tee; pause;"})


$staplesmigrationtool.ShowDialog() | Out-Null


