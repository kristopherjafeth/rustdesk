param([string]$Destino)
$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$rel = Invoke-RestMethod -UseBasicParsing -Headers @{ 'User-Agent' = 'JimkaSoporte' } `
    -Uri 'https://api.github.com/repos/rustdesk/rustdesk/releases/latest'
$asset = $rel.assets | Where-Object { $_.name -match '^rustdesk-[\d\.]+-x86_64\.exe$' } | Select-Object -First 1
if (-not $asset) { throw 'No se encontro el ejecutable de RustDesk en la ultima version.' }
Invoke-WebRequest -UseBasicParsing -Uri $asset.browser_download_url -OutFile $Destino
Write-Output "Descargado $($asset.name)"
