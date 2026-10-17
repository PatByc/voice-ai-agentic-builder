$ErrorActionPreference = "Stop"

$createdToken = -not (Test-Path Env:VAPI_API_KEY)
$vapiSecret = $null
$vapiPointer = [IntPtr]::Zero

try {
    if ($createdToken) {
        $vapiSecret = Read-Host "Vapi private API key" -AsSecureString
        $vapiPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($vapiSecret)
        $env:VAPI_API_KEY = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($vapiPointer)
    }

    if ([string]::IsNullOrWhiteSpace($env:VAPI_API_KEY)) {
        throw "VAPI_API_KEY is empty."
    }

    pi mcp list
    if ($LASTEXITCODE -ne 0) {
        throw "Vapi MCP connection check failed."
    }

    pi
}
finally {
    if ($vapiPointer -ne [IntPtr]::Zero) {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($vapiPointer)
    }
    if ($createdToken) {
        Remove-Item Env:VAPI_API_KEY -ErrorAction SilentlyContinue
    }
    Remove-Variable vapiSecret -ErrorAction SilentlyContinue
}
