[CmdletBinding()]
param(
    [ValidateSet("Validate", "List", "Create", "Pull", "Diff", "Apply", "ImportPrompt", "ExportPrompt", "SelfTest")]
    [string]$Action = "Validate",
    [string]$ProjectCode = "PR004",
    [string]$AssistantId,
    [string]$AccountId,
    [switch]$ConfirmCreate,
    [switch]$ConfirmApply,
    [switch]$ConfirmOverwrite
)

$ErrorActionPreference = "Stop"
$ApiBaseUrl = "https://api.vapi.ai"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$RemoteSecretPlaceholder = '${VAPI_REMOTE_SECRET}'
$ReadOnlyTopLevelFields = @("id", "orgId", "createdAt", "updatedAt", "isServerUrlSecretSet", "latestVersion")

function Get-PropertyValue {
    param([AllowNull()]$Object, [Parameter(Mandatory = $true)][string]$Name)
    if ($null -eq $Object) { return $null }
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    return $property.Value
}

function ConvertTo-Hashtable {
    param([AllowNull()]$InputObject)
    if ($null -eq $InputObject) { return $null }

    if ($InputObject -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $InputObject.Keys) {
            $result[[string]$key] = ConvertTo-Hashtable $InputObject[$key]
        }
        return ,$result
    }

    if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
        $result = @()
        foreach ($item in $InputObject) { $result += ,(ConvertTo-Hashtable $item) }
        return ,$result
    }

    if ($InputObject -is [pscustomobject]) {
        $result = @{}
        foreach ($property in $InputObject.PSObject.Properties) {
            $result[$property.Name] = ConvertTo-Hashtable $property.Value
        }
        return ,$result
    }

    return $InputObject
}

function Get-AgentPaths {
    param([Parameter(Mandatory = $true)][string]$Code)

    $registryPath = Join-Path $ProjectRoot "agents\registry.json"
    $registry = Get-Content -Raw -Encoding UTF8 $registryPath | ConvertFrom-Json
    $entries = @($registry.agents | Where-Object { $_.project_code -eq $Code })
    if ($entries.Count -ne 1) {
        throw "Expected exactly one registry entry for $Code; found $($entries.Count)."
    }

    $agentDirectory = Join-Path $ProjectRoot ("agents\" + $entries[0].folder)
    return [pscustomobject]@{
        AgentDirectory = $agentDirectory
        SettingsPath = Join-Path $agentDirectory "settings.json"
        PromptPath = Join-Path $agentDirectory "prompt.md"
        GptLivePromptPath = Join-Path $agentDirectory "prompt-gpt-live.md"
        ConfigPath = Join-Path $agentDirectory "vapi.config.json"
        SnapshotDirectory = Join-Path $agentDirectory ".vapi"
        SnapshotPath = Join-Path $agentDirectory ".vapi\remote.full.json"
    }
}

function Read-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { throw "Missing JSON file: $Path" }
    return Get-Content -Raw -Encoding UTF8 $Path | ConvertFrom-Json
}

function Write-JsonFile {
    param([Parameter(Mandatory = $true)][string]$Path, [Parameter(Mandatory = $true)]$Value)
    $json = $Value | ConvertTo-Json -Depth 100
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, [System.Text.UTF8Encoding]::new($false))
}

function Get-MarkdownCodeBlock {
    param([string]$Markdown, [string]$Heading)
    $pattern = '(?ms)^##\s+{0}\s*\r?\n\s*\x60\x60\x60[^\r\n]*\r?\n(.*?)\r?\n\x60\x60\x60' -f [regex]::Escape($Heading)
    $match = [regex]::Match($Markdown, $pattern)
    if (-not $match.Success) { throw "Could not find a fenced code block under '## $Heading'." }
    return $match.Groups[1].Value.Trim()
}

