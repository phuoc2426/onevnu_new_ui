param(
    [string]$DeviceId = ''
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$flutterArgs = @(
    'run',
    '--debug',
    '--dart-define=KTX_API_BASE_URL=https://testktx.sohatech.vn/api/'
)
if ($DeviceId -ne '') {
    $flutterArgs += @('-d', $DeviceId)
}

& flutter @flutterArgs
exit $LASTEXITCODE
