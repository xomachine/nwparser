
from streams import newFileStream
from parseopt import getopt, cmdLongOption, cmdShortOption
from strutils import `%`
from utils import parseInt
from nwchem.nwcommon import parseFile
from xyz import toStream

var outformat = "xyz"
var calcnum = 0
for kind, key, value in getopt():
  case kind
  of cmdShortOption, cmdLongOption:
    case key
    of "o", "output":
      outformat = value
    of "c", "calc":
      calcnum = value.parseInt()
    else:
      quit("Unknown option: " & key)
  else:
    quit("Unknown option: " & key)

let input = newFileStream(stdin)
let calculations = parseFile(input)
stderr.writeLine "Read $1 calculations from input" % $calculations.len
if calcnum > calculations.len-1 or calcnum < 0:
  quit("Only $1 calculations readed, but you requested $2." %
       [$calculations.len, $calcnum])
let outstream = newFileStream(stdout)
toStream(calculations[calcnum], outstream)

