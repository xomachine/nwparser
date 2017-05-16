from utils import skipLines
from structures import Calculation, CalcType
from streams import Stream, atEnd, readLine

const FreqHeader = """\s*'NWChem Nuclear Hessian and Frequency Analysis'.*"""
let rotationalPattern = peg"'Rotational constants'"
let freqPattern = peg"\s*'NORMAL MODE EIGENVECTORS IN CARTESIAN COORDINATES'"

proc readFreq(fd: Stream): Calculation =
  result.kind = CalcType.Frequency
  while not fd.atEnd():
    let line = fd.readLine()
    if line.match(rotationalPattern):
      result.termochemistry = readTermal(fd)
    elif line.match(freqPattern):
      result.modes = readModes(fd)
      

