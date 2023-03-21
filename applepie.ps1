Clear-Host

<#
Applepie: An 11x11 grid of shifting data horisontally and vertically to encrypt/scramble data. 11x11 was chosen because
          an 8x8 grid would ultimately waste the numbers 0,8,9. An 11x11 block only wastes the number 0.

1) Comments. Lots and lots of comments so anyone can easily understand what is going on
2) Avoid division at all costs. PowerShell is already kind of a slow language and division costs a lot of CPU power
3) Avoid floats and decimals at all costs
4) Strongly defined data types, i.e. no accidental casting from byte to integer. Casting to string is unavoidable though
5) No external modules allowed and must work on all platforms supported by PowerShell
#>

[string]$password = 'sn0wf1ake1'
[string]$password_hashed = $null
[object]$password_SHA512 = [IO.MemoryStream]::new([byte[]][char[]]$password) # SHA512 initiation
[string]$password_SHA512 = [System.Convert]::ToString((Get-FileHash -InputStream $password_SHA512 -Algorithm SHA512).Hash) # SHA512 encoding here
[array]$table_applepie = @(0,0,1,1,2,2,3,3,4,4,5,5,6,6,7,7,8,8,9,9,10,10)
[array]$table_applepie_reverse = @(10,10,9,9,8,8,7,7,6,6,5,5,4,4,3,3,2,2,1,1,0,0)
[byte]$x,$y,$z = 0

for([byte]$i = 0; $i -lt 128; $i++) {
    $password_hashed += [byte][char]$password_SHA512[$i]

    if($i -gt 16) {
        $password_hashed += [int]$password_hashed.Substring($i,7) * [int]$password_hashed.Substring($password_hashed.Length - 7,7)
    }
}

$password = $password_hashed.Replace('0',$null)
[string]$password_block = $password.Substring(1,22) # Take 22 digits from the long password because block is 11x11, i.e. 11 + 11 rotations

<# Test and debug data start #>
$password
$password.Length
$password_block
$password_block.Length
#break

[array]$data = ('A','B','C','D','E','F','G','H','§','"','#',
                'I','J','K','L','M','N','O','P','¤','%','&',
                'w','R','S','T','U','V','W','X','/','(',')',
                'Y','Z','Æ','Ø','Å','1','2','3','=','?','`',
                '4','5','6','7','8','9','0','a','§','"','1',
                'b','c','d','e','f','g','h','i','§','"','2',
                'j','k','l','m','n','o','p','q','§','"','3',
                'r','s','t','u','v','w','x','y','§','"','4',
                'A','B','C','D','E','F','G','H','§','"','5',
                'I','J','K','L','M','N','O','P','¤','%','&',
                'x','R','S','T','U','V','W','X','/','(',')')

function display_grid {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )

    Write-Host (($data[0..10] -join ' ') + "`n" +
                ($data[11..21] -join ' ') + "`n" +
                ($data[22..32] -join ' ') + "`n" +
                ($data[33..43] -join ' ') + "`n" +
                ($data[44..54] -join ' ') + "`n" +
                ($data[55..65] -join ' ') + "`n" +
                ($data[66..76] -join ' ') + "`n" +
                ($data[77..87] -join ' ') + "`n" +
                ($data[88..98] -join ' ') + "`n" +
                ($data[99..109] -join ' ') + "`n" +
                ($data[110..121] -join ' '))
}
<# End #>

function shift_horizontal {
    param(
        [Parameter(Mandatory = $true)] [byte]$row,
        [Parameter(Mandatory = $true)] [string]$shifts
    )

    [array]$data_temp = $null # Clean shop
    [byte]$j = 0

    $data_temp = $data[($row * 11)..($row * 11 + 10)]
    $data_temp = $data_temp[$shifts..10] + $data_temp

    for([byte]$i = $row * 11; $i -le $row * 11 + 10; $i++) {
        $data[$i] = $data_temp[$j]
        $j++
    }

    Write-Host ("`nHorizontal        " + $row + ' ' + $shifts)
    display_grid $data
}

function shift_vertical {
    param(
        [Parameter(Mandatory = $true)] [byte]$column,
        [Parameter(Mandatory = $true)] [string]$shifts
    )

    [array]$data_temp = $null # Clean shop
    [byte]$j = 0

    for([byte]$i = 0; $i -le 10; $i++) {
        $data_temp += $data[$i * 11 + $column]
    }

    $data_temp = $data_temp[$shifts..10] + $data_temp
    for($i = 0; $i -le 10; $i++) {
        $data[$i * 11 + $column] = $data_temp[$j]
        $j++
    }

    Write-Host ("`nVertical          " + $column + ' ' + $shifts)
    display_grid $data
}

function applepie {
    for([byte]$i = 0; $i -lt 22; $i++) {
        [byte]$j = $password_block.Substring($i,1)

        if($i % 2 -eq 0) {
            shift_horizontal $table_applepie[$i] $j
            } else {
            shift_vertical $table_applepie[$i] $j
        }
    }
}

Write-Host ("`n--- ENCRYPTION START ---")
applepie
Write-Host ("`n--- ENCRYPTION END ---")
#break

function applepie_reverse {
    for([byte]$i = 1; $i -le 22; $i++) {
        shift_vertical $table_applepie_reverse[$i - 1] (11 - $password_block.Substring(22 - $i,1))
        shift_horizontal $table_applepie_reverse[$i - 1] (11 - $password_block.Substring(21 - $i,1))
        $i++
    }
}

Write-Host ("`n--- DECRYPTION START ---`n")
applepie_reverse
Write-Host ("`n--- DECRYPTION END ---")
