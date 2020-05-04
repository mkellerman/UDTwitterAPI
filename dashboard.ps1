Import-Module UniversalDashboard

Enable-UDLogging -Level Warning

$global:TwitterOAuthSettings = @{ ApiKey = $env:ApiKey; ApiSecret = $env:ApiSecret; AccessToken = $env:AccessToken; AccessTokenSecret = $env:AccessTokenSecret }
$global:DataPath = New-Item -Path './Data' -ItemType Directory -Force | Select-Object -Expand FullName

$UDPages = Get-ChildItem -Path './Pages/*.ps1' | ForEach-Object { . $_.FullName }
$UDTheme = Get-UDTheme -Name DefaultTight
$UDFooter = New-UDFooter -Links (New-UDLink -Text '@mkellerman (GitHub)' -Url 'https://github.com/mkellerman')

$Dashboard = New-UDDashboard -Title "PSTwitterAPI Dashboard" -Pages $UDPages -Theme $UDTheme -Footer $UDFooter
Start-UDDashboard -Dashboard $Dashboard -Port 10001 -Force