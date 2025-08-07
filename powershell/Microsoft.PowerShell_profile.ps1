# =============================================================================
# PowerShell Profile - Well Organized and Enhanced
# =============================================================================

<#
.SYNOPSIS
    Comprehensive PowerShell Profile with advanced PSReadLine features

.DESCRIPTION
    This profile provides an enhanced PowerShell experience with:
    - Advanced PSReadLine configuration (Windows mode)
    - Smart text editing features
    - Directory marking system
    - Virtual environment auto-activation
    - Custom utility functions
    - Extensive keyboard shortcuts

.FEATURES
    ✅ Oh-My-Posh theme integration
    ✅ Terminal Icons for better file visualization
    ✅ Auto virtual environment activation
    ✅ Smart quote and bracket insertion
    ✅ Advanced history management
    ✅ Directory marking and jumping
    ✅ Unicode character input
    ✅ Command validation and auto-correction
    ✅ Clipboard integration
    ✅ Build macros for development

.KEYBOARD_SHORTCUTS
    === History & Navigation ===
    F7                      Show command history in grid view
    UpArrow/DownArrow      History search with cursor positioning

    === Editing & Transformation ===
    F1                     Get help for current command
    Alt+w                  Save current line to history (don't execute)
    Alt+'                  Toggle quotes on arguments
    Alt+%                  Expand aliases to full commands
    Alt+a                  Select command arguments
    Alt+(                  Parenthesize selection
    Alt+x                  Convert 4-digit hex to Unicode character
    
    === Development & Build ===
    Ctrl+b                 Execute msbuild in current directory
    Ctrl+d,Ctrl+c         Capture screen
    
    === Clipboard & Text ===
    Ctrl+C                 Copy (Windows standard)
    Ctrl+V                 Paste (Windows standard)
    Ctrl+Shift+V           Paste as here string
    
    === Tab Completion ===
    Tab                    Cycle through completions (Windows mode)
    Shift+Tab              Cycle backwards through completions
    
    === Word Movement (Emacs style) ===
    Alt+b/f                Move by words backward/forward
    Alt+B/F                Select words backward/forward
    Alt+d                  Kill word forward
    Alt+Backspace          Kill word backward
    
    === Smart Editing ===
    "/'                    Smart quote insertion
    ([{                    Smart bracket insertion with auto-closing
    Backspace              Smart deletion of matching pairs
    RightArrow             Accept next suggestion word at line end

.CUSTOM_COMMANDS
    profile-info           Show profile information and status
    reload                 Reload PowerShell profile
    backup-profile         Create timestamped profile backup
    my-aliases             Show all custom aliases

.VIRTUAL_ENVIRONMENT
    - Automatically activates .venv or venv when entering directories
    - Enhanced cd function with venv detection

.NOTES
    Author: Enhanced PowerShell Profile
    Version: 1.1 (Fixed key bindings, improved functions, added Node version management)
    Requires: PowerShell 7+, PSReadLine 2.1+, Oh-My-Posh
    
    To reload this profile: . $PROFILE
    To edit this profile: code $PROFILE
    
    CHANGELOG v1.1:
    - Fixed undefined $OMPThemePath variable in Show-ProfileInfo
    - Replaced hardcoded function list with dynamic detection
    - Unified virtual environment activation logic (DRY principle)
    - Added Set-NodeVersion function for explicit Node version management
    - Renamed ping alias to psping to avoid conflicts
    - Added community module suggestions (z, PSFzf)
    - Micro-optimization: Moved FindToken helper function outside key handler (performance improvement)
#>

# Import required namespaces
using namespace System.Management.Automation
using namespace System.Management.Automation.Language

# =============================================================================
# SECTION 1: SECURITY AND PREREQUISITES CHECK
# =============================================================================

# Check PowerShell version compatibility
if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Warning "This profile is optimized for PowerShell 7+. Some features may not work properly."
}

# Check execution policy (but don't force change)
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -eq 'Restricted') {
    Write-Host "Execution Policy is Restricted. Some features may not work. Consider running:" -ForegroundColor Yellow
    Write-Host "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser" -ForegroundColor Yellow
}

# =============================================================================
# SECTION 2: AUTOMATIC ENVIRONMENT REFRESH
# =============================================================================

# Auto-refresh environment variables on profile load (VS Code PATH fix)
try {
    $machinePath = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
    if ($machinePath -and $userPath) {
        $env:Path = "$machinePath;$userPath"
        Write-Host "Environment variables refreshed automatically" -ForegroundColor Green
    }
} catch {
    Write-Host "Failed to refresh environment variables: $($_.Exception.Message)" -ForegroundColor Yellow
}

# =============================================================================
# SECTION 3: MODULE LOADING AND CONFIGURATION
# =============================================================================

# PSReadLine: For better command history and auto-completion
Import-Module PSReadLine

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineOption -HistorySearchCursorMovesToEnd


# Terminal Icons: For better file/folder visualization
Import-Module -Name Terminal-Icons

# PowerToys CommandNotFound: For better command not found error messages
Import-Module -Name Microsoft.WinGet.CommandNotFound

# =============================================================================
# SECTION 4: OH-MY-POSH THEME CONFIGURATION
# =============================================================================

# Oh-My-Posh Theme Configuration
try {
    # Smart theme detection based on terminal type and environment
    $themePaths = @()
    
    # Add custom theme paths first (highest priority)
    $themePaths += @(
        "$env:USERPROFILE\AppData\Local\Programs\oh-my-posh\themes\ohmytheme.omp.json",
        "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\ohmytheme.omp.json"
    )
    
    # Add POSH_THEMES_PATH themes (if available)
    if ($env:POSH_THEMES_PATH) {
        $themePaths += @(
            "$env:POSH_THEMES_PATH\ohmytheme.omp.json",
            "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json",
            "$env:POSH_THEMES_PATH\agnoster.omp.json"
        )
    }
    
    # Add fallback themes
    $themePaths += @(
        "C:\Program Files (x86)\oh-my-posh\themes\jandedobbeleer.omp.json",
        "C:\Program Files (x86)\oh-my-posh\themes\agnoster.omp.json"
    )
    
    $script:foundTheme = $null
    $terminalType = if ($env:WT_SESSION) { "Windows Terminal" } elseif ($env:TERM_PROGRAM -eq "vscode") { "VSCode Terminal" } else { "Other" }
    
    Write-Host "Detecting theme for: $terminalType" -ForegroundColor Cyan
    
    foreach ($path in $themePaths) {
        if (Test-Path $path) {
            $script:foundTheme = $path
            break
        }
    }
    
    if ($script:foundTheme) {
        oh-my-posh init pwsh --config $script:foundTheme | Invoke-Expression
        Write-Host "Theme loaded: $script:foundTheme" -ForegroundColor Green
    } else {
        Write-Host "No theme found, using basic prompt..." -ForegroundColor Yellow
        # Fallback to basic prompt if no theme found
        function prompt {
            $location = Get-Location
            $host.UI.RawUI.WindowTitle = "PowerShell - $location"
            "PS $location> "
        }
    }
} catch {
    Write-Host "Oh-My-Posh theme loading failed, using basic prompt..." -ForegroundColor Yellow
    # Fallback to basic prompt if Oh-My-Posh fails
    function prompt {
        $location = Get-Location
        $host.UI.RawUI.WindowTitle = "PowerShell - $location"
        "PS $location> "
    }
}

# =============================================================================
# SECTION 5: ALIASES AND SHORTCUTS
# =============================================================================

# Basic aliases
Set-Alias ll ls

# File and directory functions
function la { Get-ChildItem -Force }
function lla { Get-ChildItem -Force | Format-Wide }
function lt { Get-ChildItem | Sort-Object LastWriteTime -Descending }
function ld { Get-ChildItem -Directory }
function lf { Get-ChildItem -File }

# Navigation functions
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
function ~ { Set-Location $env:USERPROFILE }

# Git aliases (if you use git)
# Note: Some git aliases are commented out due to PowerShell conflicts
# Set-Alias -Name gs -Value "git status"                     # Git status
# Set-Alias -Name ga -Value "git add"                        # Git add
# Set-Alias -Name gcm -Value "git commit"                    # Git commit
# Set-Alias -Name gpush -Value "git push"                    # Git push
# Set-Alias -Name gpull -Value "git pull"                    # Git pull
# Set-Alias -Name gco -Value "git checkout"                  # Git checkout
# Set-Alias -Name gb -Value "git branch"                     # Git branch

# System and process functions
function ps { Get-Process }
function top { Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 }

# Network functions
function ip { Get-NetIPAddress }

# Utility functions
function which { Get-Command }

# Additional navigation functions
function desk { Set-Location ~\Desktop }
function docs { Set-Location ~\Documents }
function dwn { Set-Location ~\Downloads }
function dev { Set-Location ~\Desktop\development }

# File operations
function md { New-Item -ItemType Directory }
function mkcd { 
    param([string]$DirectoryName)
    New-Item -ItemType Directory -Name $DirectoryName
    Set-Location $DirectoryName
}

# Quick access functions
function cls { Clear-Host }
function h { Get-History }
function hc { Clear-History }

# =============================================================================
# SECTION 6: ENVIRONMENT MANAGEMENT (VENV & NODE)
# =============================================================================

# A single, reusable function to activate a Python virtual environment if found.
# This avoids re-activating if the environment is already active.
function Enter-VenvIfNeeded {
    # Define the possible venv directory names
    $venvDirNames = '.venv', 'venv'
    $currentPath = $PWD.Path

    # Find the first venv directory that exists in the current location
    $venvPath = $venvDirNames | ForEach-Object { Join-Path $currentPath $_ } | Where-Object { Test-Path $_ -PathType Container } | Select-Object -First 1

    # If no venv directory was found, do nothing.
    if (-not $venvPath) { return }

    # CRITICAL: If we are already in this specific virtual environment, do nothing.
    # This prevents spamming "Virtual environment activated" messages on every cd within the project.
    if ($env:VIRTUAL_ENV -and ($env:VIRTUAL_ENV -eq $venvPath)) {
        return
    }

    # Construct the path to the activation script
    $activateScript = Join-Path -Path $venvPath -ChildPath "Scripts\Activate.ps1"

    # If the script exists, activate (source) it.
    if (Test-Path $activateScript) {
        . $activateScript
        Write-Host "Virtual environment activated from '$venvPath'." -ForegroundColor Green
    }
}

# --- VIRTUAL ENVIRONMENT AUTO-ACTIVATION ---

# 1. Handle the "IDE startup" case: Check for a venv upon profile load.
Enter-VenvIfNeeded

# 2. Handle interactive navigation: Enhance 'cd' to check for a venv on every location change.
function Invoke-EnhancedCd {
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Path
    )
    
    # Use the original Set-Location cmdlet to avoid recursion
    Microsoft.PowerShell.Management\Set-Location -Path $Path

    # After changing location, check if we need to activate a venv.
    Enter-VenvIfNeeded
}

# Replace the 'cd' alias with our enhanced function
if (Get-Alias -Name cd -ErrorAction SilentlyContinue) {
    Remove-Item Alias:cd -Force
}
Set-Alias -Name cd -Value Invoke-EnhancedCd

# --- NODE.JS VERSION MANAGEMENT ---

# A function to explicitly set the node version for the current directory using FNM
function Set-NodeVersion {
    if (-not (Get-Command fnm -ErrorAction SilentlyContinue)) {
        Write-Host "fnm is not installed or not in your PATH." -ForegroundColor Red
        return
    }
    
    # Check if .node-version file exists
    if (Test-Path ".node-version") {
        # Set the Node version for current directory
        fnm use
        
        # Then apply the environment changes
        $envOutput = fnm env --shell powershell
        if ($envOutput) {
            $envOutput | Invoke-Expression
            Write-Host "Node version environment updated." -ForegroundColor Green
        } else {
            Write-Host "Failed to update Node environment." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No .node-version file found in current directory." -ForegroundColor Yellow
        Write-Host "Available Node versions:" -ForegroundColor Cyan
        fnm list
        Write-Host "`nTo set a Node version, use: fnm use <version>" -ForegroundColor Cyan
    }
}
Set-Alias snv Set-NodeVersion

# =============================================================================
# SECTION 7: AUTO-COMPLETION REGISTRATIONS
# =============================================================================

# Register winget completion
Register-ArgumentCompleter -Native -CommandName winget -ScriptBlock {
    param($wordToComplete, $commandAst, $cursorPosition)
    [Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding = [System.Text.UTF8Encoding]::new()
    $Local:word = $wordToComplete.Replace('"', '""')
    $Local:ast = $commandAst.ToString().Replace('"', '""')
    winget complete --word="$Local:word" --commandline "$Local:ast" --position $cursorPosition | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}

# Docker completion (if Docker is available)
if (Get-Command docker -ErrorAction SilentlyContinue) {
    Register-ArgumentCompleter -Native -CommandName docker -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        try {
            docker completion powershell | Invoke-Expression
        } catch {
            # Fallback to basic completion
        }
    }
}

# =============================================================================
# SECTION 8: KEY BINDINGS AND SHORTCUTS
# =============================================================================

# History search with arrow keys
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

# F7 - Show command history in grid view
Set-PSReadLineKeyHandler -Key F7 `
    -BriefDescription Get-History `
    -LongDescription 'Show command history' `
    -ScriptBlock {
    $pattern = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$pattern, [ref]$null)
    if ($pattern) {
        $pattern = [regex]::Escape($pattern)
    }

    $history = [System.Collections.ArrayList]@(
        $last = ''
        $lines = ''
        foreach ($line in [System.IO.File]::ReadLines((Get-PSReadLineOption).HistorySavePath)) {
            if ($line.EndsWith('`')) {
                $line = $line.Substring(0, $line.Length - 1)
                $lines = if ($lines) {
                    "$lines`n$line"
                } else {
                    $line
                }
                continue
            }

            if ($lines) {
                $line = "$lines`n$line"
                $lines = ''
            }

            if (($line -cne $last) -and (!$pattern -or ($line -match $pattern))) {
                $last = $line
                $line
            }
        }
    )
    $history.Reverse()

    $command = $history | Out-GridView -Title Get-History -Passthru
    if ($command) {
        [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert(($command -join "`n"))
    }
}

