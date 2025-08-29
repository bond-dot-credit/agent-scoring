Param(
[string]$ServiceName = "giza_clickhouse",
[string]$Db = "giza",
[string]$User = $env:CH_USER,
[string]$Password = $env:CH_PASSWORD
)


$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = Resolve-Path "$here/.."
$migrations = Join-Path $root "migrations"


$files = @(
"0001_tables.sql",
"0002_views.sql",
"0003_access.sql"
)


foreach ($f in $files) {
$src = Join-Path $migrations $f
Write-Host "Applying $f ..."
docker cp $src "$ServiceName:/tmp/$f" | Out-Null
docker exec -e CLICKHOUSE_PASSWORD=$Password -it $ServiceName bash -lc "clickhouse-client -u $User -d $Db --queries-file=/tmp/$f"
}
Write-Host "Done."