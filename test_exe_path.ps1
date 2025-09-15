
Add-Type -AssemblyName System.Windows.Forms

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Installation Path"
$form.Size = New-Object System.Drawing.Size(500,150)
$form.StartPosition = "CenterScreen"

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Choose installation directory:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($label)

# TextBox (default path)
$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Size = New-Object System.Drawing.Size(350,20)
$textBox.Location = New-Object System.Drawing.Point(10,50)
$textBox.Text = "C:\Program Files\OutSystems\Platform Server"   # default path
$form.Controls.Add($textBox)

# Browse button
$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = "Browse..."
$browseButton.Location = New-Object System.Drawing.Point(370,48)
$browseButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.SelectedPath = $textBox.Text
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBox.Text = $dialog.SelectedPath
    }
})
$form.Controls.Add($browseButton)

# OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(200,80)
$okButton.Add_Click({ $form.Close() })
$form.Controls.Add($okButton)

# Show form
$form.ShowDialog() | Out-Null

# Final path selected by user
$dirPath = $textBox.Text
Write-Host "Using path: $dirPath"

if ($MyInvocation.MyCommand.CommandType -eq "ExternalScript")
{ # Powershell script
    $ScriptPath = Split-Path -Parent -Path $MyInvocation.MyCommand.Definition
}
else
{ # PS2EXE compiled script
    $ScriptPath = Split-Path -Parent -Path ([Environment]::GetCommandLineArgs()[0])
}

$installer = Join-Path $ScriptPath "outsysInstall.ps1"

# Call Script B with argument
& $installer -installPath $dirPath