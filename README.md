# cdf.ps

Cdf provides the function `Set-FuzzyDirectory` that allows regex parts in the
path and will ask for user feedback in cases of ambiguity, for example:

```powershell
# The following command will try to navigate to a folder that matches
# Us (e.g. Users), and then N (e.g. Name)
> Set-FuzzyDirectory C:\Us\N

# If there is more than one folder, e.g. Name and Name2, a menu will be
# displayed to select a choice
Select next folder (Current location: C:\Users)
 Name
 Name2
```

The menu is navigated using arrow up/down, selection is via the return key. In
cases of abortions (Esc), the location is not changed.
If the path cannot be matched, an attempt to call Set-Location from the starting
directory is issued.

# Aliasing Set-Location
If the module is imported in `$PROFILE`, `cd` can be made to point to
Set-FuzzyDirectory instead of Get-Location:

```powershell
Remove-Alias cd
Set-Alias -Name cd -Value Set-FuzzyDirectory
```

# Other links
- The menu is inspired by https://github.com/chrisseroka/ps-menu