function Set-MarkdownCodeBlock {
    param([string]$Markdown, [string]$Heading, [string]$Content)
    $pattern = '(?ms)(^##\s+{0}\s*\r?\n\s*\x60\x60\x60[^\r\n]*\r?\n).*?(\r?\n\x60\x60\x60)' -f [regex]::Escape($Heading)
    if (-not [regex]::IsMatch($Markdown, $pattern)) {
        throw "Could not find a fenced code block under '## $Heading'."
    }
    $evaluator = [System.Text.RegularExpressions.MatchEvaluator]{ param($match) $match.Groups[1].Value + $Content.Trim() + $match.Groups[2].Value }
    return [regex]::Replace($Markdown, $pattern, $evaluator, 1)
}

function Test-SensitiveName {
    param([string]$Name)
    return $Name -match '(?i)(api[-_]?key|access[-_]?token|auth[-_]?token|password|authorization|client[-_]?secret|private[-_]?key|^secret$)'
}

function ConvertTo-LocalConfig {
    param([AllowNull()]$Value, [string]$Path = "", [bool]$AtRoot = $true)

    if ($null -eq $Value) { return $null }
    $hash = ConvertTo-Hashtable $Value

    if ($hash -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $hash.Keys) {
            if ($AtRoot -and $ReadOnlyTopLevelFields -contains $key) { continue }
            $childPath = if ($Path) { "$Path.$key" } else { $key }
            $child = $hash[$key]
            if ((Test-SensitiveName $key) -and $child -is [string] -and -not [string]::IsNullOrWhiteSpace($child)) {
                $result[$key] = $RemoteSecretPlaceholder
            }
            else {
                $result[$key] = ConvertTo-LocalConfig -Value $child -Path $childPath -AtRoot $false
            }
        }
        return ,$result
    }

    if (($hash -is [System.Collections.IEnumerable]) -and -not ($hash -is [string])) {
        $result = @()
        $index = 0
        foreach ($item in $hash) {
            $result += ,(ConvertTo-LocalConfig -Value $item -Path "$Path[$index]" -AtRoot $false)
            $index++
        }
        return ,$result
    }

    return $hash
}

function Assert-NoRawSecrets {
    param([AllowNull()]$Value, [string]$Path = "config")
    $hash = ConvertTo-Hashtable $Value
    if ($null -eq $hash) { return }

    if ($hash -is [System.Collections.IDictionary]) {
        foreach ($key in $hash.Keys) {
            $child = $hash[$key]
            $childPath = "$Path.$key"
            if ((Test-SensitiveName $key) -and $child -is [string] -and -not [string]::IsNullOrWhiteSpace($child)) {
                $isRemotePlaceholder = $child -eq $RemoteSecretPlaceholder
                $isEnvironmentReference = $child -match '^\$\{ENV:[A-Za-z_][A-Za-z0-9_]*\}$'
                if (-not $isRemotePlaceholder -and -not $isEnvironmentReference) {
                    throw "Possible raw secret at $childPath. Use `${VAPI_REMOTE_SECRET} to preserve the remote value or `${ENV:VARIABLE_NAME} to inject an environment value."
                }
            }
            Assert-NoRawSecrets -Value $child -Path $childPath
        }
        return
    }

    if (($hash -is [System.Collections.IEnumerable]) -and -not ($hash -is [string])) {
        $index = 0
        foreach ($item in $hash) {
            Assert-NoRawSecrets -Value $item -Path "$Path[$index]"
            $index++
        }
    }
}

function Resolve-SecretReferences {
    param([AllowNull()]$LocalValue, [AllowNull()]$RemoteValue, [string]$Path = "config")
    $local = ConvertTo-Hashtable $LocalValue
    $remote = ConvertTo-Hashtable $RemoteValue
    if ($null -eq $local) { return $null }

    if ($local -is [string]) {
        if ($local -eq $RemoteSecretPlaceholder) {
            if ($null -eq $remote) { throw "No remote value exists for secret placeholder at $Path." }
            return $remote
        }
        if ($local -match '^\$\{ENV:([A-Za-z_][A-Za-z0-9_]*)\}$') {
            $environmentName = $matches[1]
            $environmentValue = [Environment]::GetEnvironmentVariable($environmentName, "Process")
            if ([string]::IsNullOrWhiteSpace($environmentValue)) { throw "Environment variable $environmentName is required by $Path." }
            return $environmentValue
        }
        return $local
    }

    if ($local -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $local.Keys) {
            $remoteChild = $null
            if ($remote -is [System.Collections.IDictionary] -and $remote.ContainsKey($key)) { $remoteChild = $remote[$key] }
            $result[$key] = Resolve-SecretReferences -LocalValue $local[$key] -RemoteValue $remoteChild -Path "$Path.$key"
        }
        return ,$result
    }

    if (($local -is [System.Collections.IEnumerable]) -and -not ($local -is [string])) {
        $result = @()
        for ($index = 0; $index -lt $local.Count; $index++) {
            $remoteChild = if ($null -ne $remote -and $index -lt $remote.Count) { $remote[$index] } else { $null }
            $result += ,(Resolve-SecretReferences -LocalValue $local[$index] -RemoteValue $remoteChild -Path "$Path[$index]")
        }
        return ,$result
    }

    return $local
}