# Ctrl+d,Ctrl+c - Capture screen
Set-PSReadLineKeyHandler -Chord 'Ctrl+d,Ctrl+c' -Function CaptureScreen

# Ctrl+b - Build current directory (macro example)
Set-PSReadLineKeyHandler -Key Ctrl+b `
    -BriefDescription BuildCurrentDirectory `
    -LongDescription "Build the current directory" `
    -ScriptBlock {
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert("msbuild")
    [Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}



# Tab completion is handled automatically in Windows mode
# Windows mode already provides standard Ctrl+C/Ctrl+V clipboard functionality

# Word movement bindings
Set-PSReadLineKeyHandler -Key Alt+d -Function ShellKillWord
Set-PSReadLineKeyHandler -Key Alt+Backspace -Function ShellBackwardKillWord
Set-PSReadLineKeyHandler -Key Alt+b -Function ShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+f -Function ShellForwardWord
Set-PSReadLineKeyHandler -Key Alt+B -Function SelectShellBackwardWord
Set-PSReadLineKeyHandler -Key Alt+F -Function SelectShellForwardWord

# =============================================================================
# SECTION 9: SMART INSERT/DELETE FUNCTIONS
# =============================================================================

# Smart quote insertion
Set-PSReadLineKeyHandler -Key '"', "'" `
    -BriefDescription SmartInsertQuote `
    -LongDescription "Insert paired quotes if not already on a quote" `
    -ScriptBlock {
    param($key, $arg)

    $quote = $key.KeyChar

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    # If text is selected, just quote it without any smarts
    if ($selectionStart -ne -1) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $quote + $line.Substring($selectionStart, $selectionLength) + $quote)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
        return
    }

    $ast = $null
    $tokens = $null
    $parseErrors = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$parseErrors, [ref]$null)

    $token = Find-TokenInPSReadLine $tokens $cursor

    # If we're on or inside a **quoted** string token (so not generic), we need to be smarter
    if ($token -is [StringToken] -and $token.Kind -ne [TokenKind]::Generic) {
        # If we're at the start of the string, assume we're inserting a new string
        if ($token.Extent.StartOffset -eq $cursor) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote ")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }

        # If we're at the end of the string, move over the closing quote if present.
        if ($token.Extent.EndOffset -eq ($cursor + 1) -and $line[$cursor] -eq $quote) {
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
            return
        }
    }

    if ($null -eq $token -or
        $token.Kind -eq [TokenKind]::RParen -or $token.Kind -eq [TokenKind]::RCurly -or $token.Kind -eq [TokenKind]::RBracket) {
        if ($line[0..$cursor].Where{ $_ -eq $quote }.Count % 2 -eq 1) {
            # Odd number of quotes before the cursor, insert a single quote
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
        } else {
            # Insert matching quotes, move cursor to be in between the quotes
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$quote$quote")
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
        }
        return
    }

    # If cursor is at the start of a token, enclose it in quotes.
    if ($token.Extent.StartOffset -eq $cursor) {
        if ($token.Kind -eq [TokenKind]::Generic -or $token.Kind -eq [TokenKind]::Identifier -or
            $token.Kind -eq [TokenKind]::Variable -or $token.TokenFlags.hasFlag([TokenFlags]::Keyword)) {
            $end = $token.Extent.EndOffset
            $len = $end - $cursor
            [Microsoft.PowerShell.PSConsoleReadLine]::Replace($cursor, $len, $quote + $line.Substring($cursor, $len) + $quote)
            [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($end + 2)
            return
        }
    }

    # We failed to be smart, so just insert a single quote
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($quote)
}

