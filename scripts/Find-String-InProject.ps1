$searchPattern = $args[0]

Get-ChildItem -Path ./src -Recurse -File | 
Where-Object { $_.Extension -notin @('.exe', '.dll', '.bin', '.obj', '.pdb') } | 
Select-String -Pattern $searchPattern