function ConvertTo-CanonicalValue {
    param([AllowNull()]$Value)
    $hash = ConvertTo-Hashtable $Value
    if ($null -eq $hash) { return $null }

    if ($hash -is [System.Collections.IDictionary]) {
        $ordered = [ordered]@{}
        foreach ($key in @($hash.Keys | Sort-Object)) { $ordered[$key] = ConvertTo-CanonicalValue $hash[$key] }
        return $ordered
    }

    if (($hash -is [System.Collections.IEnumerable]) -and -not ($hash -is [string])) {
        $result = @()
        foreach ($item in $hash) { $result += ,(ConvertTo-CanonicalValue $item) }
        return ,$result
    }

    return $hash
}

function ConvertTo-CanonicalJson {
    param([AllowNull()]$Value)
    return ConvertTo-CanonicalValue $Value | ConvertTo-Json -Depth 100
}

function Get-VapiApiKey {
    $apiKey = [Environment]::GetEnvironmentVariable("VAPI_API_KEY", "Process")
    if ([string]::IsNullOrWhiteSpace($apiKey)) {
        throw "VAPI_API_KEY is not set in this PowerShell process. Never paste it into chat or pass it as a command argument."
    }
    $apiKey = $apiKey.Trim()
    if ($apiKey -match '[\x00-\x1F\x7F]') {
        throw "VAPI_API_KEY contains a hidden control character. Remove the environment variable and enter the key again using the masked prompt."
    }
    return $apiKey
}

function ConvertTo-Utf8Json {
    param([Parameter(Mandatory = $true)]$Value)
    return $Value | ConvertTo-Json -Depth 100 -Compress
}

function Invoke-VapiRequest {
    param([ValidateSet("GET", "POST", "PATCH")][string]$Method, [string]$Path, $Body)

    Add-Type -AssemblyName System.Net.Http
    $apiKey = Get-VapiApiKey
    $client = [System.Net.Http.HttpClient]::new()
    $request = [System.Net.Http.HttpRequestMessage]::new(
        [System.Net.Http.HttpMethod]::new($Method),
        "$ApiBaseUrl$Path"
    )
    $request.Headers.Authorization = [System.Net.Http.Headers.AuthenticationHeaderValue]::new("Bearer", $apiKey)

    if ($null -ne $Body) {
        # Send literal Unicode as UTF-8, matching the dashboard transport and
        # avoiding Windows PowerShell 5.1 web-cmdlet encoding defaults.
        $json = ConvertTo-Utf8Json $Body
        $request.Content = [System.Net.Http.StringContent]::new($json, [System.Text.Encoding]::UTF8, "application/json")
    }

    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        try {
            $responseText = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            if (-not $response.IsSuccessStatusCode) {
                throw "Vapi API returned HTTP $([int]$response.StatusCode) ($($response.ReasonPhrase)): $responseText"
            }
            if ([string]::IsNullOrWhiteSpace($responseText)) { return $null }
            return $responseText | ConvertFrom-Json
        }
        finally {
            $response.Dispose()
        }
    }
    finally {
        $request.Dispose()
        $client.Dispose()
    }
}