# Smart brace insertion
Set-PSReadLineKeyHandler -Key '(', '{', '[' `
    -BriefDescription InsertPairedBraces `
    -LongDescription "Insert matching braces" `
    -ScriptBlock {
    param($key, $arg)

    $closeChar = switch ($key.KeyChar) {
        '(' { [char]')'; break }
        '{' { [char]'}'; break }
        '[' { [char]']'; break }
    }

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($selectionStart -ne -1) {
        # Text is selected, wrap it in brackets
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, $key.KeyChar + $line.Substring($selectionStart, $selectionLength) + $closeChar)
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
        # No text is selected, insert a pair
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)$closeChar")
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    }
}

# Smart brace closing
Set-PSReadLineKeyHandler -Key ')', ']', '}' `
    -BriefDescription SmartCloseBraces `
    -LongDescription "Insert closing brace or skip" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($line[$cursor] -eq $key.KeyChar) {
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($cursor + 1)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("$($key.KeyChar)")
    }
}

# Smart backspace
Set-PSReadLineKeyHandler -Key Backspace `
    -BriefDescription SmartBackspace `
    -LongDescription "Delete previous character or matching quotes/parens/braces" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -gt 0) {
        $toMatch = $null
        if ($cursor -lt $line.Length) {
            switch ($line[$cursor]) {
                '"' { $toMatch = '"'; break }
                "'" { $toMatch = "'"; break }
                ')' { $toMatch = '('; break }
                ']' { $toMatch = '['; break }
                '}' { $toMatch = '{'; break }
            }
        }

        if ($toMatch -ne $null -and $line[$cursor - 1] -eq $toMatch) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 1, 2)
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::BackwardDeleteChar($key, $arg)
        }
    }
}

# =============================================================================
# SECTION 10: ADVANCED KEY BINDINGS
# =============================================================================

# Alt+w - Save current line in history but do not execute
Set-PSReadLineKeyHandler -Key Alt+w `
    -BriefDescription SaveInHistory `
    -LongDescription "Save current line in history but do not execute" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    [Microsoft.PowerShell.PSConsoleReadLine]::AddToHistory($line)
    [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
}

# Ctrl+Shift+V - Paste as here string  
Set-PSReadLineKeyHandler -Key Ctrl+Shift+V `
    -BriefDescription PasteAsHereString `
    -LongDescription "Paste the clipboard text as a here string" `
    -ScriptBlock {
    param($key, $arg)

    Add-Type -Assembly PresentationCore
    if ([System.Windows.Clipboard]::ContainsText()) {
        # Get clipboard text - remove trailing spaces, convert \r\n to \n, and remove the final \n.
        $text = ([System.Windows.Clipboard]::GetText() -replace "\p{Zs}*`r?`n", "`n").TrimEnd()
        [Microsoft.PowerShell.PSConsoleReadLine]::Insert("@'`n$text`n'@")
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
    }
}

