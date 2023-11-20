$ErrorActionPreference = 'Stop'
$workspace = "$(SynapseWorkspaceName)"

Write-Host "Getting list of pools" -ForegroundColor Yellow
$pools = Get-AzSynapseSparkPool -WorkspaceName $workspace

Write-Host "Removing existing package  from existing pools " -ForegroundColor Yellow
$pools | ForEach-Object -Parallel {
    $_.DynamicExecutorAllocation.Enabled = $false
    $packages = ($_.WorkspacePackages )
    if ( $packages.Count -gt 0) {
        Write-Host "Removing existing package from pool " $_.Name -ForegroundColor Yellow
        Update-AzSynapseSparkPool -WorkspaceName $using:workspace -PackageAction Remove -Package $packages -Name $_.Name
    }

} -ThrottleLimit 1

Write-Host "Removing existing package from workspace" -ForegroundColor Yellow
Get-AzSynapseWorkspacePackage -WorkspaceName $workspace |  Where-Object { $_.Name.ToUpper() -like "<PACKAGENAME>*" } | Remove-AzSynapseWorkspacePackage -Force

Write-Host "Uploading new package into workspace" -ForegroundColor Yellow
New-AzSynapseWorkspacePackage -WorkspaceName $workspace -Package $(System.DefaultWorkingDirectory)/_Build/lib/<packagenanme>.whl


$packageList = Get-AzSynapseWorkspacePackage -WorkspaceName $workspace

$jobStatus = New-Object System.Collections.Generic.Dictionary"[String,Microsoft.Azure.Commands.Common.AzureLongRunningJob]"
$pools | ForEach-Object -Parallel {
    Write-Host "Updating pool " $_.Name "with new package" -ForegroundColor Yellow
    $jobs = Update-AzSynapseSparkPool -WorkspaceName $using:workspace  -Name $_.Name -PackageAction Add -Package $using:packageList -EnableDynamicExecutorAllocation $true -AsJob
    $tempjob = $using:jobStatus
    $tempjob.Add($_.Name, $jobs)
    Start-Sleep 120
} -ThrottleLimit 1

while ($jobStatus.Values | Where-Object { $_.State -eq "Running" }) {
    Start-Sleep 120
    Write-Host "Checking for deployment Status" -ForegroundColor Yellow
}
if ($jobStatus.Values | Where-Object { $_.State -eq "Failed" }) {
    throw "Deployment failed"
}
Write-Host "Deployment successful" -ForegroundColor Green