function Resolve-RemoteAssistant {
    param($Settings, [string]$RequestedId)
    $resolvedId = if ($RequestedId) { $RequestedId } else { [string]$Settings.provider_agent_id }
    if ($resolvedId) { return Invoke-VapiRequest -Method GET -Path "/assistant/$resolvedId" }

    $assistants = @(Invoke-VapiRequest -Method GET -Path "/assistant")
    $matches = @($assistants | Where-Object { $_.name -eq $Settings.agent_name })
    if ($matches.Count -ne 1) {
        throw "Expected one Vapi assistant named '$($Settings.agent_name)'; found $($matches.Count). Use -Action List, then pass -AssistantId."
    }
    return $matches[0]
}

function Save-RemoteSnapshot {
    param($Paths, $Remote)
    if (-not (Test-Path -LiteralPath $Paths.SnapshotDirectory)) {
        New-Item -ItemType Directory -Path $Paths.SnapshotDirectory | Out-Null
    }
    Write-JsonFile -Path $Paths.SnapshotPath -Value (ConvertTo-LocalConfig $Remote)
}

function Save-AgentMapping {
    param($Paths, $Settings, $Remote, [string]$RequestedAccountId)
    $settingsHash = ConvertTo-Hashtable $Settings
    $settingsHash.provider = "vapi"
    $settingsHash.provider_agent_id = [string]$Remote.id
    if ($RequestedAccountId) { $settingsHash.account_id = $RequestedAccountId }
    $settingsHash.updated_at = (Get-Date).ToString("yyyy-MM-dd")
    Write-JsonFile -Path $Paths.SettingsPath -Value $settingsHash
}

function Get-ConfigSystemPrompt {
    param($Config)
    $model = Get-PropertyValue $Config "model"
    foreach ($message in @((Get-PropertyValue $model "messages"))) {
        if ((Get-PropertyValue $message "role") -eq "system") { return [string](Get-PropertyValue $message "content") }
    }
    $reasoner = Get-PropertyValue $model "reasoner"
    if ($null -ne $reasoner -and $null -ne (Get-PropertyValue $reasoner "instructions")) {
        return [string](Get-PropertyValue $reasoner "instructions")
    }
    $speaker = Get-PropertyValue $model "speaker"
    if ($null -ne $speaker -and $null -ne (Get-PropertyValue $speaker "instructions")) {
        return [string](Get-PropertyValue $speaker "instructions")
    }
    throw "vapi.config.json has no system prompt in model.messages, model.reasoner.instructions, or model.speaker.instructions."
}

function Set-ConfigSystemPrompt {
    param($Config, [string]$Content)
    $hash = ConvertTo-Hashtable $Config
    if (-not $hash.ContainsKey("model") -or $null -eq $hash.model) { throw "vapi.config.json has no model object." }
    $updated = $false
    foreach ($message in @($hash.model.messages)) {
        if (-not $updated -and $message.role -eq "system") { $message.content = $Content; $updated = $true }
    }
    if ($hash.model.ContainsKey("speaker") -and $null -ne $hash.model.speaker) {
        $hash.model.speaker.instructions = $Content
        $updated = $true
    }
    if ($hash.model.ContainsKey("reasoner") -and $null -ne $hash.model.reasoner) {
        $hash.model.reasoner.instructions = $Content
        $updated = $true
    }
    if (-not $updated) { throw "vapi.config.json has no supported system prompt field." }
    return $hash
}

function Test-IsGptLiveConfig {
    param($Config)
    return (Get-PropertyValue (Get-PropertyValue $Config "model") "model") -eq "gpt-live-1"
}

function Test-PromptMirror {
    param($Paths, $Config)
    if ((Test-IsGptLiveConfig $Config) -and (Test-Path -LiteralPath $Paths.GptLivePromptPath)) {
        $markdown = Get-Content -Raw -Encoding UTF8 $Paths.GptLivePromptPath
        $model = Get-PropertyValue $Config "model"
        $speaker = Get-PropertyValue $model "speaker"
        $reasoner = Get-PropertyValue $model "reasoner"
        $speakerMatches = (Get-MarkdownCodeBlock $markdown "Speaker") -ceq [string](Get-PropertyValue $speaker "instructions")
        $reasonerMatches = (Get-MarkdownCodeBlock $markdown "Reasoner") -ceq [string](Get-PropertyValue $reasoner "instructions")
        $firstMessageMatches = (Get-MarkdownCodeBlock $markdown "First Message") -ceq [string](Get-PropertyValue $Config "firstMessage")
        return $speakerMatches -and $reasonerMatches -and $firstMessageMatches
    }

    $markdown = Get-Content -Raw -Encoding UTF8 $Paths.PromptPath
    $promptMatches = (Get-MarkdownCodeBlock $markdown "System Prompt") -ceq (Get-ConfigSystemPrompt $Config)
    $firstMessageMatches = (Get-MarkdownCodeBlock $markdown "First Message") -ceq [string](Get-PropertyValue $Config "firstMessage")
    return $promptMatches -and $firstMessageMatches
}