# Alt+( - Parenthesize selection
Set-PSReadLineKeyHandler -Key 'Alt+(' `
    -BriefDescription ParenthesizeSelection `
    -LongDescription "Put parenthesis around the selection or entire line and move the cursor to after the closing parenthesis" `
    -ScriptBlock {
    param($key, $arg)

    $selectionStart = $null
    $selectionLength = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetSelectionState([ref]$selectionStart, [ref]$selectionLength)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)
    if ($selectionStart -ne -1) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace($selectionStart, $selectionLength, '(' + $line.Substring($selectionStart, $selectionLength) + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($selectionStart + $selectionLength + 2)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(0, $line.Length, '(' + $line + ')')
        [Microsoft.PowerShell.PSConsoleReadLine]::EndOfLine()
    }
}

# Alt+' - Toggle quote argument
Set-PSReadLineKeyHandler -Key "Alt+'" `
    -BriefDescription ToggleQuoteArgument `
    -LongDescription "Toggle quotes on the argument under the cursor" `
    -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $tokenToChange = $null
    foreach ($token in $tokens) {
        $extent = $token.Extent
        if ($extent.StartOffset -le $cursor -and $extent.EndOffset -ge $cursor) {
            $tokenToChange = $token

            # If the cursor is at the end (it's really 1 past the end) of the previous token,
            # we only want to change the previous token if there is no token under the cursor
            if ($extent.EndOffset -eq $cursor -and $foreach.MoveNext()) {
                $nextToken = $foreach.Current
                if ($nextToken.Extent.StartOffset -eq $cursor) {
                    $tokenToChange = $nextToken
                }
            }
            break
        }
    }

    if ($tokenToChange -ne $null) {
        $extent = $tokenToChange.Extent
        $tokenText = $extent.Text
        if ($tokenText[0] -eq '"' -and $tokenText[-1] -eq '"') {
            # Switch to no quotes
            $replacement = $tokenText.Substring(1, $tokenText.Length - 2)
        } elseif ($tokenText[0] -eq "'" -and $tokenText[-1] -eq "'") {
            # Switch to double quotes
            $replacement = '"' + $tokenText.Substring(1, $tokenText.Length - 2) + '"'
        } else {
            # Add single quotes
            $replacement = "'" + $tokenText + "'"
        }

        [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
            $extent.StartOffset,
            $tokenText.Length,
            $replacement)
    }
}

