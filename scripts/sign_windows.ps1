# 对 Windows 可执行文件与安装包做代码签名。
#
# 用法（需要自己的代码签名证书，PFX 格式）：
#   .\scripts\sign_windows.ps1 -PfxPath D:\certs\echoloop.pfx -PfxPassword "******"
#
# 注意：自签名证书不能消除 SmartScreen 提示；正式分发请使用受信任 CA 的证书。

param(
    [Parameter(Mandatory = $true)][string]$PfxPath,
    [Parameter(Mandatory = $true)][string]$PfxPassword,
    [string]$DistDir = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($DistDir)) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $DistDir = Join-Path $scriptDir '..\dist'
}

$signTool = Get-ChildItem 'C:\Program Files (x86)\Windows Kits\10\bin' -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
    Where-Object { $_.Directory.Name -eq 'x64' } |
    Sort-Object FullName -Descending |
    Select-Object -First 1

if (-not $signTool) {
    throw 'signtool.exe not found. Install the Windows SDK first.'
}

$targets = @(
    (Join-Path $DistDir 'EchoLoop-Windows\echo_loop.exe'),
    (Join-Path $DistDir 'installer\EchoLoop-Windows-Setup-1.0.46.exe')
)

foreach ($target in $targets) {
    if (-not (Test-Path $target)) {
        Write-Warning "Skip missing file: $target"
        continue
    }
    & $signTool.FullName sign /f $PfxPath /p $PfxPassword /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 $target
    if ($LASTEXITCODE -ne 0) {
        throw "Signing failed: $target"
    }
    Write-Host "Signed: $target"
}
