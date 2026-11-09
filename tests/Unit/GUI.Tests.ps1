BeforeAll {
$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Config.psm1"
Import-Module "$ProjectRoot\modules\GUI.psm1"


. "$ProjectRoot/tests/TestHelpers.ps1"
$testConfigPath = Join-Path $TestDrive "config.json"
New-TestConfig $TestDrive | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $testConfigPath
}

Describe "GUI Module Unit Tests" {
    It 'keeps every action button reachable at an 800 pixel window width' {
        $window = [Windows.Markup.XamlReader]::Parse((Get-Content -LiteralPath "$ProjectRoot/assets/OrganizerWindow.xaml" -Raw))
        $window.Width = 800
        try {
            $window.Show()
            $window.UpdateLayout()
            foreach ($name in @('BtnStart','BtnWatcher','BtnUndo','BtnReportStats','BtnSchedule')) {
                $button = $window.FindName($name)
                $position = $button.TranslatePoint([Windows.Point]::new(0,0), $window)
                ($position.X + $button.ActualWidth) | Should -BeLessOrEqual $window.ActualWidth
                ($position.Y + $button.ActualHeight) | Should -BeLessOrEqual $window.ActualHeight
            }
        }
        finally { $window.Close() }
    }
    It 'passes the isolated task name through status, registration and removal' {
        InModuleScope GUI -Parameters @{ ConfigPath = $testConfigPath } {
            param($ConfigPath)
            $script:taskChecks = 0
            Mock Get-OrganizerTask { $script:taskChecks++; [pscustomobject]@{ IsRegistered = ($script:taskChecks -gt 1) } }
            Mock Register-OrganizerTask { $true }
            Mock Unregister-OrganizerTask { $true }
            $probe = @{ Clicked = $false; Error = ''; Ticks = 0 }
            $timer = [Windows.Threading.DispatcherTimer]::new()
            $timer.Interval = [timespan]::FromMilliseconds(100)
            $timer.Add_Tick({
                $probe.Ticks++
                $win = @([Windows.Interop.HwndSource]::CurrentSources | ForEach-Object { $_.RootVisual } | Where-Object { $_ -is [Windows.Window] -and $_.FindName('BtnSchedule') }) | Select-Object -First 1
                if (-not $win) { return }
                try {
                    foreach ($i in 1..2) { $win.FindName('BtnSchedule').RaiseEvent([Windows.RoutedEventArgs]::new([Windows.Controls.Button]::ClickEvent)) }
                    $probe.Clicked = $true
                    $probe.Error = $win.FindName('TxtLogConsole').Text
                }
                finally { $timer.Stop(); $win.Close() }
            }.GetNewClosure())
            $timer.Start()
            try { Show-OrganizerWindow -ConfigPath $ConfigPath -TaskName 'DownloadOrganizerPro-Verify-unit' }
            finally { $timer.Stop() }
            $probe.Clicked | Should -BeTrue
            $probe.Error | Should -Not -Match '\[ERROR\]'
            Should -Invoke Get-OrganizerTask -Times 2 -Exactly -ParameterFilter { $TaskName -eq 'DownloadOrganizerPro-Verify-unit' }
            Should -Invoke Register-OrganizerTask -Times 1 -Exactly -ParameterFilter { $TaskName -eq 'DownloadOrganizerPro-Verify-unit' }
            Should -Invoke Unregister-OrganizerTask -Times 1 -Exactly -ParameterFilter { $TaskName -eq 'DownloadOrganizerPro-Verify-unit' }
        }
    }
    It 'initializes options and expanded folder from configuration' -ForEach @($true, $false) {
        $selected = $_
        $config = New-TestConfig '%TEMP%'
        foreach ($name in @('EnableSmartRules', 'DryRun', 'Recursive', 'ExportHTML', 'ExportCSV')) { $config.Settings.$name = $selected }
        $window = [Windows.Markup.XamlReader]::Parse((Get-Content -LiteralPath "$ProjectRoot/assets/OrganizerWindow.xaml" -Raw))
        $controls = & (Get-Module GUI) { param($window, $config) Initialize-OrganizerWindowControls $window $config '2.2.0' } $window $config
        $controls.TxtFolderPath.Text | Should -Be ([Environment]::ExpandEnvironmentVariables('%TEMP%'))
        foreach ($name in @('ChkSmartRules', 'ChkDryRun', 'ChkRecurse', 'ChkExportHTML', 'ChkExportCSV')) { $controls[$name].IsChecked | Should -Be $selected }
        $controls.TxtVersion.Text | Should -Be 'v2.2.0'
    }
    It "Should export Show-OrganizerGUI and New-OrganizerWindow functions" {
        $cmd1 = Get-Command Show-OrganizerGUI -ErrorAction SilentlyContinue
        $cmd2 = Get-Command New-OrganizerWindow -ErrorAction SilentlyContinue

        $cmd1 | Should -Not -Be $null
        $cmd2 | Should -Not -Be $null
    }

    It "Should parse WPF XAML template and find all named controls" {
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue
        $xamlText = Get-Content -LiteralPath "$ProjectRoot/assets/OrganizerWindow.xaml" -Raw

        $win = [Windows.Markup.XamlReader]::Parse($xamlText)
        $win | Should -Not -Be $null

        $win.FindName("TxtFolderPath") | Should -Not -Be $null
        $win.FindName("BtnStart") | Should -Not -Be $null
        $win.FindName("BtnBrowse") | Should -Not -Be $null
        $win.FindName("BtnWatcher") | Should -Not -Be $null
        $win.FindName("BtnUndo") | Should -Not -Be $null
        $win.FindName("BtnReportStats") | Should -Not -Be $null
        $win.FindName("GridResults") | Should -Not -Be $null
        $win.FindName("TxtLogConsole") | Should -Not -Be $null
        $win.FindName("TxtVersion") | Should -Not -Be $null
        $win.FindName("BtnSchedule") | Should -Not -Be $null
    }
}