# Alt+% - Expand aliases
Set-PSReadLineKeyHandler -Key "Alt+%" `
    -BriefDescription ExpandAliases `
    -LongDescription "Replace all aliases with the full command" `
    -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $startAdjustment = 0
    foreach ($token in $tokens) {
        if ($token.TokenFlags -band [TokenFlags]::CommandName) {
            $alias = $ExecutionContext.InvokeCommand.GetCommand($token.Extent.Text, 'Alias')
            if ($alias -ne $null) {
                $resolvedCommand = $alias.ResolvedCommandName
                if ($resolvedCommand -ne $null) {
                    $extent = $token.Extent
                    $length = $extent.EndOffset - $extent.StartOffset
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $extent.StartOffset + $startAdjustment,
                        $length,
                        $resolvedCommand)

                    # Our copy of the tokens won't have been updated, so we need to
                    # adjust by the difference in length
                    $startAdjustment += ($resolvedCommand.Length - $length)
                }
            }
        }
    }
}

# F1 - Command help
Set-PSReadLineKeyHandler -Key F1 `
    -BriefDescription CommandHelp `
    -LongDescription "Open the help window for the current command" `
    -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $tokens = $null
    $errors = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$tokens, [ref]$errors, [ref]$cursor)

    $commandAst = $ast.FindAll({
            $node = $args[0]
            $node -is [CommandAst] -and
            $node.Extent.StartOffset -le $cursor -and
            $node.Extent.EndOffset -ge $cursor
        }, $true) | Select-Object -Last 1

    if ($commandAst -ne $null) {
        $commandName = $commandAst.GetCommandName()
        if ($commandName -ne $null) {
            $command = $ExecutionContext.InvokeCommand.GetCommand($commandName, 'All')
            if ($command -is [AliasInfo]) {
                $commandName = $command.ResolvedCommandName
            }

            if ($commandName -ne $null) {
                Get-Help $commandName -ShowWindow
            }
        }
    }
}

