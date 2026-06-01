# SMTP Tester GUI - Authentication + TLS
# SPDX-License-Identifier: MIT
# Run: powershell -STA -ExecutionPolicy Bypass -File .\smtptest.ps1
# Or double-click smtptest.cmd
#
# Optional preset file (same folder as script): smtptest.config.json
# Copy smtptest.config.json.example to smtptest.config.json and edit.

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'smtptest.config.json')
)

$versionFile = Join-Path $PSScriptRoot 'VERSION'
if (Test-Path -LiteralPath $versionFile) {
    $AppVersion = (Get-Content -LiteralPath $versionFile -Raw).Trim()
}
if ([string]::IsNullOrWhiteSpace($AppVersion)) {
    $AppVersion = '0.0.0'  # CalVer: YYYY.M.D — see VERSION and README.md
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "SMTP Tester v$AppVersion"
$form.Size = New-Object System.Drawing.Size(640, 770)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

$y = 20
$labelWidth = 120
$inputWidth = 440

function Add-LabelTextBox {
    param(
        [string]$LabelText,
        [string]$DefaultValue = "",
        [int]$Height = 20
    )

    $script:y += 35

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20, ($script:y - 35))
    $label.Size = New-Object System.Drawing.Size($labelWidth, 20)
    $label.Text = $LabelText
    $form.Controls.Add($label)

    $textbox = New-Object System.Windows.Forms.TextBox
    $textbox.Location = New-Object System.Drawing.Point(150, ($script:y - 35))
    $textbox.Size = New-Object System.Drawing.Size($inputWidth, $Height)
    $textbox.Text = $DefaultValue
    $form.Controls.Add($textbox)

    return $textbox
}

$txtServer  = Add-LabelTextBox "SMTP Server:" "smtp.office365.com"
$txtPort    = Add-LabelTextBox "Port:" "587"
$portRowY   = $y - 35

$lblCommonPorts = New-Object System.Windows.Forms.Label
$lblCommonPorts.Location = New-Object System.Drawing.Point(150, ($portRowY + 24))
$lblCommonPorts.AutoSize = $true
$lblCommonPorts.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 8)
$lblCommonPorts.ForeColor = [System.Drawing.Color]::Gray
$lblCommonPorts.Text = "Common ports (click):"
$form.Controls.Add($lblCommonPorts)

$toolTip = New-Object System.Windows.Forms.ToolTip

$commonPorts = @(
    @{ Port = 25;   Text = "25";   Hint = "25 - SMTP (plain; often blocked outbound)"; Tls = $false },
    @{ Port = 587;  Text = "587";  Hint = "587 - Submission with STARTTLS (most providers)"; Tls = $true },
    @{ Port = 465;  Text = "465";  Hint = "465 - SMTPS (implicit SSL/TLS)"; Tls = $true }
)

$portLinks = @()
$linkX = 150
$linksY = $portRowY + 42
foreach ($entry in $commonPorts) {
    $link = New-Object System.Windows.Forms.LinkLabel
    $link.Location = New-Object System.Drawing.Point($linkX, $linksY)
    $link.AutoSize = $true
    $link.Text = $entry.Text
    $link.LinkColor = [System.Drawing.Color]::SteelBlue
    $link.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 9)
    $link.Tag = @{ Port = $entry.Port; Tls = $entry.Tls }
    $toolTip.SetToolTip($link, $entry.Hint)
    $form.Controls.Add($link)
    $portLinks += $link
    $linkX += $link.PreferredWidth + 20
}

$lblPortLegend = New-Object System.Windows.Forms.Label
$lblPortLegend.Location = New-Object System.Drawing.Point(150, ($portRowY + 62))
$lblPortLegend.Size = New-Object System.Drawing.Size($inputWidth, 28)
$lblPortLegend.Font = New-Object System.Drawing.Font($form.Font.FontFamily, 8)
$lblPortLegend.ForeColor = [System.Drawing.Color]::Gray
$lblPortLegend.Text = "25 = SMTP  |  587 = STARTTLS  |  465 = SSL"
$form.Controls.Add($lblPortLegend)

$y = $portRowY + 98

$txtFrom    = Add-LabelTextBox "From Email:" "user@contoso.com"
$txtTo      = Add-LabelTextBox "To Email:" "recipient@contoso.com"
$txtUser    = Add-LabelTextBox "Username:" "user@contoso.com"
$txtSubject = Add-LabelTextBox "Subject:" "SMTP Test"

$lblBody = New-Object System.Windows.Forms.Label
$lblBody.Location = New-Object System.Drawing.Point(20, $y)
$lblBody.Size = New-Object System.Drawing.Size($labelWidth, 20)
$lblBody.Text = "Body:"
$form.Controls.Add($lblBody)

