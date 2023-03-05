Clear-Host

<#
Applepie: An 8x8 grid of shifting data horisontally and vertically to encrypt/scramble data

1) Comments. Lots and lots of comments so anyone can easily understand what is going on
2) Avoid division at all costs. PowerShell is already kind of a slow language and division costs a lot of CPU power
3) Avoid floating points at all costs. Sometimes it's neccesary though for things like square root
4) Strongly defined data types, i.e. no accidental casting from byte to integer. Casting to string is unavoidable though
5) No external modules allowed
6) No Secure-String allowed because it only works on Windows
#>

[string]$password = 'sn0wf1ake1'
$password += ($password.ToUpper() + $password.ToLower()) + $password.Length # Add entropy
[object]$password_hashed = [IO.MemoryStream]::new([byte[]][char[]]$password) # SHA encoding start by casting it to on object
[string]$password_hashed = [System.Convert]::ToString((Get-FileHash -InputStream $password_hashed -Algorithm SHA512)) # The SHA encoding here
[string]$password_base64 = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($password_hashed)) + $password_hashed # Universal welldocumented format automatically also adds another twist
[string]$password_number = $null
[array]$table_reverse = @(7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0) # Loop sequence for the 8x8 table
[byte]$x,$y,$z = 0

for([int]$i = 0; $i -lt 377; $i++) { # 377 because result is fixed length. Code needs to be rewritten
    $password_number += [byte][char]$password_base64[$i]
}

$password = $password_number.Replace('0',3).Replace('8',5).Replace('9',7) # 0,8,9 are "dumb" numbers so at least put them to good use

<# Test and debug data start #>
$password
$password.Length
#break

function display_grid {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )

    Write-Host (($data[0..7] -join ' ') + "`n" +
                ($data[8..15] -join ' ') + "`n" +
                ($data[16..23] -join ' ') + "`n" +
                ($data[24..31] -join ' ') + "`n" +
                ($data[32..39] -join ' ') + "`n" +
                ($data[40..47] -join ' ') + "`n" +
                ($data[48..55] -join ' ') + "`n" +
                ($data[56..63] -join ' '))
}

[array]$data = ('A','B','C','D','E','F','G','H',
                'I','J','K','L','M','N','O','P',
                'Q','R','S','T','U','V','W','X',
                'Y','Z','Æ','Ø','Å','1','2','3',
                '4','5','6','7','8','9','0','a',
                'b','c','d','e','f','g','h','i',
                'j','k','l','m','n','o','p','q',
                'r','s','t','u','v','w','x','y')
<# End #>

function shift_horizontal {
    param(
        [Parameter(Mandatory = $true)] [byte]$row,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    [array]$data_temp = $null # Clean shop
    [byte]$j = 0

    $data_temp = $data[($row * 8)..($row * 8 + 7)]
    $data_temp = $data_temp[$shifts..7] + $data_temp

    for([byte]$i = $row * 8; $i -le $row * 8 + 7; $i++) {
        $data[$i] = $data_temp[$j]
        $j++
    }

    Write-Host ("`n" + 'Horizontal  ' + $row + ' ' + $shifts)
    display_grid $data
}

function shift_vertical {
    param(
        [Parameter(Mandatory = $true)] [byte]$column,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    [array]$data_temp = $null # Clean shop
    [byte]$j = 0

    for([byte]$i = 0; $i -le 7; $i++) {
        $data_temp += $data[$i * 8 + $column]
    }

    $data_temp = $data_temp[$shifts..7] + $data_temp
    for($i = 0; $i -le 7; $i++) {
        $data[$i * 8 + $column] = $data_temp[$j]
        $j++
    }

    Write-Host ("`n" + 'Vertical    ' + $column + ' ' + $shifts)
    display_grid $data
}

function applepie {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )
    [byte]$x,$y = 0

    for([byte]$i = 0; $i -le 15; $i++) {
        [byte]$z = $password.Substring($i,1)

        if($i % 2 -eq 0) {
            shift_horizontal $x $z
            $x++
            } else {
            shift_vertical $y $z
            $y++
        }
    }
}

applepie $data

<# Decoding #>
Write-Host ("`n" + '---')

function applepie_reverse {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )

    for([byte]$i = 0; $i -le 15; $i++) {
        [byte]$x = $table_reverse[$i]
        [byte]$y = 8 - $password.Substring(15 - $i,1)

        if($i % 2 -eq 0) {
            shift_vertical $x $y
            } else {
            shift_horizontal $x $y
        }
    }
}

applepie_reverse $data
