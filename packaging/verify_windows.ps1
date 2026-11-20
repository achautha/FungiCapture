param(
    [Parameter(Mandatory)][string]$Installer,
    [Parameter(Mandatory)][string]$Evidence,
    [string]$Version = '0.0.1',
    [string]$ExpectedHash
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force $Evidence | Out-Null
$Installer = (Resolve-Path $Installer).Path
$Evidence = (Resolve-Path $Evidence).Path
Start-Transcript -Path "$Evidence\verification.log"
$install = Join-Path $env:LOCALAPPDATA 'Programs\FungiCapture'
$project = Join-Path $Evidence 'Research project with spaces'
$oldPath = $env:PATH
function Assert($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
    Write-Host "PASS: $Message"
}
function Install-App {
    $process = Start-Process $Installer -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', "/LOG=`"$Evidence\install.log`"" -Wait -PassThru
    Assert ($process.ExitCode -eq 0) "Installer exit code is zero (was $($process.ExitCode))"
}
try {
    $hash = (Get-FileHash $Installer -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($ExpectedHash) { Assert ($hash -eq $ExpectedHash.ToLowerInvariant()) 'Downloaded installer matches published SHA-256' }
    Assert (-not (Test-Path $install)) 'No previous FungiCapture installation'
    # Exercise the installer and executable with Python/uv absent from PATH.
    $env:PATH = "$env:SystemRoot\System32;$env:SystemRoot"
    Install-App
    $cli = Join-Path $install 'FungiCapture-cli.exe'
    Assert (Test-Path "$install\_internal\python313.dll") 'Installer supplies the Python runtime'
    Assert (Test-Path "$install\LICENSE") 'Project licence is installed'
    Assert (Test-Path "$install\BUILD-INFO.json") 'Build provenance is installed'
    Assert (@(Get-ChildItem "$install\_internal" -Directory | Where-Object Name -Match '^(torch|torchvision|ultralytics)(-|$)').Count -eq 0) 'No model runtime directories are bundled'
    $reported = & $cli --version
    Assert ($LASTEXITCODE -eq 0 -and "$reported" -eq "FungiCapture $Version") 'Installed executable reports the release version'
    $shortcut = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\FungiCapture\FungiCapture.lnk'
    Assert (Test-Path $shortcut) 'Start-menu shortcut exists'
    & $cli new $project --mode plate_batch --images "$install\sample_dataset\plates" --rows 2 --cols 3 --media SDA
    Assert ($LASTEXITCODE -eq 0) 'Frozen CLI creates a project'
    & $cli run $project --backend classical --workers 2 --no-auto-centre
    Assert ($LASTEXITCODE -eq 0) 'Frozen classical pipeline completes successfully'
    $features = @(Import-Csv "$project\vectors\all_colony_features.csv")
    Assert ($features.Count -eq 18) 'Feature table contains 18 synthetic observations'
    Assert (@($features.base_key | Sort-Object -Unique).Count -eq 18) 'Observation identities are unique'
    Assert (@(Get-ChildItem "$project\vectors\per_image_vectors" -Recurse -Filter '*_features.csv').Count -eq 18) 'All 18 per-colony CSVs are retained'
    Add-Type -AssemblyName System.Drawing
    foreach ($row in $features) {
        $mask = [Drawing.Bitmap]::new($row.mask_path)
        try {
            $area = 0
            for ($y = 0; $y -lt $mask.Height; $y++) {
                for ($x = 0; $x -lt $mask.Width; $x++) {
                    if ($mask.GetPixel($x, $y).R -gt 0) { $area++ }
                }
            }
            Assert ($area -gt 0 -and $area -eq [double]::Parse($row.area_px, [cultureinfo]::InvariantCulture)) "Exported area equals mask pixels for $($row.base_key)"
        } finally { $mask.Dispose() }
    }
    $scores = @(Import-Csv "$project\phenotypes\phenotypes_all_media.tsv" -Delimiter "`t")
    Assert ($scores.Count -eq 18) 'Phenotype table contains 18 observations'
    & $cli report $project --mode contact_sheet --output "$Evidence\contact-sheet.pdf"
    Assert ($LASTEXITCODE -eq 0 -and (Get-Item "$Evidence\contact-sheet.pdf").Length -gt 1000) 'Frozen CLI exports a nonempty PDF report'
    $gui = Start-Process "$install\FungiCapture.exe" -ArgumentList "`"$project`"" -PassThru
    try {
        $deadline = (Get-Date).AddSeconds(60)
        do {
            Start-Sleep -Seconds 1
            $gui.Refresh()
        } while (-not $gui.HasExited -and $gui.MainWindowHandle -eq 0 -and (Get-Date) -lt $deadline)
        Assert (-not $gui.HasExited -and $gui.MainWindowHandle -ne 0) 'Installed GUI opens a native window'
        Start-Sleep -Seconds 3
        Add-Type -AssemblyName System.Windows.Forms
        $screen = [Windows.Forms.SystemInformation]::VirtualScreen
        $bitmap = [Drawing.Bitmap]::new($screen.Width, $screen.Height)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.CopyFromScreen($screen.Location, [Drawing.Point]::Empty, $screen.Size)
            $bitmap.Save("$Evidence\installed-gui.png")
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        Write-Host "GUI PID=$($gui.Id) title=$($gui.MainWindowTitle) responding=$($gui.Responding)"
        Write-Host "Close requested: $($gui.CloseMainWindow())"
        Assert ($gui.WaitForExit(20000)) 'Installed GUI closes normally'
    } finally {
        Copy-Item "$env:LOCALAPPDATA\fungicapture-startup.log" "$Evidence\startup-trace.log" -ErrorAction SilentlyContinue
        if (-not $gui.HasExited) { $gui.Kill() }
    }
    throw 'Diagnostic build only; do not publish'
    'Research data must survive reinstall and uninstall' | Set-Content "$project\KEEP.txt"
    Install-App
    Assert (Test-Path "$project\KEEP.txt") 'Reinstall preserves external research data'
    $uninstall = Start-Process "$install\unins000.exe" -ArgumentList '/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART' -Wait -PassThru
    Assert ($uninstall.ExitCode -eq 0) 'Silent uninstall completes'
    Assert (-not (Test-Path "$install\FungiCapture.exe")) 'Uninstall removes application executable'
    Assert (-not (Test-Path $shortcut)) 'Uninstall removes Start-menu shortcut'
    Assert (Test-Path "$project\KEEP.txt") 'Uninstall preserves external research data'
    @{ installer_sha256 = $hash; version = $Version; observations = 18; result = 'passed'; os = [Environment]::OSVersion.VersionString } |
        ConvertTo-Json | Set-Content "$Evidence\result.json"
} finally {
    $env:PATH = $oldPath
    Stop-Transcript
}