$txtBody = New-Object System.Windows.Forms.TextBox
$txtBody.Location = New-Object System.Drawing.Point(150, $y)
$txtBody.Size = New-Object System.Drawing.Size($inputWidth, 60)
$txtBody.Multiline = $true
$txtBody.ScrollBars = "Vertical"
$txtBody.Text = "This is a test email sent from the SMTP Tester GUI."
$form.Controls.Add($txtBody)
$y += 75

$lblPass = New-Object System.Windows.Forms.Label
$lblPass.Location = New-Object System.Drawing.Point(20, $y)
$lblPass.Size = New-Object System.Drawing.Size($labelWidth, 20)
$lblPass.Text = "Password:"
$form.Controls.Add($lblPass)

$txtPassword = New-Object System.Windows.Forms.MaskedTextBox
$txtPassword.Location = New-Object System.Drawing.Point(150, $y)
$txtPassword.Size = New-Object System.Drawing.Size($inputWidth, 20)
$txtPassword.PasswordChar = '*'
$form.Controls.Add($txtPassword)
$y += 35

$chkTLS = New-Object System.Windows.Forms.CheckBox
$chkTLS.Location = New-Object System.Drawing.Point(150, $y)
$chkTLS.Size = New-Object System.Drawing.Size($inputWidth, 24)
$chkTLS.AutoSize = $false
$chkTLS.Text = "Use TLS/SSL (STARTTLS on 587, implicit SSL on 465)"
$chkTLS.Checked = $true
$form.Controls.Add($chkTLS)

foreach ($link in $portLinks) {
    $portNum = $link.Tag.Port
    $useTls = $link.Tag.Tls
    $link.Add_Click({
        $txtPort.Text = "$portNum"
        $chkTLS.Checked = $useTls
    }.GetNewClosure())
}

$y += 28

$chkAuth = New-Object System.Windows.Forms.CheckBox
$chkAuth.Location = New-Object System.Drawing.Point(150, $y)
$chkAuth.Size = New-Object System.Drawing.Size($inputWidth, 24)
$chkAuth.AutoSize = $false
$chkAuth.Text = "Use authentication"
$chkAuth.Checked = $true
$form.Controls.Add($chkAuth)
$y += 36

$lblLog = New-Object System.Windows.Forms.Label
$lblLog.Location = New-Object System.Drawing.Point(20, $y)
$lblLog.Text = "Log:"
$form.Controls.Add($lblLog)
$y += 22

$txtLog = New-Object System.Windows.Forms.TextBox
$txtLog.Location = New-Object System.Drawing.Point(20, $y)
$txtLog.Size = New-Object System.Drawing.Size(590, 200)
$txtLog.Multiline = $true
$txtLog.ReadOnly = $true
$txtLog.ScrollBars = "Vertical"
$txtLog.Font = New-Object System.Drawing.Font("Consolas", 9)
$form.Controls.Add($txtLog)
$y += 210

$btnTestTcp = New-Object System.Windows.Forms.Button
$btnTestTcp.Location = New-Object System.Drawing.Point(20, $y)
$btnTestTcp.Size = New-Object System.Drawing.Size(130, 32)
$btnTestTcp.Text = "Test TCP Port"
$form.Controls.Add($btnTestTcp)

$btnSend = New-Object System.Windows.Forms.Button
$btnSend.Location = New-Object System.Drawing.Point(160, $y)
$btnSend.Size = New-Object System.Drawing.Size(140, 32)
$btnSend.Text = "Send Test Email"
$form.Controls.Add($btnSend)

$btnClear = New-Object System.Windows.Forms.Button
$btnClear.Location = New-Object System.Drawing.Point(310, $y)
$btnClear.Size = New-Object System.Drawing.Size(90, 32)
$btnClear.Text = "Clear Log"
$form.Controls.Add($btnClear)

$btnSaveConfig = New-Object System.Windows.Forms.Button
$btnSaveConfig.Location = New-Object System.Drawing.Point(410, $y)
$btnSaveConfig.Size = New-Object System.Drawing.Size(100, 32)
$btnSaveConfig.Text = "Save Config"
$form.Controls.Add($btnSaveConfig)

$btnReloadConfig = New-Object System.Windows.Forms.Button
$btnReloadConfig.Location = New-Object System.Drawing.Point(520, $y)
$btnReloadConfig.Size = New-Object System.Drawing.Size(90, 32)
$btnReloadConfig.Text = "Reload"
$form.Controls.Add($btnReloadConfig)

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $txtLog.AppendText("[$timestamp] $Message`r`n")
    $txtLog.SelectionStart = $txtLog.Text.Length
    $txtLog.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