function Show-FullDiff {
    param($LocalConfig, $RemoteConfig)
    $localLines = (ConvertTo-CanonicalJson $LocalConfig) -split "`r?`n"
    $remoteLines = (ConvertTo-CanonicalJson $RemoteConfig) -split "`r?`n"
    $differences = @(Compare-Object -ReferenceObject $remoteLines -DifferenceObject $localLines)
    if ($differences.Count -eq 0) {
        Write-Host "Full local configuration matches the Vapi API draft view. The current published version may still differ."
        return $false
    }

    Write-Host "Full configuration differences:"
    $differences |
        Select-Object -First 200 -Property @{
            Name = "Source"
            Expression = { if ($_.SideIndicator -eq "=>") { "LOCAL (will apply)" } else { "VAPI (current)" } }
        }, InputObject |
        Format-Table Source, InputObject -Wrap |
        Out-Host
    if ($differences.Count -gt 200) { Write-Host "Output truncated: $($differences.Count - 200) additional differing lines." }
    return $true
}

$paths = Get-AgentPaths $ProjectCode
$settings = Read-JsonFile $paths.SettingsPath

if ($Action -eq "SelfTest") {
    $fixture = @{ id = "readonly"; name = "Fixture"; credentials = @(@{ apiKey = "secret-value"; credentialId = "safe-id" }); model = @{ provider = "openai" } }
    $localFixture = ConvertTo-LocalConfig $fixture
    if ($localFixture.ContainsKey("id")) { throw "Self-test failed: read-only field was retained." }
    if ($localFixture.credentials.Count -ne 1) { throw "Self-test failed: a single-item array was not preserved." }
    if ($localFixture.credentials[0].apiKey -ne $RemoteSecretPlaceholder) { throw "Self-test failed: secret was not redacted." }
    $rawSecretWasBlocked = $false
    try { Assert-NoRawSecrets $fixture } catch { $rawSecretWasBlocked = $true }
    if (-not $rawSecretWasBlocked) { throw "Self-test failed: a raw secret was not blocked." }
    $remoteFixture = ConvertTo-Hashtable $fixture
    $remoteFixture.Remove("id")
    $resolvedFixture = Resolve-SecretReferences $localFixture $remoteFixture
    if ($resolvedFixture.credentials[0].apiKey -ne "secret-value") { throw "Self-test failed: remote secret was not restored in memory." }
    $unicodeText = "Krak" + [char]0x00F3 + "w " + [char]0x2014 + " " + [char]0x0141 + [char]0x0105 + "czna, Pa" + [char]0x0144 + "stwu"
    $unicodeFixture = @{ text = $unicodeText }
    $utf8Json = ConvertTo-Utf8Json $unicodeFixture
    if ($utf8Json -notmatch '[^\x00-\x7F]') { throw "Self-test failed: request JSON does not contain literal Unicode." }
    $utf8 = New-Object System.Text.UTF8Encoding($false, $true)
    $transportRoundTrip = $utf8.GetString($utf8.GetBytes($utf8Json))
    $unicodeRoundTrip = $transportRoundTrip | ConvertFrom-Json
    if ($unicodeRoundTrip.text -cne $unicodeFixture.text) { throw "Self-test failed: Unicode JSON escape round trip changed text." }
    Write-Host "Full-config sanitizer and canonicalizer self-test passed."
    exit 0
}

