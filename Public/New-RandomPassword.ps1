function New-RandomPassword {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateRange(8, 128)]
        [int]$Length = 16,
        
        [Parameter()]
        [switch]$IncludeSpecialChars
    )
    
    $charSet = @{
        Standard = 'abcdefghkmnprstuvwxyzABCDEFGHKLMNPRSTUVWXYZ123456789'
        Special = '!@#$%^&*'
    }
    
    # Using array instead of string concatenation
    $chars = if ($IncludeSpecialChars) {
        $charSet.Standard, $charSet.Special -join ''
    }
    else {
        $charSet.Standard
    }
    
    try {
        $bytes = [byte[]]::new($Length)
        $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
        $rng.GetBytes($bytes)
        
        $password = [System.Text.StringBuilder]::new($Length)
        foreach ($i in 0..($Length - 1)) {
            $null = $password.Append($chars[$bytes[$i] % $chars.Length])
        }
        
        return $password.ToString()
    }
    catch {
        Write-Error "Failed to generate password: $_"
    }
    finally {
        if ($rng) {
            $rng.Dispose()
        }
    }
}