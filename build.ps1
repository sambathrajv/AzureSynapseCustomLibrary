python.exe -m pip install --upgrade pip
pip install wheel
pip install SetupTools

if (Test-Path -Path .\dist) {
    Write-Host "Removing dist folder" -ForegroundColor Green
    Remove-Item .\dist -Force -Recurse
}
function clean_folders() {
    if (Test-Path -Path .\build) {
        Write-Host "Removing build folder" -ForegroundColor Green
        Remove-Item .\build -Force -Recurse
    }
    if (Test-Path -Path .\AzureLibrary\AzureLibrary.Sample.egg-info) {
        Write-Host "Removing AzureLibrary.Sample.egg-info" -ForegroundColor Green
        Remove-Item .\AzureLibrary\AzureLibrary.Sample.egg-info -Force -Recurse
    }
    $Error.Clear()
}
clean_folders
try {
    python setup.py sdist bdist_wheel
}
catch [System.Management.Automation.RemoteException] {
    $r = ($Error | Select-Object –Property *)
    if ($r.Exception.Message.ToLower().Contains("setuptoolsdeprecationwarning")) {
        Write-Host $r.Exception.Message -ForegroundColor Yellow
    }
    else {
        throw $r.Exception
    }

}
clean_folders