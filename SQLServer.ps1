Add-Type -AssemblyName PresentationCore,PresentationFramework,WindowsBase

Add-Type -AssemblyName System.Windows.Forms

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript")
{ # Powershell script
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else
{ # PS2EXE compiled script
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

# Create Window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="SQL Server Installer" Height="200" Width="400"
        WindowStartupLocation="CenterScreen">
    <Grid Margin="12">

        <!-- Page 1: Password Entry -->
        <StackPanel Name="PagePassword">
            <TextBlock FontWeight="Bold">Enter SA Password:</TextBlock>
            <PasswordBox Name="PwdBox1" Margin="0,5,0,10"/>
            
            <TextBlock FontWeight="Bold">Confirm SA Password:</TextBlock>
            <PasswordBox Name="PwdBox2" Margin="0,5,0,5"/>
            <TextBlock Name="MsgBlock" Foreground="Red" FontWeight="Bold" Margin="0,0,0,5"/>
            <Button Name="InstallBtn" Content="Install" Width="100" HorizontalAlignment="Center"/>
        </StackPanel>

        <!-- Page 2: Progress -->
        <StackPanel Name="PageProgress" Visibility="Collapsed" VerticalAlignment="Center">
            <TextBlock Text="Installing SQL Server..." FontWeight="Bold" Margin="0,0,0,10"
                       HorizontalAlignment="Center"/>
            <ProgressBar Name="ProgBar" Height="20" IsIndeterminate="True" Margin="0,0,0,10"/>
            <TextBlock Name="ProgMsg" Text="Please wait..." HorizontalAlignment="Center"/>
        </StackPanel>

    </Grid>
</Window>
"@

# Load XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get controls
$pwdBox1  = $window.FindName("PwdBox1")
$pwdBox2  = $window.FindName("PwdBox2")
$btn      = $window.FindName("InstallBtn")
$msgBlock = $window.FindName("MsgBlock")
$PagePassword = $window.FindName("PagePassword")
$PageProgress = $window.FindName("PageProgress")
$progressBar = $window.FindName("ProgBar")

$deviceName = "$env:COMPUTERNAME"
$sqlSysAdmin = "$deviceName\Administrator"

# Build command dynamically

# Button click event
$btn.Add_Click({
    $pwd1 = $pwdBox1.Password
    $pwd2 = $pwdBox2.Password
    $configFile = "$ScriptPath\ConfigurationFile.ini"
    $arguments = @(
        "/Q"
        "/IACCEPTSQLSERVERLICENSETERMS" 
        "/ACTION=Install"
        "/SAPWD=$pwd1"
        "/CONFIGURATIONFILE=$configFile"
        "/SQLSYSADMINACCOUNTS=$sqlSysAdmin"
        )

    if ([string]::IsNullOrWhiteSpace($pwd1) -or [string]::IsNullOrWhiteSpace($pwd2)) {
        $msgBlock.Text = "Password cannot be empty!"
    }
    elseif ($pwd1 -ne $pwd2) {
        $msgBlock.Text = "Passwords do not match!"
    }
    else {
        $msgBlock.Foreground = "Green"
        $msgBlock.Text = "Passwords match. Starting installation..."
        $window.Dispatcher.Invoke([action]{}, "Render")
        

        $PagePassword.Visibility = "Collapsed"
        $PageProgress.Visibility = "Visible"
        $window.Dispatcher.Invoke([action]{}, "Render")

        #$process = Start-Process -FilePath "$ScriptPath\SQLServer2022-x64-ENU\SETUP.exe" -ArgumentList $arguments -WindowStyle Hidden -PassThru
         
        $proc = New-Object System.Diagnostics.Process
        $proc.StartInfo.FileName = "$ScriptPath\SQLServer2022-x64-ENU\SETUP.exe"
        $proc.StartInfo.Arguments = "$arguments"
        $proc.StartInfo.UseShellExecute = $false
        $proc.EnableRaisingEvents = $true
        $proc.StartInfo.CreateNoWindow = $true

        $proc.add_Exited({
            $exitCode = $proc.ExitCode

            [System.Windows.Application]::Current.Dispatcher.Invoke({
                if ($exitCode -eq 0) {
                    [System.Windows.MessageBox]::Show("SQL Setup completed successfully!", "Installation Complete")
                } else { 
                    [System.Windows.MessageBox]::Show("SQL Setup failed. Exit code: $($exitCode)`nSee log files in Setup Bootstrap\Log folder.", "Installation Error")
                }
                 #$window.Close()
            })
        })

        $proc.Start() | Out-Null
    }
})

$window.ShowDialog() | Out-Null