if ($Action -eq "List") {
    @(Invoke-VapiRequest -Method GET -Path "/assistant") | Select-Object id, name, updatedAt | Sort-Object name | Format-Table -AutoSize
    exit 0
}

if ($Action -eq "Validate") {
    if (-not (Test-Path -LiteralPath $paths.ConfigPath)) {
        Write-Host "Local prompt/settings are present. Full Vapi config has not been pulled yet: $($paths.ConfigPath)"
        exit 0
    }
    $config = Read-JsonFile $paths.ConfigPath
    Assert-NoRawSecrets $config
    foreach ($field in $ReadOnlyTopLevelFields) {
        if ($null -ne $config.PSObject.Properties[$field]) { throw "Read-only field '$field' must not be stored in vapi.config.json." }
    }
    if (-not (Test-PromptMirror $paths $config)) { throw "prompt.md has drifted from vapi.config.json. Use ImportPrompt or ExportPrompt intentionally." }
    Write-Host "Full local Vapi configuration and prompt mirror are valid: $ProjectCode"
    exit 0
}

if ($Action -eq "ImportPrompt") {
    $config = Read-JsonFile $paths.ConfigPath
    if ((Test-IsGptLiveConfig $config) -and (Test-Path -LiteralPath $paths.GptLivePromptPath)) {
        $markdown = Get-Content -Raw -Encoding UTF8 $paths.GptLivePromptPath
        $hash = ConvertTo-Hashtable $config
        $hash.model.speaker.instructions = Get-MarkdownCodeBlock $markdown "Speaker"
        $hash.model.reasoner.instructions = Get-MarkdownCodeBlock $markdown "Reasoner"
        $hash.firstMessage = Get-MarkdownCodeBlock $markdown "First Message"
        $config = $hash
        $sourceName = "prompt-gpt-live.md"
    }
    else {
        $markdown = Get-Content -Raw -Encoding UTF8 $paths.PromptPath
        $config = Set-ConfigSystemPrompt $config (Get-MarkdownCodeBlock $markdown "System Prompt")
        $config.firstMessage = Get-MarkdownCodeBlock $markdown "First Message"
        $sourceName = "prompt.md"
    }
    Assert-NoRawSecrets $config
    Write-JsonFile $paths.ConfigPath $config
    Write-Host "Imported $sourceName into vapi.config.json."
    exit 0
}