function Get-SmtpSettings {
    $server = $txtServer.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($server)) {
        throw "SMTP server is required."
    }

    if (-not [int]::TryParse($txtPort.Text.Trim(), [ref]$null)) {
        throw "Port must be a number."
    }
    $port = [int]$txtPort.Text.Trim()
    if ($port -lt 1 -or $port -gt 65535) {
        throw "Port must be between 1 and 65535."
    }

    foreach ($field in @(
            @{ Name = "From"; Value = $txtFrom.Text.Trim() },
            @{ Name = "To"; Value = $txtTo.Text.Trim() }
        )) {
        if ([string]::IsNullOrWhiteSpace($field.Value)) {
            throw "$($field.Name) email is required."
        }
        try {
            $null = [System.Net.Mail.MailAddress]::new($field.Value)
        }
        catch {
            throw "$($field.Name) email address is invalid: $($field.Value)"
        }
    }

    if ($chkAuth.Checked -and [string]::IsNullOrWhiteSpace($txtUser.Text.Trim())) {
        throw "Username is required when authentication is enabled."
    }

    if ($chkAuth.Checked -and [string]::IsNullOrWhiteSpace($txtPassword.Text)) {
        throw "Password is required when authentication is enabled."
    }

    [pscustomobject]@{
        Server   = $server
        Port     = $port
        From     = $txtFrom.Text.Trim()
        To       = $txtTo.Text.Trim()
        User     = $txtUser.Text.Trim()
        Password = $txtPassword.Text
        Subject  = $txtSubject.Text.Trim()
        Body     = $txtBody.Text
        UseTls   = $chkTLS.Checked
        UseAuth  = $chkAuth.Checked
    }
}

function New-SmtpClientFromSettings {
    param($Settings)

    $smtp = New-Object System.Net.Mail.SmtpClient($Settings.Server, $Settings.Port)
    $smtp.Timeout = 30000
    $smtp.EnableSsl = $Settings.UseTls

    if ($Settings.UseAuth) {
        $smtp.UseDefaultCredentials = $false
        $smtp.Credentials = New-Object System.Net.NetworkCredential(
            $Settings.User,
            $Settings.Password
        )
    }
    else {
        $smtp.UseDefaultCredentials = $true
    }

    return $smtp
}

function Set-UiBusy {
    param([bool]$Busy)
    $btnSend.Enabled = -not $Busy
    $btnTestTcp.Enabled = -not $Busy
    $btnSaveConfig.Enabled = -not $Busy
    $btnReloadConfig.Enabled = -not $Busy
    $form.Cursor = if ($Busy) { [System.Windows.Forms.Cursors]::WaitCursor } else { [System.Windows.Forms.Cursors]::Default }
}

function Get-UiConfig {
    [pscustomobject]@{
        SmtpServer = $txtServer.Text
        Port       = $txtPort.Text
        From       = $txtFrom.Text
        To         = $txtTo.Text
        Username   = $txtUser.Text
        Password   = $txtPassword.Text
        Subject    = $txtSubject.Text
        Body       = $txtBody.Text
        UseTls     = $chkTLS.Checked
        UseAuth    = $chkAuth.Checked
    }
}

function Set-UiFromConfig {
    param($Config)

    if ($null -eq $Config) { return }

    foreach ($pair in @(
            @{ Key = 'SmtpServer'; Control = $txtServer },
            @{ Key = 'Port'; Control = $txtPort },
            @{ Key = 'From'; Control = $txtFrom },
            @{ Key = 'To'; Control = $txtTo },
            @{ Key = 'Username'; Control = $txtUser },
            @{ Key = 'Subject'; Control = $txtSubject },
            @{ Key = 'Body'; Control = $txtBody }
        )) {
        if ($Config.PSObject.Properties.Name -contains $pair.Key) {
            $value = $Config.($pair.Key)
            if ($null -ne $value) {
                $pair.Control.Text = [string]$value
            }
        }
    }

    if ($Config.PSObject.Properties.Name -contains 'Password') {
        $txtPassword.Text = [string]$Config.Password
    }
    if ($Config.PSObject.Properties.Name -contains 'UseTls') {
        $chkTLS.Checked = ConvertTo-ConfigBool $Config.UseTls
    }
    if ($Config.PSObject.Properties.Name -contains 'UseAuth') {
        $chkAuth.Checked = ConvertTo-ConfigBool $Config.UseAuth
    }
}

