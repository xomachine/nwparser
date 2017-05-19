from utils import skipLines, floatPattern
from structures import Calculation, CalcType, Mode, ThermoData
from streams import Stream, atEnd, readLine

const FreqHeader = """\s*'NWChem Nuclear Hessian and Frequency Analysis'.*"""
let rotationalPattern = peg"'Rotational constants'"
let freqPattern = peg"\s*'NORMAL MODE EIGENVECTORS IN CARTESIAN COORDINATES'"

proc readThermal(fd: Stream): ThermoData =
  discard
proc readModes(fd: Stream): seq[Mode] =
  var captures = newSeq[string](6)
  let elemPattern: static[Peg] = peg("""$1(\s+{$1})?(\s+{$1})?(\s+{$1})?(\s+{$1})?(\s+{$1})?""" % floatPattern)
  while not fd.atEnd():
    let line = fd.readLine()
    while fd.readLine().match(elemPattern, captures):
      discard

proc readFreq*(fd: Stream): Calculation =
  result.kind = CalcType.Frequency
  while not fd.atEnd():
    let line = fd.readLine()
    if line.match(rotationalPattern):
      result.termochemistry = readTermal(fd)
    elif line.match(freqPattern):
      result.modes = readModes(fd)
      

