$text = Get-Content wiki.md

# work with array of strings (1 / line)
$text = $text -ireplace '^\| image *= *.*$', ''
$text = $text -ireplace '^\| event *= *.*$', ''
$text = $text -ireplace '^\| quote *= *.*$', ''
$text = $text -ireplace '^\| animated *= *.*$', ''
$text = $text -ireplace '^\| character *= *.*$', ''

$text = $text -ireplace '^\| name *= *(.*)$', '"n":"$1",'

$text = $text -ireplace '^\| time *= *((\d+)d )?(\d+)h (\d+)m (\d+)s\s*$', '"d":"P$2T$3:$4:$5",'
$text = $text -ireplace '"PT', '"P0T'
$text = $text -replace '"P(\d)T(\d):', '"P$1T0$2:'
$text = $text -replace '"P(\d)T(\d{2}):(\d):', '"P$1T$2:0$3:'
$text = $text -replace '"P(\d)T(\d{2}):(\d{2}):(\d)"', '"P$1T$2:$3:0$4"'

$text = $text -ireplace '^\| currency *= *(\d+)\s*$', '"c":$1,'

$text = $text -ireplace '^\| xp *= *(\d+)\s*$', '"x":$1,'

$text = $text -ireplace '^\| requirements_level *= *(\d+)?\s*$', '"l":$1,'
$text = $text -ireplace '^"l":,$', '"l":1,'

$text = $text -ireplace '^\| requirements_character *= *(.+)?\s*$', '"h":"$1",'
$text = $text -replace '^"h":"",', ''

$text = $text -ireplace '^\| requirements_building *= *(.+)?\s*$', '"b":"$1",'
$text = $text -replace '^"b":"",', ''

# unused wiki references and comments
$text = $text -replace '^{{.*}}\s*$', ''
$text = $text -replace '^\s*<!--.*-->\s*$', ''

# block start marker
$text = $text -replace '^==.*==\s*$', "["

# action block markers
$text = $text -ireplace '^{{Action\s*$', '{'
$text = $text -replace '^}}\s*$', '},'

# block end marker
$text = $text -replace '^\|}\s*$', ']'

# pad lines to get even spacing when joined
$newText = @()
[String]$line
foreach ($line in $text) {
    # extra padding for longer lines
    if ($line -match '"(n|b|h)":') {
        $padLine = $line.PadRight(50)
    } elseif ($line -match '"d":') {
        $padLine = $line.PadRight(20)
    } else {
        $padLine = $line.PadRight(10)
    }
    $newText += $padLine
}

# now work with newline in regex
$text = $newText | Out-String

$text = $text -replace '\r\n\s*\r\n', "`r`n"
$text = $text -replace '{\s*', '{ '
$text = $text -replace ',( *)\r\n}', " `$1`r`n}"
$text = $text -replace '\r\n(["}])', '$1'
$text = $text -replace '},\s*\r\n', "},`r`n"
$text = $text -replace '},\s*\r\n\]', "}`r`n]"
$text = $text -replace '([\]\[])\s*', "`$1`r`n"
$text = $text -replace '{ "n":', '    $0'

# look for missing levels
$text = $text -replace '("x":\d+)(\s+)}', '$1,   "l":1$2 }'
$text = $text -replace '("x":\d+,)(\s+)("h":|"b":)', '$1   "l":1,$2 $3'

#$text = $text + ']'
$text | Out-File actions.json