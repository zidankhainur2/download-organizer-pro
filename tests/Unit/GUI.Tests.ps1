$ProjectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent

Import-Module "$ProjectRoot\modules\Config.psm1" -Force
Import-Module "$ProjectRoot\modules\GUI.psm1" -Force

Describe "GUI Module Unit Tests" {
    It "Should export Show-OrganizerGUI and New-OrganizerWindow functions" {
        $cmd1 = Get-Command Show-OrganizerGUI -ErrorAction SilentlyContinue
        $cmd2 = Get-Command New-OrganizerWindow -ErrorAction SilentlyContinue

        $cmd1 | Should Not Be $null
        $cmd2 | Should Not Be $null
    }

    It "Should parse WPF XAML template and find all named controls" {
        Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase -ErrorAction SilentlyContinue
        $guiCode = Get-Content "$ProjectRoot\modules\GUI.psm1" -Raw
        $startIdx = $guiCode.IndexOf('<Window')
        $endIdx = $guiCode.IndexOf('</Window>') + 9
        $xamlText = $guiCode.Substring($startIdx, $endIdx - $startIdx)

        $win = [Windows.Markup.XamlReader]::Parse($xamlText)
        $win | Should Not Be $null

        $win.FindName("TxtFolderPath") | Should Not Be $null
        $win.FindName("BtnStart") | Should Not Be $null
        $win.FindName("BtnBrowse") | Should Not Be $null
        $win.FindName("BtnWatcher") | Should Not Be $null
        $win.FindName("BtnUndo") | Should Not Be $null
        $win.FindName("BtnReportStats") | Should Not Be $null
        $win.FindName("GridResults") | Should Not Be $null
        $win.FindName("TxtLogConsole") | Should Not Be $null
    }
}
