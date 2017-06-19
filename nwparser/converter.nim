
from streams import newFileStream, Stream, write
from parseopt import getopt, cmdLongOption, cmdShortOption
from strutils import `%`
from units import Hartree
from utils import parseInt
from nwchem.nwcommon import parseFile
from xyz import toStream
from structures import Calculation, CalcType
from mesmer.mesverter import toMESMER
#import nwrtdb.reader

proc `$`(h: Hartree): string {.borrow.} # = $(h.BiggestInt)

proc toXYZStream(calcs: seq[Calculation], stream: Stream) =
  calcs[^1].toStream(stream)

proc toMESMERStream(calcs: seq[Calculation], stream: Stream) =
  stream.write(calcs.toMESMER("testcalc"))

var outhandler: proc(calcs:seq[Calculation], stream:Stream) = toXYZStream
var calcnum = 0
for kind, key, value in getopt():
  case kind
  of cmdShortOption, cmdLongOption:
    case key
    of "o", "output":
      case value
      of "xyz":
        outhandler = toXYZStream
      of "mesmer":
        outhandler = toMESMERStream
      else:
        discard
    else:
      quit("Unknown option: " & key)
  else:
    quit("Unknown option: " & key)

let input = newFileStream(stdin)
let calculations = parseFile(input)
stderr.writeLine "Read $1 calculations from input" % $calculations.len
let outstream = newFileStream(stdout)
outhandler(calculations, outstream)

