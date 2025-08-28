[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('DC', 'FE', 'LT')]
    [string]$OSRole,

    [Parameter()]
    [string]$OSDBAuth = 'Database Authentication',
    [string]$OSController,
    #[string]$OSOutgoingIp,  #!!!!!
    #[string]$OSPrivateKey,

    [string]$OSDBSAUser = 'MSSQLSERVER',
    [string]$OSDBSAPass = 'Qwer!234',

    [string]$OSDBCommonPass = 'Qwer!234',

    [string]$OSDBCatalog = 'outsystem',
    [string]$OSDBServer = 'EC2AMAZ-II9CHR0\MSSQLSERVER',
    [string]$OSDBAdminUser = 'OUTSYSADMIN_PLAT',
    [string]$OSDBRuntimeUser = 'OUTSYSRUNTIME_PLAT',

    [string]$OSDBLogCatalog = 'outsystem_logging',
    [string]$OSDBLogServer = 'EC2AMAZ-II9CHR0\MSSQLSERVER',
    [string]$OSDBLogAdminUser = 'OUTSYSADMIN_LOG',
    [string]$OSDBLogRuntimeUser = 'OUTSYSRUNTIME_LOG',

    [string]$OSDBSessionServer = 'EC2AMAZ-II9CHR0\MSSQLSERVER',
    [string]$OSDBSessionUser = 'OUTSYSSESSION',
    [string]$OSDBSessionCatalog = 'ASPStateOS',

    [string]$OSRabbitMQHost = 'EC2AMAZ-II9CHR0\MSSQLSERVER',
    [string]$OSRabbitMQUser = 'rabbitmq',
    [string]$OSRabbitMQPass = 'Qwer!234',
    [string]$OSRabbitMQVHost = '/outsystems'
    #[string]$OSInstallDir = 'E:\OutSystems',
    #[string]$OSServerVersion,
    #[string]$OSServiceStudioVersion
)

$ErrorActionPreference = 'Stop'
$OSDBSACred = New-Object System.Management.Automation.PSCredential ($OSDBSAUser, $(ConvertTo-SecureString $OSDBSAPass -AsPlainText -Force))

# Start PS Logging
Start-Transcript -Path "$Env:Windir\temp\PowerShellTranscript.log" -Append | Out-Null

# -- Start a new config
if ($OSPrivateKey)
{
    New-OSServerConfig -DatabaseProvider 'SQL' -PrivateKey $OSPrivateKey -ErrorAction Stop | Out-Null
}
else
{
    New-OSServerConfig -DatabaseProvider 'SQL' -ErrorAction Stop | Out-Null
}

# -- Configure common settings to both versions
# **** Platform Database ****
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'UsedAuthenticationMode' -Value $OSDBAuth -ErrorAction Stop | Out-Null #!!!
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'Server' -Value $OSDBServer -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'Catalog' -Value $OSDBCatalog -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'AdminUser' -Value $OSDBAdminUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'AdminPassword' -Value $OSDBCommonPass -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'RuntimeUser' -Value $OSDBRuntimeUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'PlatformDatabaseConfiguration' -Setting 'RuntimePassword' -Value $OSDBCommonPass -ErrorAction Stop | Out-Null
# **** Session Database ****
Set-OSServerConfig -SettingSection 'SessionDatabaseConfiguration' -Setting 'UsedAuthenticationMode' -Value $OSDBAuth -ErrorAction Stop | Out-Null #!!!
Set-OSServerConfig -SettingSection 'SessionDatabaseConfiguration' -Setting 'Server' -Value $OSDBSessionServer -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'SessionDatabaseConfiguration' -Setting 'Catalog' -Value $OSDBSessionCatalog -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'SessionDatabaseConfiguration' -Setting 'SessionUser' -Value $OSDBSessionUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'SessionDatabaseConfiguration' -Setting 'SessionPassword' -Value $OSDBCommonPass -ErrorAction Stop | Out-Null
# **** Service config ****
#Set-OSServerConfig -SettingSection 'ServiceConfiguration' -Setting 'CompilerServerHostname' -Value $OSController -ErrorAction Stop | Out-Null
# **** Other config ****
#Set-OSServerConfig -SettingSection 'OtherConfigurations' -Setting 'DBTimeout' -Value '60' -ErrorAction Stop | Out-Null

# -- Configure version specific platform settings
# **** Cache invalidation service config ****
Set-OSServerConfig -SettingSection 'CacheInvalidationConfiguration' -Setting 'ServiceHost' -Value $OSRabbitMQHost -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'CacheInvalidationConfiguration' -Setting 'ServiceUsername' -Value $OSRabbitMQUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'CacheInvalidationConfiguration' -Setting 'ServicePassword' -Value $OSRabbitMQPass -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'CacheInvalidationConfiguration' -Setting 'VirtualHost' -Value $OSRabbitMQVHost -ErrorAction Stop | Out-Null

# **** Logging database ****
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'UsedAuthenticationMode' -Value $OSDBAuth -ErrorAction Stop | Out-Null #!!!
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'Server' -Value $OSDBLogServer -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'Catalog' -Value $OSDBLogCatalog -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'AdminUser' -Value $OSDBLogAdminUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'AdminPassword' -Value $OSDBCommonPass -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'RuntimeUser' -Value $OSDBLogRuntimeUser -ErrorAction Stop | Out-Null
Set-OSServerConfig -SettingSection 'LoggingDatabaseConfiguration' -Setting 'RuntimePassword' -Value $OSDBCommonPass -ErrorAction Stop | Out-Null

# -- Apply the configuration
switch ($OSRole)
{
    {$_ -in 'DC','LT'}
    {
        Set-OSServerConfig -Apply -PlatformDBCredential $OSDBSACred -SessionDBCredential $OSDBSACred -LogDBCredential $OSDBSACred -ConfigureCacheInvalidationService -ErrorAction Stop | Out-Null
    }
    'FE'
    {
        Set-OSServerConfig -Apply -PlatformDBCredential $OSDBSACred -SessionDBCredential $OSDBSACred -LogDBCredential $OSDBSACred -ErrorAction Stop | Out-Null
    }
}
# -- Configure windows firewall with rabbit
Set-OSServerWindowsFirewall -IncludeRabbitMQ -ErrorAction Stop | Out-Null

# -- Outputs the private key
Get-OSServerPrivateKey

