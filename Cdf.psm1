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

function Get-Choice([Parameter(Mandatory=$true)] [string[]] $items, [bool] $hasPrompt){
    $choice = 0
    $pageHeight = [System.Console]::BufferHeight, 10 | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
    $maxPage = [Math]::Ceiling($items.Length / $pageHeight)-1
    $currentPage = 0
    try {
        [System.Console]::CursorVisible = $false
        $currentPageItems = $items[($currentPage * $pageHeight)..(($currentPage + 1) * $pageHeight - 1)]
        Write-ItemLines $currentPageItems $choice
        Write-Host -ForegroundColor ([System.ConsoleColor]::DarkYellow) "Page $($currentPage + 1)/$($maxPage + 1)"
        while($true) {
            $press = [System.Console]::ReadKey()
            if ($press.Key -eq [System.ConsoleKey]::UpArrow) {
                $choice = ($choice - 1), 0 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
            } elseif ($press.Key -eq [System.ConsoleKey]::DownArrow) {
                $choice = ($choice + 1), ($items.Count - 1) | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
            } elseif ($press.Key -eq [System.ConsoleKey]::RightArrow) {
                $currentPage = ($currentPage + 1), $maxPage | Measure-Object -Minimum | Select-Object -ExpandProperty Minimum
                $choice = 0
            } elseif ($press.Key -eq [System.ConsoleKey]::LeftArrow) {
                $currentPage = ($currentPage - 1), 0 | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
                $choice = 0
            }

            if ($press.Key -eq [System.ConsoleKey]::Escape) {
                return $null
            } elseif ($press.Key -eq [System.ConsoleKey]::Enter) {
                return $currentPageItems[$choice]
            } else {
                Clear-LinesAbove ($currentPageItems.Length + 1)
                $currentPageItems = $items[($currentPage * $pageHeight)..(($currentPage + 1) * $pageHeight - 1)]
                Write-ItemLines $currentPageItems $choice
                Write-Host -ForegroundColor ([System.ConsoleColor]::DarkYellow) "Page $($currentPage + 1)/$($maxPage + 1)"
            }
        }
    } finally {
        Clear-LinesAbove ($pageHeight + 1 + $hasPrompt)
        [System.Console]::CursorVisible = $true
    }
}

function Get-PathSegments([string] $path) {
    $parent = Split-Path -LiteralPath $path
    if ([String]::IsNullOrEmpty($parent)) {
        @($path)
    } else {
        $leaf = $path.Substring($parent.Length + 1)
        [string[]] $parentList = Get-PathSegments $parent
        $parentList + @($leaf)
    }
}

function Set-FuzzyDirectory {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true, ValueFromPipeline)] [string] $path)
    $startingPoint = Get-Location
    Get-PathSegments $path | Where-Object {-not [String]::IsNullOrEmpty($_)} | ForEach-Object {
        $levelDir = $_
        if ($levelDir -in @(".", "..")) {
            $levelDir | Set-Location
        } elseif ($levelDir.Contains(":")) {
            Set-Location "$levelDir\"
        } else {
            [String[]] $candidates = & {if ($levelDir -eq "*") { 
                Get-ChildItem -Directory 
                } else {
                    Get-ChildItem -Directory | Where-Object { $_.Name -match $levelDir }
                }} | Select-Object -ExpandProperty Name
            if ($candidates.Length -eq 0) {
                Set-Location $startingPoint
                Set-Location $path
                return
            } elseif ($candidates.Length -eq 1) {
                Set-Location $candidates[0]
            } elseif ($candidates -contains $levelDir) {
                Set-Location $levelDir
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

function Set-CdAlias {
    Set-Item -Path "Alias:cd" -Value "Set-FuzzyDirectory" -Options "AllScope"
}

Export-ModuleMember -Function @("Set-FuzzyDirectory", "Set-CdAlias")