# =============================================================================
# SECTION 11: COMMAND VALIDATION AND AUTO-CORRECTION
# =============================================================================

# Auto correct 'git cmt' to 'git commit'
Set-PSReadLineOption -CommandValidationHandler {
    param([CommandAst]$CommandAst)

    switch ($CommandAst.GetCommandName()) {
        'git' {
            $gitCmd = $CommandAst.CommandElements[1].Extent
            switch ($gitCmd.Text) {
                'cmt' {
                    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
                        $gitCmd.StartOffset, $gitCmd.EndOffset - $gitCmd.StartOffset, 'commit')
                }
            }
        }
    }
}

# Enhanced right arrow behavior
Set-PSReadLineKeyHandler -Key RightArrow `
    -BriefDescription ForwardCharAndAcceptNextSuggestionWord `
    -LongDescription "Move cursor one character to the right in the current editing line and accept the next word in suggestion when it's at the end of current editing line" `
    -ScriptBlock {
    param($key, $arg)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    if ($cursor -lt $line.Length) {
        [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar($key, $arg)
    } else {
        [Microsoft.PowerShell.PSConsoleReadLine]::AcceptNextSuggestionWord($key, $arg)
    }
}

# Alt+a - Select command arguments
Set-PSReadLineKeyHandler -Key Alt+a `
    -BriefDescription SelectCommandArguments `
    -LongDescription "Set current selection to next command argument in the command line. Use of digit argument selects argument by position" `
    -ScriptBlock {
    param($key, $arg)

    $ast = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$ast, [ref]$null, [ref]$null, [ref]$cursor)

    $asts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ExpressionAst] -and
            $args[0].Parent -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].Extent.StartOffset -ne $args[0].Parent.Extent.StartOffset
        }, $true)

    if ($asts.Count -eq 0) {
        [Microsoft.PowerShell.PSConsoleReadLine]::Ding()
        return
    }

    $nextAst = $null

    if ($null -ne $arg) {
        $nextAst = $asts[$arg - 1]
    } else {
        foreach ($ast in $asts) {
            if ($ast.Extent.StartOffset -ge $cursor) {
                $nextAst = $ast
                break
            }
        }

        if ($null -eq $nextAst) {
            $nextAst = $asts[0]
        }
    }

    $startOffsetAdjustment = 0
    $endOffsetAdjustment = 0

    if ($nextAst -is [System.Management.Automation.Language.StringConstantExpressionAst] -and
        $nextAst.StringConstantType -ne [System.Management.Automation.Language.StringConstantType]::BareWord) {
        $startOffsetAdjustment = 1
        $endOffsetAdjustment = 2
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::SetCursorPosition($nextAst.Extent.StartOffset + $startOffsetAdjustment)
    [Microsoft.PowerShell.PSConsoleReadLine]::SetMark($null, $null)
         [Microsoft.PowerShell.PSConsoleReadLine]::SelectForwardChar($null, ($nextAst.Extent.EndOffset - $nextAst.Extent.StartOffset) - $endOffsetAdjustment)
}

