﻿# OUTPUT tsv
<#
Get-ProcsHash.ps1
Acquires hash, set to MD5 by default, for each unique ExecutablePath returned by
Get-WmiObject -Query "Select * from win32_process"

You can change the hash to one of MD5, SHA1, SHA256, SHA384, SHA512 or RIPEMD160 on
the first line of code in this script.
#>

$hashtype = "MD5"

function Compute-FileHash {
Param(
    [Parameter(Mandatory = $true, Position=1)]
    [string]$FilePath,
    [ValidateSet("MD5","SHA1","SHA256","SHA384","SHA512","RIPEMD160")]
    [string]$HashType = "MD5"
)
    
    switch ( $HashType.ToUpper() )
    {
        "MD5"       { $hash = [System.Security.Cryptography.MD5]::Create() }
        "SHA1"      { $hash = [System.Security.Cryptography.SHA1]::Create() }
        "SHA256"    { $hash = [System.Security.Cryptography.SHA256]::Create() }
        "SHA384"    { $hash = [System.Security.Cryptography.SHA384]::Create() }
        "SHA512"    { $hash = [System.Security.Cryptography.SHA512]::Create() }
        "RIPEMD160" { $hash = [System.Security.Cryptography.RIPEMD160]::Create() }
        default     { "Invalid hash type selected." }
    }

    if (Test-Path $FilePath) {
        $FileName = Get-ChildItem $FilePath | Select-Object -ExpandProperty Fullname
        $fileData = [System.IO.File]::ReadAllBytes($FileName)
        $HashBytes = $hash.ComputeHash($fileData)
        $PaddedHex = ""

        foreach($Byte in $HashBytes) {
            $ByteInHex = [String]::Format("{0:X}", $Byte)
            $PaddedHex += $ByteInHex.PadLeft(2,"0")
        }
        $PaddedHex
        
    } else {
        Write-Error -Message "Invalid input file or path specified." -Category InvalidArgument
    }
}

foreach($item in (Get-WmiObject -Query "Select * from win32_process")) {
    if ($item.ExecutablePath) {
        $hash = Compute-FileHash -FilePath $item.ExecutablePath -HashType $hashtype
    } else {
        $hash = "Get-WmiObject query returned no executable path."
    }

    $o = "" | Select-Object ProcessId, ExecutablePath, Hash
    $o.ProcessId = $item.ProcessId
    $o.ExecutablePath = $item.ExecutablePath
    $o.Hash = $hash
    $o
}