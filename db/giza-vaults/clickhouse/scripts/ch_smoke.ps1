Param(
[string]$ServiceName = "giza_clickhouse",
[string]$Db = "giza",
[string]$User = $env:CH_USER,
[string]$Password = $env:CH_PASSWORD
)


docker exec -e CLICKHOUSE_PASSWORD=$Password -it $ServiceName bash -lc @"
clickhouse-client -u $User -d $Db -q """
SELECT database, name, engine
FROM system.tables
WHERE database = '$Db'
ORDER BY name;"""
"@