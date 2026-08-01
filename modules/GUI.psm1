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

    $ProgressPreference = 'SilentlyContinue'

    $xamlString = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Download Organizer Pro - Order From Chaos" Height="780" Width="1180"
        WindowStartupLocation="CenterScreen" Background="#0c0b09" Foreground="#f5efe1"
        FontFamily="Segoe UI">
    <Window.Resources>
        <!-- Base Button Style -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="#131210" />
            <Setter Property="Foreground" Value="#f5efe1" />
            <Setter Property="BorderBrush" Value="#3d3830" />
            <Setter Property="BorderThickness" Value="1" />
            <Setter Property="Padding" Value="16,10" />
            <Setter Property="FontWeight" Value="SemiBold" />
            <Setter Property="FontSize" Value="12" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" />
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#211e18" />
                                <Setter Property="Foreground" Value="#ff5c1a" />
                                <Setter Property="BorderBrush" Value="#ff5c1a" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- Primary Button Style -->
        <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#ff5c1a" />
            <Setter Property="Foreground" Value="#0c0b09" />
            <Setter Property="BorderThickness" Value="0" />
            <Setter Property="FontWeight" Value="Bold" />
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#f5efe1" />
                    <Setter Property="Foreground" Value="#0c0b09" />
                </Trigger>
            </Style.Triggers>
        </Style>
        
        <!-- Checkbox Style -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#9a9385" />
            <Setter Property="FontFamily" Value="Segoe UI" />
            <Setter Property="FontSize" Value="12" />
            <Setter Property="Margin" Value="0,0,24,0" />
            <Setter Property="Cursor" Value="Hand" />
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <StackPanel Orientation="Horizontal" Background="Transparent">
                            <Border Width="16" Height="16" Background="#0c0b09" BorderBrush="#3d3830" BorderThickness="1">
                                <TextBlock x:Name="CheckMark" Text="v" Foreground="#c8ff3a" FontWeight="Bold" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Visibility="Collapsed" Margin="0,-2,0,0"/>
                            </Border>
                            <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center" />
                        </StackPanel>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="CheckMark" Property="Visibility" Value="Visible" />
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Foreground" Value="#f5efe1" />
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        
        <!-- DataGrid Styling -->
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="#131210" />
            <Setter Property="Foreground" Value="#f5efe1" />
            <Setter Property="RowBackground" Value="#131210" />
            <Setter Property="AlternatingRowBackground" Value="#0c0b09" />
            <Setter Property="BorderBrush" Value="#2d2922" />
            <Setter Property="GridLinesVisibility" Value="Horizontal" />
            <Setter Property="HorizontalGridLinesBrush" Value="#2d2922" />
            <Setter Property="HeadersVisibility" Value="Column" />
            <Setter Property="ColumnHeaderStyle">
                <Setter.Value>
                    <Style TargetType="DataGridColumnHeader">
                        <Setter Property="Background" Value="#1a1813" />
                        <Setter Property="Foreground" Value="#9a9385" />
                        <Setter Property="FontWeight" Value="SemiBold" />
                        <Setter Property="FontSize" Value="11" />
                        <Setter Property="FontFamily" Value="Cascadia Code, Consolas" />
                        <Setter Property="Padding" Value="12,8" />
                        <Setter Property="BorderBrush" Value="#2d2922" />
                        <Setter Property="BorderThickness" Value="0,0,1,1" />
                    </Style>
                </Setter.Value>
            </Setter>
            <Setter Property="CellStyle">
                <Setter.Value>
                    <Style TargetType="DataGridCell">
                        <Setter Property="BorderThickness" Value="0" />
                        <Setter Property="Padding" Value="12,8" />
                        <Setter Property="Template">
                            <Setter.Value>
                                <ControlTemplate TargetType="DataGridCell">
                                    <Border Background="Transparent" Padding="{TemplateBinding Padding}">
                                        <ContentPresenter VerticalAlignment="Center" />
                                    </Border>
                                </ControlTemplate>
                            </Setter.Value>
                        </Setter>
                        <Style.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Background" Value="#211e18" />
                                <Setter Property="Foreground" Value="#ff5c1a" />
                            </Trigger>
                        </Style.Triggers>
                    </Style>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="140"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Grid Grid.Row="0" Margin="0,0,0,24">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel Grid.Column="0" Orientation="Horizontal" VerticalAlignment="Center">
                <Border Background="#ff5c1a" Width="36" Height="36" Margin="0,0,16,0">
                    <TextBlock Text="DOP" Foreground="#0c0b09" FontWeight="Bold" FontFamily="Cascadia Code, Consolas" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Margin="0,-2,0,0"/>
                </Border>
                <TextBlock FontFamily="Bricolage Grotesque, Segoe UI" FontSize="22" FontWeight="Bold" Foreground="#f5efe1" VerticalAlignment="Center">
                    DOWNLOAD ORGANIZER <Run Foreground="#ff5c1a">PRO</Run>
                </TextBlock>
            </StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                <TextBlock Text="V2.1.0 DESKTOP" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385" HorizontalAlignment="Right"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,4,0,0">
                    <Ellipse Width="8" Height="8" Fill="#c8ff3a" Margin="0,0,8,0"/>
                    <TextBlock Text="SYSTEM OPERATIONAL" FontFamily="Cascadia Code, Consolas" FontSize="10" Foreground="#c8ff3a"/>
                </StackPanel>
            </StackPanel>
        </Grid>

        <!-- Path Bar -->
        <Border Grid.Row="1" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="0,0,0,16">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="TARGET FOLDER" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385" VerticalAlignment="Center" Margin="0,0,16,0"/>
                <TextBox x:Name="TxtFolderPath" Grid.Column="1" Background="#0c0b09" Foreground="#ff8a4d" BorderBrush="#2d2922" BorderThickness="1" Padding="8,6" FontSize="13" FontFamily="Cascadia Code, Consolas" VerticalContentAlignment="Center" CaretBrush="#ff5c1a"/>
                <Button x:Name="BtnBrowse" Grid.Column="2" Content="BROWSE" Margin="12,0,0,0" Width="100"/>
            </Grid>
        </Border>

        <!-- Options Panel -->
        <Border Grid.Row="2" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="0,0,0,16">
            <WrapPanel>
                <CheckBox x:Name="ChkSmartRules" Content="Enable Smart Rules" IsChecked="True"/>
                <CheckBox x:Name="ChkDryRun" Content="Dry-Run Mode"/>
                <CheckBox x:Name="ChkRecurse" Content="Recurse Subfolders"/>
                <CheckBox x:Name="ChkExportHTML" Content="Export HTML Dashboard" IsChecked="True"/>
                <CheckBox x:Name="ChkExportCSV" Content="Export CSV Report"/>
            </WrapPanel>
        </Border>

        <!-- Action Buttons -->
        <StackPanel Grid.Row="3" Orientation="Horizontal" Margin="0,0,0,24">
            <Button x:Name="BtnStart" Content="START ORGANIZING" Style="{StaticResource PrimaryButton}" Width="210" Height="44" Margin="0,0,12,0"/>
            <Button x:Name="BtnWatcher" Content="START WATCHER" Width="180" Height="44" Margin="0,0,12,0"/>
            <Button x:Name="BtnUndo" Content="UNDO LAST MOVE" Width="170" Height="44" Margin="0,0,12,0"/>
            <Button x:Name="BtnReportStats" Content="STATS REPORT" Width="160" Height="44"/>
        </StackPanel>

        <!-- KPI Summary Cards -->
        <Grid Grid.Row="4" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="0,0,6,0">
                <StackPanel>
                    <TextBlock Text="SCANNED" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385"/>
                    <TextBlock x:Name="TxtKpiScanned" Text="0" FontFamily="Bricolage Grotesque, Segoe UI" FontSize="28" FontWeight="Bold" Foreground="#f5efe1" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="1" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="6,0,6,0">
                <StackPanel>
                    <TextBlock Text="MOVED" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385"/>
                    <TextBlock x:Name="TxtKpiMoved" Text="0" FontFamily="Bricolage Grotesque, Segoe UI" FontSize="28" FontWeight="Bold" Foreground="#c8ff3a" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="2" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="6,0,6,0">
                <StackPanel>
                    <TextBlock Text="FAILED" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385"/>
                    <TextBlock x:Name="TxtKpiFailed" Text="0" FontFamily="Bricolage Grotesque, Segoe UI" FontSize="28" FontWeight="Bold" Foreground="#ff4444" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
            <Border Grid.Column="3" Background="#131210" BorderBrush="#2d2922" BorderThickness="1" Padding="16,12" Margin="6,0,0,0">
                <StackPanel>
                    <TextBlock Text="TOTAL SIZE" FontFamily="Cascadia Code, Consolas" FontSize="11" Foreground="#9a9385"/>
                    <TextBlock x:Name="TxtKpiSize" Text="0 MB" FontFamily="Bricolage Grotesque, Segoe UI" FontSize="28" FontWeight="Bold" Foreground="#ff8a4d" Margin="0,4,0,0"/>
                </StackPanel>
            </Border>
        </Grid>

        <!-- Results DataGrid -->
        <DataGrid x:Name="GridResults" Grid.Row="5" AutoGenerateColumns="False" IsReadOnly="True" Margin="0,0,0,16">
            <DataGrid.Columns>
                <DataGridTextColumn Header="FILE NAME" Binding="{Binding File}" Width="2*"/>
                <DataGridTextColumn Header="CATEGORY" Binding="{Binding Category}" Width="1.2*"/>
                <DataGridTextColumn Header="SUBCATEGORY" Binding="{Binding SubCategory}" Width="1.2*"/>
                <DataGridTextColumn Header="STATUS" Binding="{Binding Status}" Width="1*"/>
                <DataGridTextColumn Header="DESTINATION" Binding="{Binding Destination}" Width="3*"/>
            </DataGrid.Columns>
        </DataGrid>

        <!-- Log Console -->
        <Border Grid.Row="6" Background="#0a0908" BorderBrush="#2d2922" BorderThickness="1" Padding="12">
            <TextBox x:Name="TxtLogConsole" IsReadOnly="True" VerticalScrollBarVisibility="Auto" Background="Transparent" Foreground="#ff8a4d" BorderThickness="0" FontFamily="Cascadia Code, Consolas" FontSize="12" TextWrapping="Wrap" CaretBrush="#ff5c1a"/>
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
    $txtLogConsole.Text = "[INIT] Download Organizer Pro v2.1.0 Desktop Initialized.`n"
    $txtLogConsole.AppendText("[INIT] Configuration loaded successfully. Awaiting user input.`n")

    # Event Handlers
    $btnBrowse.Add_Click({
            try {
                $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
                $dialog.Description = "Select Downloads Target Folder"
                if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
                    $txtFolderPath.Text = $dialog.SelectedPath
                    $txtLogConsole.AppendText("[CONFIG] Target folder updated: $($dialog.SelectedPath)`n")
                }
            }
            catch {
                [System.Windows.MessageBox]::Show($_.Exception.Message, "Folder Browser Error", "OK", "Error")
            }
        })

    $btnStart.Add_Click({
            try {
                $ProgressPreference = 'SilentlyContinue'
                $targetFolder = $txtFolderPath.Text
                if (-not (Test-Path -LiteralPath $targetFolder)) {
                    [System.Windows.MessageBox]::Show("Target folder does not exist: $targetFolder", "Error", "OK", "Error")
                    return
                }

                $txtLogConsole.AppendText("[EXEC] Scanning target directory: $targetFolder...`n")

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

                $txtLogConsole.AppendText("[CLASSIFY] Applying extension rules and smart keywords...`n")
                $classifiedFiles = Set-FileCategory -Files $files -Categories $config.Categories

                if ($chkSmartRules.IsChecked) {
                    $classifiedFiles = Invoke-SmartClassification -Files $classifiedFiles -SmartRules $config.SmartRules
                }

                $moveResults = Move-OrganizerFiles `
                    -Files $classifiedFiles `
                    -BasePath $targetFolder `
                    -DryRun:$chkDryRun.IsChecked `
                    -TransactionPath (Join-Path $projectRoot "logs")

                if ($moveResults.Count -gt 500) {
                    $gridResults.ItemsSource = $moveResults | Select-Object -First 500
                    $txtLogConsole.AppendText("[WARN] UI limited to first 500 items to prevent freezing.`n")
                }
                else {
                    $gridResults.ItemsSource = $moveResults
                }

                $movedCount = @($moveResults | Where-Object { $_.Status -like "*Moved*" }).Count
                $failedCount = @($moveResults | Where-Object { $_.Status -eq "Failed" }).Count
                $totalBytes = 0
                foreach ($f in $files) { $totalBytes += $f.SizeBytes }
                $sizeMB = [Math]::Round($totalBytes / 1MB, 2)

                $txtKpiMoved.Text = $movedCount.ToString()
                $txtKpiFailed.Text = $failedCount.ToString()
                $txtKpiSize.Text = "$sizeMB MB"

                $txtLogConsole.AppendText("[SUCCESS] Pipeline completed: $movedCount moved, $failedCount failed.`n")

                # Export Reports
                $dateStamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
                $reportsDir = Join-Path $projectRoot "logs\reports"

                if ($chkExportHTML.IsChecked) {
                    $summary = Get-OrganizerSummary -Files $classifiedFiles -Results $moveResults -StartTime (Get-Date) -EndTime (Get-Date)
                    $htmlFile = Join-Path $reportsDir "report-$dateStamp.html"
                    Export-OrganizerHTMLReport -Summary $summary -Results $moveResults -OutputPath $htmlFile | Out-Null
                    $txtLogConsole.AppendText("[REPORT] HTML Dashboard generated: $htmlFile`n")
                }

                if ($chkExportCSV.IsChecked) {
                    $csvFile = Join-Path $reportsDir "report-$dateStamp.csv"
                    Export-OrganizerCSV -Results $moveResults -OutputPath $csvFile | Out-Null
                    $txtLogConsole.AppendText("[REPORT] CSV File generated: $csvFile`n")
                }
            }
            catch {
                [System.Windows.MessageBox]::Show($_.Exception.Message, "Organize Error", "OK", "Error")
            }
        })

    $btnWatcher.Add_Click({
            try {
                $status = Get-OrganizerWatcherStatus
                if ($status.IsActive) {
                    Stop-OrganizerWatcher | Out-Null
                    $btnWatcher.Content = "START WATCHER"
                    $btnWatcher.Background = "#131210"
                    $btnWatcher.Foreground = "#f5efe1"
                    $txtLogConsole.AppendText("[INFO] Real-Time Folder Watcher Stopped.`n")
                }
                else {
                    $targetFolder = $txtFolderPath.Text
                    $ps1Path = Join-Path $projectRoot "DownloadOrganizer.ps1"
                    $exePath = Join-Path $projectRoot "DownloadOrganizerPro.exe"
                    $scriptPath = if (Test-Path -LiteralPath $ps1Path) { $ps1Path } else { $exePath }
                    Start-OrganizerWatcher -Path $targetFolder -ScriptPath $scriptPath -DebounceSeconds 2 | Out-Null
                    $btnWatcher.Content = "STOP WATCHER"
                    $btnWatcher.Background = "#ff4444"
                    $btnWatcher.Foreground = "#0c0b09"
                    $txtLogConsole.AppendText("[WATCH] Real-Time Folder Watcher Activated for: $targetFolder`n")
                }
            }
            catch {
                [System.Windows.MessageBox]::Show($_.Exception.Message, "Watcher Error", "OK", "Error")
            }
        })

    $btnUndo.Add_Click({
            try {
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
            }
            catch {
                [System.Windows.MessageBox]::Show($_.Exception.Message, "Undo Error", "OK", "Error")
            }
        })

    $btnReportStats.Add_Click({
            try {
                $logsDir = Join-Path $projectRoot "logs"
                $stats = Get-OrganizerStatistics -LogPath $logsDir
                $msg = "HISTORICAL STATISTICS:`n`nTotal Executions Logged: $($stats.TotalExecutions)`nTotal Files Moved: $($stats.TotalMoved)`nTotal Operations Failed: $($stats.TotalFailed)"
                [System.Windows.MessageBox]::Show($msg, "Statistics Dashboard", "OK", "Information")
            }
            catch {
                [System.Windows.MessageBox]::Show($_.Exception.Message, "Stats Error", "OK", "Error")
            }
        })

    $window.Add_Closed({
            Stop-OrganizerWatcher | Out-Null
        })

    $window.ShowDialog() | Out-Null
    Stop-OrganizerWatcher | Out-Null
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