function ConvertTo-ConfigBool {
    param($Value)

    if ($Value -is [bool]) { return $Value }
    if ($null -eq $Value) { return $false }

    $text = [string]$Value
    switch ($text.Trim().ToLowerInvariant()) {
        { $_ -in @('true', '1', 'yes', 'on') } { return $true }
        { $_ -in @('false', '0', 'no', 'off') } { return $false }
    }

    return [bool]$Value
}

function Export-SmtpConfig {
    param([string]$Path)

    $config = Get-UiConfig
    $json = $config | ConvertTo-Json -Depth 3
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.UTF8Encoding]::new($false))
}

function Import-SmtpConfig {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Config file not found: $Path"
    }

    $json = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($json)) {
        throw "Config file is empty: $Path"
    }

    $config = $json | ConvertFrom-Json
    Set-UiFromConfig $config
}

$btnTestTcp.Add_Click({
    $txtLog.Clear()
    Write-Log "Testing TCP connection..."

    try {
        Set-UiBusy $true
        $settings = Get-SmtpSettings

        $client = New-Object System.Net.Sockets.TcpClient
        $connect = $client.BeginConnect($settings.Server, $settings.Port, $null, $null)
        $ok = $connect.AsyncWaitHandle.WaitOne(5000, $false)
        if (-not $ok) {
            throw "Timed out connecting to $($settings.Server):$($settings.Port) (5s)."
        }
        $client.EndConnect($connect)
        $client.Close()

        Write-Log "TCP OK - reached $($settings.Server):$($settings.Port)"
        Write-Log "Next: use Send Test Email to verify TLS and authentication."
    }
    catch {
        Write-Log "TCP FAILED: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "TCP connection failed:`n`n$($_.Exception.Message)",
            "Connection Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        Set-UiBusy $false
    }
})

$btnSend.Add_Click({
    $txtLog.Clear()
    Write-Log "Sending test email..."

    $smtp = $null
    $mail = $null

    try {
        Set-UiBusy $true
        $settings = Get-SmtpSettings

        $mail = New-Object System.Net.Mail.MailMessage
        $mail.From = [System.Net.Mail.MailAddress]::new($settings.From)
        $mail.To.Add($settings.To)
        $mail.Subject = if ([string]::IsNullOrWhiteSpace($settings.Subject)) {
            "SMTP Test"
        } else {
            $settings.Subject
        }
        $mail.Body = $settings.Body
        $mail.IsBodyHtml = $false

        $smtp = New-SmtpClientFromSettings $settings

        if ($settings.UseTls) {
            Write-Log "TLS/SSL enabled"
        }
        if ($settings.UseAuth) {
            Write-Log "Authentication enabled (user: $($settings.User))"
        }

        Write-Log "Connecting to $($settings.Server):$($settings.Port) ..."
        $smtp.Send($mail)

        Write-Log "SUCCESS - test email sent."
        [System.Windows.Forms.MessageBox]::Show(
            "Test email sent successfully.",
            "Success",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        $detail = $_.Exception.Message
        if ($_.Exception.InnerException) {
            $detail += " -> $($_.Exception.InnerException.Message)"
        }
        Write-Log "FAILED: $detail"
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to send email:`n`n$detail",
            "Send Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
    finally {
        if ($mail) { $mail.Dispose() }
        if ($smtp) { $smtp.Dispose() }
        Set-UiBusy $false
    }
})

$btnClear.Add_Click({ $txtLog.Clear() })

$btnSaveConfig.Add_Click({
    try {
        Export-SmtpConfig -Path $ConfigPath
        Write-Log "Saved config to $ConfigPath"
        [System.Windows.Forms.MessageBox]::Show(
            "Settings saved to:`n$ConfigPath",
            "Config Saved",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    }
    catch {
        Write-Log "Save config failed: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not save config:`n`n$($_.Exception.Message)",
            "Save Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$btnReloadConfig.Add_Click({
    try {
        Import-SmtpConfig -Path $ConfigPath
        Write-Log "Reloaded config from $ConfigPath"
    }
    catch {
        Write-Log "Reload config failed: $($_.Exception.Message)"
        [System.Windows.Forms.MessageBox]::Show(
            "Could not load config:`n`n$($_.Exception.Message)",
            "Load Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

if (Test-Path -LiteralPath $ConfigPath) {
    try {
        Import-SmtpConfig -Path $ConfigPath
        Write-Log "Loaded config from $ConfigPath"
    }
    catch {
        Write-Log "Config load failed: $($_.Exception.Message)"
    }
}
else {
    Write-Log "No config file at $ConfigPath (using defaults). Use Save Config to create one."
}

Write-Log "SMTP Tester v$AppVersion"
Write-Log "Ready. Typical: port 587 + TLS + auth (Office 365, Gmail relay, etc.)."
[void]$form.ShowDialog()