if ($Action -eq "ExportPrompt") {
    $config = Read-JsonFile $paths.ConfigPath
    if ((Test-IsGptLiveConfig $config) -and (Test-Path -LiteralPath $paths.GptLivePromptPath)) {
        $markdown = Get-Content -Raw -Encoding UTF8 $paths.GptLivePromptPath
        $model = Get-PropertyValue $config "model"
        $markdown = Set-MarkdownCodeBlock $markdown "Speaker" ([string](Get-PropertyValue (Get-PropertyValue $model "speaker") "instructions"))
        $markdown = Set-MarkdownCodeBlock $markdown "Reasoner" ([string](Get-PropertyValue (Get-PropertyValue $model "reasoner") "instructions"))
        $markdown = Set-MarkdownCodeBlock $markdown "First Message" ([string]$config.firstMessage)
        $destinationPath = $paths.GptLivePromptPath
        $destinationName = "prompt-gpt-live.md"
    }
    else {
        $markdown = Get-Content -Raw -Encoding UTF8 $paths.PromptPath
        $markdown = Set-MarkdownCodeBlock $markdown "System Prompt" (Get-ConfigSystemPrompt $config)
        $markdown = Set-MarkdownCodeBlock $markdown "First Message" ([string]$config.firstMessage)
        $destinationPath = $paths.PromptPath
        $destinationName = "prompt.md"
    }
    [System.IO.File]::WriteAllText($destinationPath, $markdown, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Exported vapi.config.json prompt fields into $destinationName."
    exit 0
}

if ($Action -eq "Create") {
    if (-not $ConfirmCreate) { throw "Create is blocked. Re-run with -Action Create -ConfirmCreate after validating the local configuration." }
    if ($settings.provider_agent_id) { throw "Create is blocked because PR004 already has provider_agent_id '$($settings.provider_agent_id)'." }
    if (-not (Test-Path -LiteralPath $paths.ConfigPath)) { throw "Create requires $($paths.ConfigPath)." }
    if (-not $AccountId -and -not $settings.account_id) { throw "Pass -AccountId when creating the assistant." }

    $localConfig = Read-JsonFile $paths.ConfigPath
    Assert-NoRawSecrets $localConfig
    if (-not (Test-PromptMirror $paths $localConfig)) { throw "Create is blocked because prompt.md and vapi.config.json differ." }
    $payload = Resolve-SecretReferences $localConfig $null
    $created = Invoke-VapiRequest -Method POST -Path "/assistant" -Body $payload
    $createdConfig = ConvertTo-LocalConfig $created
    Save-RemoteSnapshot $paths $created
    Write-JsonFile $paths.ConfigPath $createdConfig
    Save-AgentMapping $paths $settings $created $AccountId
    Write-Host "Created Vapi assistant '$($created.name)' ($($created.id)) and adopted the complete returned configuration locally."
    exit 0
}

$remote = Resolve-RemoteAssistant $settings $AssistantId
$remoteConfig = ConvertTo-LocalConfig $remote

if ($Action -eq "Pull") {
    if ((Test-Path -LiteralPath $paths.ConfigPath) -and -not $ConfirmOverwrite) {
        $existing = Read-JsonFile $paths.ConfigPath
        if ((ConvertTo-CanonicalJson $existing) -cne (ConvertTo-CanonicalJson $remoteConfig)) {
            throw "Pull would overwrite local configuration. Review Diff or re-run Pull with -ConfirmOverwrite."
        }
    }
    if (-not $AccountId -and -not $settings.account_id) { throw "Pass -AccountId when linking this assistant." }
    Assert-NoRawSecrets $remoteConfig
    Save-RemoteSnapshot $paths $remote
    Write-JsonFile $paths.ConfigPath $remoteConfig
    Save-AgentMapping $paths $settings $remote $AccountId
    Write-Host "Pulled the full editable Vapi configuration to $($paths.ConfigPath)."
    if (-not (Test-PromptMirror $paths $remoteConfig)) { Write-Warning "prompt.md differs from the pulled config. Choose ImportPrompt or ExportPrompt before applying changes." }
    exit 0
}

$localConfig = Read-JsonFile $paths.ConfigPath
Assert-NoRawSecrets $localConfig
$hasDiff = Show-FullDiff $localConfig $remoteConfig
if ($Action -eq "Diff") { exit 0 }

if (-not $ConfirmApply) { throw "Apply is blocked. Re-run with -Action Apply -ConfirmApply after reviewing the full diff." }
if ($settings.status -eq "live") { throw "Apply is blocked because the local agent status is 'live'. Use a separately reviewed release workflow." }
if (-not (Test-PromptMirror $paths $localConfig)) { throw "Apply is blocked because prompt.md and vapi.config.json differ." }

Save-RemoteSnapshot $paths $remote
$remoteForSecrets = ConvertTo-Hashtable $remote
foreach ($field in $ReadOnlyTopLevelFields) { $remoteForSecrets.Remove($field) }
$payload = Resolve-SecretReferences $localConfig $remoteForSecrets
$updated = Invoke-VapiRequest -Method PATCH -Path "/assistant/$($remote.id)" -Body $payload
$verified = Invoke-VapiRequest -Method GET -Path "/assistant/$($remote.id)"
$verifiedConfig = ConvertTo-LocalConfig $verified
if ((ConvertTo-CanonicalJson $localConfig) -cne (ConvertTo-CanonicalJson $verifiedConfig)) {
    Show-FullDiff $localConfig $verifiedConfig | Out-Null
    throw "Vapi accepted the update, but the full configuration did not verify exactly."
}
Save-AgentMapping $paths $settings $updated $AccountId
Write-Host "Applied and verified the full Vapi draft configuration for '$($verified.name)' ($($verified.id))."
Write-Warning "This does not publish the draft. Inbound and default web/outbound calls continue using Vapi's current published version until the draft is published."
Write-Warning "Vapi drafts are per user. A dashboard session can publish its own draft instead of the API-key draft; compare the complete dashboard publish preview before publishing."
