param(
    [Parameter(Mandatory = $true)]
    [string]$ModelPath,
    [string]$PackageName = "com.example.dish_dash"
)

$ErrorActionPreference = "Stop"
$resolvedModel = (Resolve-Path -LiteralPath $ModelPath).Path
$modelFileName = "gemma-4-e2b-it.litertlm"
$targetDir = "app_flutter/models"
$remoteTemp = "/data/local/tmp/$modelFileName"
$targetFile = "$targetDir/$modelFileName"

adb get-state | Out-Null
adb push $resolvedModel $remoteTemp
adb shell run-as $PackageName mkdir -p $targetDir
adb shell run-as $PackageName cp $remoteTemp $targetFile
adb shell run-as $PackageName ls -lh $targetFile

Write-Host "Model installed at Documents/models/$modelFileName"
