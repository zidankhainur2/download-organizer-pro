Set-StrictMode -Version Latest

#region Assemblies

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms -ErrorAction SilentlyContinue

#endregion

#region Public Functions

<#
.SYNOPSIS
Launches the Download Organizer Pro Desktop Graphical User Interface (WPF).

.DESCRIPTION
Constructs and displays a native WPF desktop window providing folder selection, dry-run simulation, real-time watcher toggling, undo operations, configuration editing, live execution progress, and result DataGrid views.

.PARAMETER ConfigPath
Path to config.json file. Default is project root config.json.

.OUTPUTS
[System.Windows.Window]

.EXAMPLE
Show-OrganizerGUI
#>
function Show-OrganizerGUI {

    [CmdletBinding()]

    param(

        [string]$ConfigPath = ""

    )

    $projectRoot = Split-Path -Parent $PSScriptRoot

    if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
        $ConfigPath = Join-Path $projectRoot "config.json"
    }

    $config = Get-OrganizerConfig -Path $ConfigPath

    $xamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Download Organizer Pro v2.1" Height="720" Width="1050"
        WindowStartupLocation="CenterScreen" Background="#0F172A" Foreground="#F8FAFC"
        FontFamily="Segoe UI, sans-serif">
    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="120"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <DockPanel Grid.Row="0" Margin="0,0,0,16">
            <TextBlock Text="DOWNLOAD ORGANIZER PRO" FontSize="20" FontWeight="Bold" Foreground="#38BDF8" VerticalAlignment="Center"/>
            <TextBlock Text="v2.1.0 Desktop Edition" FontSize="12" Foreground="#94A3B8" VerticalAlignment="Center" HorizontalAlignment="Right"/>
        </DockPanel>

        <!-- Path Bar -->
        <Border Grid.Row="1" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Target Folder:" VerticalAlignment="Center" FontWeight="SemiBold" Margin="0,0,12,0" Foreground="#F8FAFC"/>
                <TextBox x:Name="TxtFolderPath" Grid.Column="1" Background="#0F172A" Foreground="#38BDF8" BorderBrush="#334155" Padding="6" FontSize="13" VerticalContentAlignment="Center"/>
                <Button x:Name="BtnBrowse" Grid.Column="2" Content="Browse..." Margin="8,0,0,0" Padding="12,6" Background="#334155" Foreground="#F8FAFC" BorderThickness="0" Cursor="Hand"/>
            </Grid>
        </Border>

        <!-- Options Panel -->
        <Border Grid.Row="2" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,0,12">
            <WrapPanel>
                <CheckBox x:Name="ChkSmartRules" Content="Enable Smart Rules" IsChecked="True" Foreground="#F8FAFC" Margin="0,0,24,0"/>
                <CheckBox x:Name="ChkDryRun" Content="Dry-Run Mode" Foreground="#F8FAFC" Margin="0,0,24,0"/>
                <CheckBox x:Name="ChkRecurse" Content="Recurse Subfolders" Foreground="#F8FAFC" Margin="0,0,24,0"/>
                <CheckBox x:Name="ChkExportHTML" Content="Export HTML Dashboard" IsChecked="True" Foreground="#F8FAFC" Margin="0,0,24,0"/>
                <CheckBox x:Name="ChkExportCSV" Content="Export CSV Report" Foreground="#F8FAFC" Margin="0,0,24,0"/>
            </WrapPanel>
        </Border>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,16">
            <Button x:Name="BtnStart" Content="  START ORGANIZING" Width="180" Height="38" Background="#0284C7" Foreground="#FFFFFF" FontWeight="Bold" BorderThickness="0" Margin="0,0,12,0" Cursor="Hand"/>
            <Button x:Name="BtnWatcher" Content=" START WATCHER" Width="160" Height="38" Background="#0369A1" Foreground="#FFFFFF" FontWeight="Bold" BorderThickness="0" Margin="0,0,12,0" Cursor="Hand"/>
            <Button x:Name="BtnUndo" Content=" UNDO LAST MOVE" Width="150" Height="38" Background="#334155" Foreground="#F8FAFC" FontWeight="SemiBold" BorderThickness="0" Margin="0,0,12,0" Cursor="Hand"/>
            <Button x:Name="BtnReportStats" Content=" STATS REPORT" Width="140" Height="38" Background="#334155" Foreground="#F8FAFC" FontWeight="SemiBold" BorderThickness="0" Cursor="Hand"/>
        </StackPanel>

        <!-- KPI Summary Cards -->
        <Grid Grid.Row="4" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,6,0">
                <StackPanel>
                    <TextBlock Text="SCANNED" FontSize="11" Foreground="#94A3B8" FontWeight="Bold"/>
                    <TextBlock x:Name="TxtKpiScanned" Text="0" FontSize="20" FontWeight="Bold" Foreground="#38BDF8" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="1" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="10" Margin="3,0,3,0">
                <StackPanel>
                    <TextBlock Text="MOVED" FontSize="11" Foreground="#94A3B8" FontWeight="Bold"/>
                    <TextBlock x:Name="TxtKpiMoved" Text="0" FontSize="20" FontWeight="Bold" Foreground="#22C55E" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="2" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="10" Margin="3,0,3,0">
                <StackPanel>
                    <TextBlock Text="FAILED" FontSize="11" Foreground="#94A3B8" FontWeight="Bold"/>
                    <TextBlock x:Name="TxtKpiFailed" Text="0" FontSize="20" FontWeight="Bold" Foreground="#EF4444" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="3" Background="#1E293B" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="10" Margin="6,0,0,0">
                <StackPanel>
                    <TextBlock Text="TOTAL SIZE" FontSize="11" Foreground="#94A3B8" FontWeight="Bold"/>
                    <TextBlock x:Name="TxtKpiSize" Text="0.00 MB" FontSize="20" FontWeight="Bold" Foreground="#F59E0B" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- Results DataGrid -->
        <DataGrid x:Name="GridResults" Grid.Row="5" AutoGenerateColumns="False" IsReadOnly="True" Background="#1E293B" RowBackground="#1E293B" AlternatingRowBackground="#0F172A" Foreground="#F8FAFC" BorderBrush="#334155" GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#334155" Margin="0,0,0,12">
            <DataGrid.Columns>
                <DataGridTextColumn Header="File Name" Binding="{Binding File}" Width="2*"/>
                <DataGridTextColumn Header="Category" Binding="{Binding Category}" Width="1.2*"/>
                <DataGridTextColumn Header="SubCategory" Binding="{Binding SubCategory}" Width="1.2*"/>
                <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="1*"/>
                <DataGridTextColumn Header="Destination" Binding="{Binding Destination}" Width="3*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Log Console -->
        <Border Grid.Row="6" Background="#090D16" BorderBrush="#334155" BorderThickness="1" CornerRadius="6" Padding="8">
            <TextBox x:Name="TxtLogConsole" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Background="Transparent" Foreground="#38BDF8" BorderThickness="0" FontFamily="Consolas, Courier New" FontSize="11" TextWrapping="Wrap"/>
        </Border>
    </Grid>
