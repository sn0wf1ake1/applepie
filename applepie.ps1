Clear-Host

[string]$password = 'sn0wf1ake1'
$password += $password.ToUpper() + $password.ToLower() # Add entropy
$password += $password.Length * 7 # Add more entropy. 7 because of highest single digit prime number and no fancy math::PI stuff with weird digit encoding
$password = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($password)) # Universal welldocumented format automatically also adds another twist
[string]$x,$y,$z = $null

$password

<# Passcode generation start #>
for([int]$i = 0; $i -lt $password.Length - 2; $i++) {
    $x += [System.Convert]::ToString([math]::Sqrt([byte][char]$password[$i] + [byte][char]$password[$i + 1] + [byte][char]$password[$i + 2]))
    $y += $x.Substring($x.Length % 11)
}

$y = $y -replace "[^0-9]" # Remove all non-digit characters like "." and "," and spaces

for($i = 0; $i -lt $y.Length - 2; $i++) {
    $z += [System.Convert]::ToString(([byte]$y.Substring($i,2) + [byte]$y.Substring($i + 1,2)) + $i % 11) # Additional necessary entropy
}

# 0 and 8 could technically be dropped but adds to entropy. 9 leaps over so replace it with 1. Replace XXXX numbers with their counterparts X
$z = $z -replace(9,1) -replace(0000,0) -replace(1111,1) -replace(2222,2) -replace(3333,3) -replace(4444,4) -replace(5555,5) -replace(6666,6) -replace(7777,7) -replace(8888,8)
$password = $z.Substring($z.Length % 16) # Trim to fit in a 16 byte rotations (8 shifts horizontal and 8 shifts vertical)
<# End #>

<# Debug info #>
$password
$password.Length
break
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

[array]$data = ('A','B','C','D','E','F','G','H',
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

    if($shifts % 8 -ne 0) {
        [byte]$j = 0

        $data_temp = $data[($row * 8)..($row * 8 + 7)]
        $data_temp = $data_temp[$shifts..7] + $data_temp

        for([byte]$i = $row * 8; $i -le $row * 8 + 7; $i++) {
            $data[$i] = $data_temp[$j]
            $j++
        }
    }

    Write-Host ("`n" + 'Horizontal  ' + $row + ' ' + $shifts)
    display_grid($data)
}

function shift_vertical {
    param(
        [Parameter(Mandatory = $true)] [byte]$row,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    if($shifts % 8 -ne 0) {
        [array]$data_temp = $null
        [byte]$j = 0

        for([byte]$i = 0; $i -le 7; $i++) {
            $data_temp += $data[$i * 8 + $row]
        }

        $data_temp = $data_temp[$shifts..7] + $data_temp
        for($i = 0; $i -le 7; $i++) {
            $data[$i * 8 + $row] = $data_temp[$j]
            $j++
        }
    }

    Write-Host ("`n" + 'Vertical    ' + $row + ' ' + $shifts)
    display_grid($data)
}

function applepie {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )
    [byte]$x,$y = 0

    for([byte]$i = 0; $i -le 15; $i++) {
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
Write-Host ($null)

<# Decode #>
function applepie_reverse {
    param(
        [Parameter(Mandatory = $true)] [array]$data
    )

    for([int]$i = 7; $i -ge 0; $i--) { # Integer data type because .NET is not happy about the $i-- part
        $i = [byte]$i # Cast back to byte just for safety and memory reasons
        $x = [byte]$password.Substring($i * 2,1) # Horizontal shift number of the block
        $y = [byte]$password.Substring($i * 2 + 1,1) # Vertical shift number of the block

        Write-Host ($i.ToString() + ' ' + $x.ToString() + ' ' + $y.ToString())
        #shift_vertical $y $data
        #display_grid($data)
        #Write-Host ($null)
    }
}

applepie_reverse($data)
