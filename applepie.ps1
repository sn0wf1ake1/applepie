Clear-Host

<#
Applepie: An 8x8 grid of shifting data horisontally and vertically to encrypt/scramble data

1) Comments. Lots and lots of comments so anyone can easily understand what is going on
2) Avoid division at all costs. PowerShell is already kind of a slow language and division costs a lot of CPU power
3) Avoid floating points at all costs. Sometimes it's neccesary though for things like square root
4) Strongly defined data types, i.e. no accidental casting from byte to integer. Casting to string is unavoidable though
5) No external modules allowed
6) No Secure-String allowed because it only works on Windows platforms
#>

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
    # Additional necessary entropy. This is where 0 and 8 come into play in the form of $i
    $z += [System.Convert]::ToString(([byte]$y.Substring($i,2) + [byte]$y.Substring($i + 1,2)) + $i % 11)
}

$password = $z -replace(9,$null) -replace("^(\d{3})") # 0 and 8 could technically be dropped but adds to entropy. 9 leaps over so just drop it
<# End #>

<# Debug info #>
$password
$password.Length
#break
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

    if($shifts % 8 -ne 0) { # Ignore 0 and 8
        [array]$data_temp = $null # Clean shop
        [byte]$j = 0

        $data_temp = $data[($row * 8)..($row * 8 + 7)]
        $data_temp = $data_temp[$shifts..7] + $data_temp

        for([byte]$i = $row * 8; $i -le $row * 8 + 7; $i++) {
            $data[$i] = $data_temp[$j]
            $j++
        }
    }

    Write-Host ("`n" + 'Horizontal  ' + $row + ' ' + $shifts)
    display_grid $data
}

function shift_vertical {
    param(
        [Parameter(Mandatory = $true)] [byte]$column,
        [Parameter(Mandatory = $true)] [byte]$shifts
    )

    if($shifts % 8 -ne 0) { # Ignore 0 and 8
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
        if($i % 2 -eq 0) {
            shift_horizontal $x ([byte]$password.Substring($i,1))
            $x++
            } else {
            shift_vertical $y ([byte]$password.Substring($i,1))
            $y++
        }
    }
}

applepie $data

<# Decoding #>
Write-Host ("`n" + '---')

<#
1 shift. Just add 7 to reverse the result. 7 because it's a 0 to 7 array, so 8 (8 being the grid) - 1 = 7
Reversed to revert the order of encryption/scrambling
#>
#shift_vertical 7 7
#shift_horizontal 7 3

function applepie_reverse {
    param(
        [Parameter(Mandatory = $true)] [array]$data,
        [Parameter(Mandatory = $true)] [byte]$password_offset # Byte type so far but will likely change to integer or big integer
    )

    [array]$password_segment = $password[($password_offset * 16)..($password_offset * 16 + 15)]
Write-Host $password_segment
    break
    <#
    Hack because .NET is not happy with the byte and $i-- part that will loop over to -1 and then needs to be recast from integer back to byte.
    Looks a bit clumsy and strange, but is better and more secure than constant type changing, so bite the bullet and spend a CPU cycle
    #>
    for([byte]$i = 0; $i -le 7; $i++) {
        [byte]$j = 7 - $i
        Write-Host ($j)
    }
}

applepie_reverse $data 0 # 0 in this case is the very first 16 byte password block