</Window>
"@

    $window = [Windows.Markup.XamlReader]::Parse($xamlString)

    # Controls Binding
    $txtFolderPath = $window.FindName("TxtFolderPath")
    $btnBrowse = $window.FindName("BtnBrowse")
    $btnStart = $window.FindName("BtnStart")
    $btnWatcher = $window.FindName("BtnWatcher")
    $btnUndo = $window.FindName("BtnUndo")
    $btnReportStats = $window.FindName("BtnReportStats")
    $chkSmartRules = $window.FindName("ChkSmartRules")
    $chkDryRun = $window.FindName("ChkDryRun")
    $chkRecurse = $window.FindName("ChkRecurse")
    $chkExportHTML = $window.FindName("ChkExportHTML")
    $chkExportCSV = $window.FindName("ChkExportCSV")
    $txtKpiScanned = $window.FindName("TxtKpiScanned")
    $txtKpiMoved = $window.FindName("TxtKpiMoved")
    $txtKpiFailed = $window.FindName("TxtKpiFailed")
    $txtKpiSize = $window.FindName("TxtKpiSize")
    $gridResults = $window.FindName("GridResults")
    $txtLogConsole = $window.FindName("TxtLogConsole")

    # Initial Values
    $txtFolderPath.Text = $config.Settings.DownloadsPath
    $txtLogConsole.Text = "[INFO] Download Organizer Pro v2.1 Desktop GUI Ready.`n"

    # Event Handlers
    $btnBrowse.Add_Click({
            $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
            $dialog.Description = "Select Downloads Target Folder"
            if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                $txtFolderPath.Text = $dialog.SelectedPath
            }
        })

    $btnStart.Add_Click({
            $targetFolder = $txtFolderPath.Text
            if (-not (Test-Path -LiteralPath $targetFolder)) {
                [System.Windows.MessageBox]::Show("Target folder does not exist: $targetFolder", "Error", "OK", "Error")
                return
            }

            $txtLogConsole.AppendText("[INFO] Scanning downloads folder: $targetFolder...`n")

            $files = Get-DownloadFiles `
                -Path $targetFolder `
                -Recurse:$chkRecurse.IsChecked `
                -IgnorePatterns $config.Settings.IgnorePatterns `
                -MinAgeDays ([int]$config.Settings.MinAgeDays) `
                -MaxAgeDays ([int]$config.Settings.MaxAgeDays) `
                -MinSizeBytes ([Int64]$config.Settings.MinSizeBytes) `
                -MaxSizeBytes ([Int64]$config.Settings.MaxSizeBytes)

            $txtKpiScanned.Text = $files.Count.ToString()

            if ($files.Count -eq 0) {
                $txtLogConsole.AppendText("[WARN] No files found matching criteria.`n")
                return
            }

            $classifiedFiles = Set-FileCategory -Files $files -Categories $config.Categories

            if ($chkSmartRules.IsChecked) {
                $classifiedFiles = Invoke-SmartClassification -Files $classifiedFiles -SmartRules $config.SmartRules
            }

            $moveResults = Move-OrganizerFiles `
                -Files $classifiedFiles `
                -BasePath $targetFolder `
                -DryRun:$chkDryRun.IsChecked `
                -TransactionPath (Join-Path $projectRoot "logs")

            $gridResults.ItemsSource = $moveResults

            $movedCount = @($moveResults | Where-Object { $_.Status -like "*Moved*" }).Count
            $failedCount = @($moveResults | Where-Object { $_.Status -eq "Failed" }).Count
            $totalBytes = 0
            foreach ($f in $files) { $totalBytes += $f.SizeBytes }
            $sizeMB = [Math]::Round($totalBytes / 1MB, 2)

            $txtKpiMoved.Text = $movedCount.ToString()
            $txtKpiFailed.Text = $failedCount.ToString()
            $txtKpiSize.Text = "$sizeMB MB"

            $txtLogConsole.AppendText("[SUCCESS] Completed: $movedCount moved, $failedCount failed.`n")

            # Export Reports
            $dateStamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
            $reportsDir = Join-Path $projectRoot "logs\reports"

            if ($chkExportHTML.IsChecked) {
                $summary = Get-OrganizerSummary -Files $classifiedFiles -Results $moveResults -StartTime (Get-Date) -EndTime (Get-Date)
                $htmlFile = Join-Path $reportsDir "report-$dateStamp.html"
                Export-OrganizerHTMLReport -Summary $summary -Results $moveResults -OutputPath $htmlFile | Out-Null
                $txtLogConsole.AppendText("[REPORT] HTML Dashboard: $htmlFile`n")
            }

            if ($chkExportCSV.IsChecked) {
                $csvFile = Join-Path $reportsDir "report-$dateStamp.csv"
                Export-OrganizerCSV -Results $moveResults -OutputPath $csvFile | Out-Null
                $txtLogConsole.AppendText("[REPORT] CSV File: $csvFile`n")
            }
        })

    $btnWatcher.Add_Click({
            $status = Get-OrganizerWatcherStatus
            if ($status.IsActive) {
                Stop-OrganizerWatcher | Out-Null
                $btnWatcher.Content = "⚡ START WATCHER"
                $btnWatcher.Background = "#0369A1"
                $txtLogConsole.AppendText("[INFO] Real-Time Folder Watcher Stopped.`n")
            }
            else {
                $targetFolder = $txtFolderPath.Text
                $scriptPath = Join-Path $projectRoot "DownloadOrganizer.ps1"
                Start-OrganizerWatcher -Path $targetFolder -ScriptPath $scriptPath -DebounceSeconds 2 | Out-Null
                $btnWatcher.Content = "⏹ STOP WATCHER"
                $btnWatcher.Background = "#DC2626"
                $txtLogConsole.AppendText("[INFO] Real-Time Folder Watcher Activated for: $targetFolder`n")
            }
        })

    $btnUndo.Add_Click({
            $logsDir = Join-Path $projectRoot "logs"
            $undoLogs = Get-UndoLog -LogPath $logsDir
            if ($undoLogs.Count -eq 0) {
                [System.Windows.MessageBox]::Show("No transaction manifest logs found for undo.", "Undo Info", "OK", "Information")
                return
            }
            $latest = $undoLogs[0].FullName
            $res = Invoke-UndoOperation -TransactionFile $latest
            $txtLogConsole.AppendText("[UNDO] Restored $($res.RestoredCount) file(s), $($res.FailedCount) failed.`n")
            [System.Windows.MessageBox]::Show("Undo completed!`nRestored: $($res.RestoredCount) file(s)", "Undo Complete", "OK", "Information")
        })

    $btnReportStats.Add_Click({
            $logsDir = Join-Path $projectRoot "logs"
            $stats = Get-OrganizerStatistics -LogPath $logsDir
            $msg = "HISTORICAL STATISTICS:`n`nTotal Executions Logged: $($stats.TotalExecutions)`nTotal Files Moved: $($stats.TotalMoved)`nTotal Operations Failed: $($stats.TotalFailed)"
            [System.Windows.MessageBox]::Show($msg, "Statistics Dashboard", "OK", "Information")
        })

    $window.ShowDialog() | Out-Null
    return $window

}

<#
.SYNOPSIS
Alias helper for Show-OrganizerGUI.
#>
function New-OrganizerWindow {

    [CmdletBinding()]

    param()

    return Show-OrganizerGUI

}

#endregion

Export-ModuleMember `
    -Function `
    Show-OrganizerGUI,
New-OrganizerWindow
New-OrganizerWindow
New-OrganizerWindow
