function Write-ItemLines([array] $items, [int] $selectedIndex) {
    0..($items.Count -1) | ForEach-Object {
        Write-Host -NoNewline " "
        if ($_ -eq $selectedIndex) {
            Write-Host -NoNewline -BackgroundColor Magenta -ForegroundColor White "$($items[$_])"
        } else {
            Write-Host -NoNewline "$($items[$_])"
        }
        Write-Host " "
    }
}

function Clear-LinesAbove([int] $numberOfLinesToClear) {
    [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - $numberOfLinesToClear)
    1..$numberOfLinesToClear | ForEach-Object {
        Write-Host "".PadRight([System.Console]::BufferWidth, " ")
    }
    [System.Console]::SetCursorPosition(0, [System.Console]::CursorTop - $numberOfLinesToClear)
}

function Get-Choice([Parameter(Mandatory=$true)] [array] $items, [bool] $hasPrompt){
    $choice = 0
    try {
        [System.Console]::CursorVisible = $false
        Write-ItemLines $items $choice
        while($true) {
            $press = [System.Console]::ReadKey()
            if ($press.Key -eq [System.ConsoleKey]::UpArrow) {
                $choice = ($choice - 1), 0 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
            } elseif ($press.Key -eq [System.ConsoleKey]::DownArrow) {
                $choice = ($choice + 1), ($items.Count - 1) | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
            }
            if ($press.Key -eq [System.ConsoleKey]::Escape) {
                return $null
            } elseif ($press.Key -eq [System.ConsoleKey]::Enter) {
                return $items[$choice]
            } else {
                Clear-LinesAbove ($items.Count)
                Write-ItemLines $items $choice
            }
        }
    } finally {
        Clear-LinesAbove ($items.Count + $hasPrompt)
        [System.Console]::CursorVisible = $true
    }
}

function Set-FuzzyDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true, ValueFromPipeline)] [string] $path)
    $startingPoint = Get-Location
    $path.Split("/").Split("\") | Where-Object {-not [String]::IsNullOrEmpty($_)} | ForEach-Object {
        $levelDir = $_
        if ($levelDir -in @(".", "..")) {
            $levelDir | Set-Location
        } elseif ($levelDir.Contains(":")) {
            Set-Location "$levelDir\"
        } else {
            [String[]] $candidates = Get-ChildItem -Directory | Where-Object { $_.Name -match $levelDir } | Select-Object -ExpandProperty Name
            if ($candidates.Length -eq 0) {
                Set-Location $startingPoint
                Set-Location $path
                return
            } elseif ($candidates.Length -eq 1) {
                Set-Location $candidates[0]
            } else {
                Write-Host -NoNewline "Select next folder "
                Write-Host -NoNewline -ForegroundColor Green "(Current location: $(Get-Location))"
                Write-Host " "
                $choice = Get-Choice $candidates $true
                if ($null -ne $choice) {
                    $choice | Set-Location
                } else {
                    Set-Location $startingPoint
                    Set-Location $path
                    return
                }
            }
        }
    }
}

Export-ModuleMember -Function "Set-FuzzyDirectory"
