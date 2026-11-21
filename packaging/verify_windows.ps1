param(
    [Parameter(Mandatory)][string]$Installer,
    [Parameter(Mandatory)][string]$PreviousInstaller,
    [Parameter(Mandatory)][string]$Evidence
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Evidence = (Resolve-Path $Evidence).Path
$Installer = (Resolve-Path $Installer).Path
$PreviousInstaller = (Resolve-Path $PreviousInstaller).Path
$install = Join-Path $env:LOCALAPPDATA 'Programs\FungiCapture'
$project = Join-Path $Evidence 'Research project with spaces'
$settings = 'HKCU:\Software\FungiCapture\FungiCapture'
$modelCache = Join-Path $env:LOCALAPPDATA 'FungiCapture\FungiCapture\Cache\models'
$oldPath = $env:PATH
Start-Transcript -Path "$Evidence\verification.log"
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    Write-Host "PASS: $Message"
}
function Install-App([string]$File, [string]$Label) {
    $process = Start-Process $File -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$Evidence\$Label-install.log`"" -Wait -PassThru
    Assert ($process.ExitCode -eq 0) "$Label installer exits successfully"
}
try {
    Assert (-not (Test-Path $install)) 'No existing application on test runner'
    Assert ((Get-FileHash $PreviousInstaller -Algorithm SHA256).Hash -eq '2F278E9F5AA3B4BE0B333E034D3A135956B231BA13DE8ED409C3EDE81B5B50EF') 'Previous installer matches the released 0.0.1 checksum'
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
    Install-App $PreviousInstaller 'previous'
    $cli = Join-Path $install 'FungiCapture-cli.exe'
    & $cli new $project --mode single_dish
    Assert ($LASTEXITCODE -eq 0) '0.0.1 creates the project to upgrade'
    'Preserve research data' | Set-Content "$project\KEEP.txt"
    $configBefore = (Get-FileHash "$project\fungicapture.toml").Hash
    New-Item -ItemType Directory -Force $settings | Out-Null
    New-ItemProperty -Path $settings -Name pilot_upgrade_sentinel -Value 'preserve' -Force | Out-Null
    New-Item -ItemType Directory -Force $modelCache | Out-Null
    'Preserve cached user data' | Set-Content "$modelCache\KEEP.txt"
    Install-App $Installer 'candidate'
    Assert ((Get-FileHash "$project\fungicapture.toml").Hash -eq $configBefore) 'Upgrade does not rewrite the project'
    Assert ((Get-ItemProperty $settings).pilot_upgrade_sentinel -eq 'preserve') 'Upgrade preserves preferences'
    Assert (Test-Path "$modelCache\KEEP.txt") 'Upgrade preserves external model cache'
    $entry = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*' | Where-Object DisplayName -eq FungiCapture
    Assert (@($entry).Count -eq 1 -and $entry.DisplayVersion -eq '0.1.0rc1') 'One installed-app entry reports the new version'
    Assert (Test-Path "$install\_internal\python312.dll") 'Installer supplies Python without Python on PATH'
    Assert (Test-Path "$install\_internal\fungicapture\resources\bpe_simple_vocab_16e6.txt.gz") 'SAM tokenizer is installed'
    Assert (Test-Path "$install\_internal\torch\lib\torch_cpu.dll") 'CPU torch DLL is installed'
    Assert (Test-Path "$install\LICENSE") 'Project licence is installed'
    $reported = & $cli --version
    Assert ($LASTEXITCODE -eq 0 -and "$reported" -eq 'FungiCapture 0.1.0rc1') 'Frozen console executable reports the release version'
    Add-Type -AssemblyName System.Drawing
    $crop = [Drawing.Bitmap]::new(80, 60)
    $graphics = [Drawing.Graphics]::FromImage($crop)
    $brush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(80, 45, 15))
    try {
        $graphics.Clear([Drawing.Color]::FromArgb(220, 220, 220))
        $graphics.FillRectangle($brush, 20, 15, 38, 27)
        $crop.Save("$project\crops\colony.png", [Drawing.Imaging.ImageFormat]::Png)
    } finally { $brush.Dispose(); $graphics.Dispose(); $crop.Dispose() }
    & $cli run $project --steps segment --backend classical --quiet
    Assert ($LASTEXITCODE -eq 0) 'Frozen Classical segmentation runs after upgrade'
    $mask = [Drawing.Bitmap]::new("$project\masks\colony_mask.png")
    try {
        $area = 0
        for ($y = 0; $y -lt $mask.Height; $y++) {
            for ($x = 0; $x -lt $mask.Width; $x++) {
                if ($mask.GetPixel($x, $y).R -gt 0) { $area++ }
            }
        }
        Assert ($area -eq (38 * 27)) 'Frozen segmentation returns the independently expected 1026 foreground pixels'
    } finally { $mask.Dispose() }
    @{ weights="$Evidence\missing-sam3.pt"; params=@{} } | ConvertTo-Json | Set-Content "$Evidence\request.json"
    $worker = Start-Process "$install\FungiCapture.exe" -ArgumentList '--sam-worker', "`"$Evidence\request.json`"", "`"$Evidence\result.json`"" -PassThru
    Assert ($worker.WaitForExit(60000)) 'Frozen SAM worker exits within a minute for missing weights'
    Assert ($worker.ExitCode -eq 1 -and (Get-Content "$Evidence\result.json" -Raw | ConvertFrom-Json).error -like '*weights not found*') 'Frozen SAM worker returns a structured missing-model error'
    $gui = Start-Process "$install\FungiCapture.exe" -ArgumentList "`"$project`"" -PassThru
    try {
        $deadline = (Get-Date).AddSeconds(60)
        do {
            Start-Sleep -Seconds 1
            $gui.Refresh()
        } while (-not $gui.HasExited -and $gui.MainWindowTitle -notlike '*Research project with spaces*' -and (Get-Date) -lt $deadline)
        Assert (-not $gui.HasExited -and $gui.MainWindowHandle -ne 0 -and $gui.MainWindowTitle -like '*Research project with spaces*' -and $gui.Responding) 'Installed GUI opens the existing project and responds'
        Start-Sleep -Seconds 3
        Add-Type -AssemblyName System.Windows.Forms
        $screen = [Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = [Drawing.Bitmap]::new($screen.Width, $screen.Height)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($screen.Location, [Drawing.Point]::Empty, $screen.Size)
            $bitmap.Save("$Evidence\installed-gui.png")
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        # Dismiss the optional first-run SAM notice before requesting closure.
        $shell = New-Object -ComObject WScript.Shell
        $null = $shell.AppActivate($gui.Id)
        [Windows.Forms.SendKeys]::SendWait('{ESC}')
        Start-Sleep -Seconds 1
        Assert (@(Get-Process -Name FungiCapture).Count -eq 1) 'GUI does not relaunch itself for environment checks'
        $null = $gui.CloseMainWindow()
        Assert ($gui.WaitForExit(20000) -and $gui.ExitCode -eq 0) 'Installed GUI closes normally'
    } finally { if (-not $gui.HasExited) { $gui.Kill() } }
    Install-App $Installer 'reinstall'
    Assert (Test-Path "$project\KEEP.txt") 'Reinstall preserves external research data'
    $uninstall = Start-Process "$install\unins000.exe" -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
    Assert ($uninstall.ExitCode -eq 0) 'Uninstall completes successfully'
    Assert (-not (Test-Path "$install\FungiCapture.exe")) 'Uninstall removes application executable'
    Assert (Test-Path "$project\KEEP.txt") 'Uninstall preserves external research data'
    Assert (Test-Path "$modelCache\KEEP.txt") 'Uninstall preserves external cached data'
    Assert ((Get-ItemProperty $settings).pilot_upgrade_sentinel -eq 'preserve') 'Uninstall preserves preferences'
    @{ version='0.1.0rc1'; result='passed'; installer_sha256=(Get-FileHash $Installer -Algorithm SHA256).Hash; sam_inference='not tested: no authorised weights'; os=[Environment]::OSVersion.VersionString } |
        ConvertTo-Json | Set-Content "$Evidence\verification-result.json"
} finally {
    $env:PATH = $oldPath
    Stop-Transcript
}
