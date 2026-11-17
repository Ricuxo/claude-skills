# Liga cada skill do repositório em %USERPROFILE%\.claude\skills por junction.
# Não exige administrador nem Modo de Desenvolvedor. O repo deve estar em disco local.
# Uso: powershell -ExecutionPolicy Bypass -File .\scripts\link.ps1

$repo   = Resolve-Path (Join-Path $PSScriptRoot "..\skills")
$target = Join-Path $env:USERPROFILE ".claude\skills"

New-Item -ItemType Directory -Force -Path $target | Out-Null

Get-ChildItem -Directory $repo | ForEach-Object {
    $link = Join-Path $target $_.Name
    if (Test-Path $link) {
        $item = Get-Item $link -Force
        if ($item.LinkType) { Write-Host "já ligado: $($_.Name)" }
        else { Write-Warning "$link existe e não é link — remova ou renomeie e rode de novo" }
        return
    }
    New-Item -ItemType Junction -Path $link -Target $_.FullName | Out-Null
    Write-Host "ligado: $($_.Name)"
}
