Set-StrictMode -Version Latest
$modules = @('Models', 'Utils', 'Validation', 'Config', 'Scanner', 'Classifier', 'SmartClassifier', 'DuplicateDetector', 'Transactions', 'Mover', 'Logger', 'Summary', 'Undo', 'Watcher', 'Scheduler', 'ReportGenerator', 'Organizer', 'GUI')
foreach ($name in $modules) { Import-Module "$PSScriptRoot/modules/$name.psm1" }
Export-ModuleMember -Function *