# Alt+x - Unicode character input
Set-PSReadLineKeyHandler -Chord 'Alt+x' `
    -BriefDescription ToUnicodeChar `
    -LongDescription "Transform Unicode code point into a UTF-16 encoded string" `
    -ScriptBlock {
    $buffer = $null
    $cursor = 0
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref] $buffer, [ref] $cursor)
    if ($cursor -lt 4) {
        return
    }

    $number = 0
    $isNumber = [int]::TryParse(
        $buffer.Substring($cursor - 4, 4),
        [System.Globalization.NumberStyles]::AllowHexSpecifier,
        $null,
        [ref] $number)

    if (-not $isNumber) {
        return
    }

    try {
        $unicode = [char]::ConvertFromUtf32($number)
    } catch {
        return
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::Delete($cursor - 4, 4)
    [Microsoft.PowerShell.PSConsoleReadLine]::Insert($unicode)
}

# =============================================================================
# SECTION 13: EXTERNAL TOOLS INTEGRATION
# =============================================================================



# Fast Node Manager (fnm) integration 
# NOTE: --use-on-cd flag disabled for performance (was causing slowdowns)
# To manually switch Node versions, use: fnm use <version>
# fnm env --use-on-cd --shell power-shell | Out-String | Invoke-Expression

# =============================================================================
# SECTION 13.5: COMMUNITY MODULES (OPTIONAL)
# =============================================================================

# Uncomment the following lines to enable popular community modules
# These modules enhance the PowerShell experience significantly

# z - Smart directory jumping (tracks most used directories)
# Install with: Install-Module z -Scope CurrentUser
# Import-Module z

# PSFzf - Fuzzy finder for PowerShell (replaces Out-GridView with fast fuzzy search)
# Install with: Install-Module PSFzf -Scope CurrentUser
# Import-Module PSFzf
# Set-PsFzfOption -TabExpansion

# =============================================================================
# SECTION 14: CUSTOM FUNCTIONS AND UTILITIES
# =============================================================================

# Private helper function for PSReadLine token finding (used in SmartInsertQuote)
function Find-TokenInPSReadLine {
    param($tokens, $cursor)

    foreach ($token in $tokens) {
        if ($cursor -lt $token.Extent.StartOffset) { continue }
        if ($cursor -lt $token.Extent.EndOffset) {
            $result = $token
            $token = $token -as [StringExpandableToken]
            if ($token) {
                $nested = Find-TokenInPSReadLine $token.NestedTokens $cursor
                if ($nested) { $result = $nested }
            }

            return $result
        }
    }
    return $null
}

# Function to show profile information
function Show-ProfileInfo {
    Write-Host "=== PowerShell Profile Information ===" -ForegroundColor Cyan
    Write-Host "Profile Path: $PROFILE" -ForegroundColor Yellow
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Yellow
    Write-Host "OS: $($PSVersionTable.OS)" -ForegroundColor Yellow
    Write-Host "Current Theme: $script:foundTheme" -ForegroundColor Yellow
    # Check current virtual environment
    $currentVenv = if ($env:VIRTUAL_ENV) { Split-Path $env:VIRTUAL_ENV -Leaf } else { "None" }
    Write-Host "Virtual Environment: $currentVenv" -ForegroundColor Yellow
    Write-Host "Directory Marks: $($global:PSReadLineMarks.Count)" -ForegroundColor Yellow
}

# Function to reload profile
function Update-Profile {
    Write-Host "Reloading PowerShell profile..." -ForegroundColor Green
    . $PROFILE
    Write-Host "Profile reloaded successfully!" -ForegroundColor Green
}

# Function to backup profile
function New-Backup-Profile {
    $backupPath = "$env:USERPROFILE\Documents\PowerShell\profile_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
    Copy-Item $PROFILE $backupPath
    Write-Host "Profile backed up to: $backupPath" -ForegroundColor Green
}

# Function to show available aliases and functions
function Show-MyAliases {
    Write-Host "=== Custom Aliases and Functions ===" -ForegroundColor Cyan
    
    Write-Host "`n--- Aliases ---" -ForegroundColor Yellow
    # Filter for aliases pointing to functions or simple commands you've likely set
    Get-Alias | Where-Object { 
        $_.Definition -match '^(Show-ProfileInfo|Update-Profile|New-Backup-Profile|Invoke-EnhancedCd|Get-ChildItem)' -or
        $_.Source -notlike 'App_*' # Exclude built-in aliases
    } | Sort-Object Name | Format-Table -AutoSize

    Write-Host "`n--- Custom Functions ---" -ForegroundColor Yellow
    # Get all functions that are not from a system module
    Get-Command -CommandType Function | Where-Object { $_.Module -eq $null } | Select-Object Name, Source | Format-Table -AutoSize
}

# Set aliases for utility functions
Set-Alias -Name profile-info -Value Show-ProfileInfo
Set-Alias -Name reload -Value Update-Profile
Set-Alias -Name backup-profile -Value New-Backup-Profile
Set-Alias -Name my-aliases -Value Show-MyAliases

# =============================================================================
# SECTION 15: WELCOME MESSAGE
# =============================================================================

# Show welcome message only on first load
if (-not $global:ProfileLoaded) {
    Write-Host "=== Welcome to Enhanced PowerShell! ===" -ForegroundColor Green
    Write-Host "Type 'profile-info' to see profile information" -ForegroundColor Yellow
    Write-Host "Type 'my-aliases' to see custom aliases" -ForegroundColor Yellow
    Write-Host "Type 'reload' to reload the profile" -ForegroundColor Yellow
    Write-Host "Type 'backup-profile' to backup the profile" -ForegroundColor Yellow
    Write-Host "Type 'snv' to set Node version for current directory" -ForegroundColor Yellow
    Write-Host "Key Shortcuts: Ctrl+b (build), Alt+x (Unicode), Ctrl+Shift+V (here string)" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Green
    $global:ProfileLoaded = $true
}