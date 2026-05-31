param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]] $ScraperArgs
)

$ErrorActionPreference = "Stop"

function Test-RealPython {
    param([string] $Command)

    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if (-not $cmd) {
        return $null
    }

    $source = [string] $cmd.Source
    if ($source -like "*\WindowsApps\python*.exe") {
        return $null
    }

    try {
        & $source -c "import sys; print(sys.executable)" *> $null
        if ($LASTEXITCODE -eq 0) {
            return $source
        }
    }
    catch {
        return $null
    }

    return $null
}

$python = Test-RealPython "python"
if (-not $python) {
    $python = Test-RealPython "python3"
}

if (-not $python) {
    throw "Could not find a real Python executable. Install Python 3, then run: python -m pip install -r requirements.txt"
}

& $python "$PSScriptRoot\scrape_ieltsbro.py" @ScraperArgs
