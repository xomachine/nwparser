
from streams import newFileStream, Stream, write
from parseopt import getopt, cmdLongOption, cmdShortOption
from strutils import `%`
from tables import Table, `[]`, `[]=`, contains, newTable
from units import Hartree
from utils import parseInt, parseFloat
from nwchem.nwcommon import parseFile
from xyz import toStream
from kisthelp.kisthelp_common import toPoint, toFields, `$`
from structures import Calculation, CalcType, toMolSystem
from mesmer.mesverter import toMESMER
#import nwrtdb.reader

type
  Options = ref Table[string, string]
proc `$`(h: Hartree): string {.borrow.} # = $(h.BiggestInt)

proc toXYZStream(calcs: seq[Calculation], stream: Stream, options: Options) =
  calcs[^1].toStream(stream)

proc toMESMERStream(calcs: seq[Calculation], stream: Stream, options: Options) =
  let calcname = 
    if "name" in options:
      options["name"]
    else: "Unnamed calculation"
  stream.write(calcs.toMESMER(calcname))

proc toKISTHELPStream(calcs: seq[Calculation], stream: Stream, options: Options) =
  let fielded = calcs.toMolSystem().toFields()
  if "number" in options:
    stream.write($toPoint(fielded, options["number"].parseFloat()))
  else:
    stream.write($fielded)

var outhandler: proc(calcs:seq[Calculation], stream:Stream, options: Options) = toXYZStream
var calcnum = 0
var otherOptions: Options = newTable[string, string]()
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
      of "kisthelp":
        outhandler = toKISTHELPStream
      else:
        discard
    else:
      otherOptions[key] = value
  else:
    quit("Unknown option: " & key)

let input = newFileStream(stdin)
let calculations = parseFile(input)
stderr.writeLine "Read $1 calculations from input" % $calculations.len
let outstream = newFileStream(stdout)
outhandler(calculations, outstream, otherOptions)

