Clear-Host

$password = 'sn0wf1ake1'
$password += $password.ToUpper() + $password.ToLower()
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($password))
[string]$x,$y,$z = $null

$password

<# Passcode generation start #>
for($i = 0; $i -lt $password.Length - 2; $i++) {
    $x += [System.Convert]::ToString([math]::Sqrt([byte][char]$password[$i] + [byte][char]$password[$i + 1] + [byte][char]$password[$i + 2]))
    $y += $x.Substring($x.Length / 2)
}

$y = $y -replace "[^0-9]" # Remove all non-digit characters

for($i = 0; $i -lt $y.Length - 2; $i++) {
    $z += [System.Convert]::ToString(([int]$y.Substring($i,2) + [int]$y.Substring($i + 1,2)) + $i % 11) # Additional necessary entropy
}

$z = $z -replace(9,1) # 0 and 8 could technically be dropped but adds to entropy. 9 leaps over so replace it with 1
$password = $z.Substring($z.Length % 16) # Trim to fit in a 16 byte rotations (8 shifts horizontal and 8 shifts vertical)
<# End #>

<# Debug info #>
#$x
#$x.Length
$password
$password.Length
<# End #>

<# Test data start #>
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

$data = ('A','B','C','D','E','F','G','H',
         'I','J','K','L','M','N','O','P',
         'Q','R','S','T','U','V','W','X',
         'Y','Z','Æ','Ø','Å','1','2','3',
         '4','5','6','7','8','9','0','a',
         'b','c','d','e','f','g','h','i',
         'j','k','l','m','n','o','p','q',
         'r','s','t','u','v','w','x','y')

function shift_horizontal {
    param(
        [Parameter(Mandatory = $true)] [byte]$row,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    if($shifts -ne 0 -and $shifts -ne 8) {
        [byte]$j = 0

        $data_temp = $data[($row * 8)..($row * 8 + 7)]
        $data_temp = $data_temp[$shifts..7] + $data_temp

        for($i = $row * 8; $i -le $row * 8 + 7; $i++) {
            $data[$i] = $data_temp[$j]
            $j++
        }
    }
}

function shift_vertical {
    param(
        [Parameter(Mandatory = $true)] [byte]$row,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    if($shifts -ne 0 -and $shifts -ne 8) {
        [array]$data_temp = $null
        [byte]$j = 0
        
        for($i = 0; $i -le 7; $i++) {
            $data_temp += $data[$i * 8 + $row]
        }

        $data_temp = $data_temp[$shifts..7] + $data_temp
        for($i = 0; $i -le 7; $i++) {
            $data[$i * 8 + $row] = $data_temp[$j]
            $j++
        }
    }
}

function applepie {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )
    [byte]$x,$y = 0

    for($i = 0; $i -le 15; $i++) {
        if($i % 2 -eq 0) {
            shift_horizontal $x ([byte]$password.Substring($i,1))
            $x++
            } else {
            shift_vertical $y ([byte]$password.Substring($i,1))
            $y++
        }
    }
}

applepie($data)
display_grid($data)
break
$password[0..15] -join ' '

function applepie_reverse {
    param(
        [Parameter(Mandatory = $true)] [array]$password
    )
    [array]$password_reversed = $null

    for($i = 0; $i -le 15; $i++) {
        $password_reversed += 8 - $password[15 - $i].ToString() # Strangest type conversion ever but necessary. 8 minus to loop back to origin
    }
    $password_reversed -join ' '
}

applepie_reverse($password[0..15])

#$password_temp = [array]::Reverse($password[0..15])
#$password_temp -join ' '
break
<#
Example; if 1 in passcode, shift 7 places (8 - 1 = 7)
1 = 7
2 = 6
3 = 5
4 = 4
5 = 3
6 = 2
7 = 1
#>

shift_horizontal 0 7
shift_horizontal 0 1

display_grid($data)
