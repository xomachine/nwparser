from nwgeometry import findGeometry
from nwopt import multiplicityPattern
from nwinertia import readInertiaMoments
from utils import skipLines, floatPattern, parseInt, parseFloat, find, limit
from structures import Calculation, CalcType, Mode, TermoData, Hessian
from structures import initHessian, setElement
from units import ReversedCM, Bohr, Hartree
from streams import Stream, atEnd, readLine
from pegs import peg, findAll, match
from sequtils import mapIt
from strutils import `%`, repeat, strip, replace

const FreqHeader* = """\s*'NWChem Nuclear Hessian and Frequency Analysis'.*"""
const elemPart = """\s+{$1}""" % floatPattern

proc readHessian(fd: Stream, rank: Natural): Hessian =
  stderr.writeLine("Reading Hessian")
  result = initHessian(rank)
  fd.skipLines(3) # Header
  let floats = peg"'-'?\d+'.'\d+'D'[+-]\d+"
  let lineNumber = peg"\s*{\d+}\s+.*"
  var captures: array[10, string]
  var residue: int = rank
  while not fd.atEnd() and residue > 0:
    let prepattern = """\s+{\d+}""".repeat(residue.limit(10))
    let pattern = peg(prepattern)
    residue -= 10
    let columnNumbersStr = fd.readLine()
    assert columnNumbersStr.match(pattern, captures)
    let startColumn = captures[0].parseInt()
    fd.skipLines(1) # ----
    while not fd.atEnd():
      let rawline = fd.readLine()
      if not rawline.match(lineNumber,captures):
        fd.skipLines(1)
        break
      let lineNo = captures[0].parseInt()
      assert lineNo in 1..rank
      let line = rawline.findAll(floats)
      assert line.len > 0
      for col in 0..<line.len:
        let value = line[col].replace("D", "e").parseFloat().Hartree()
        result.setElement(lineNo - 1, col+startColumn - 1, value)

proc readThermal(fd: Stream): TermoData =
  let pattern {.global.} =
    peg("""\s*[ABC]'='\s+{$1}\s+'cm-1'.*""" % floatPattern)
  const zpe = """\s*'Zero-Point correction to Energy'\s+'=""" &
    """'\s+{$1}\s+'kcal/mol  ('\s*{$1}\s+'au)'""" % floatPattern
  let zpePattern {.global.} = peg(zpe)
  const enthalpy = """\s*'Thermal correction to Enthalpy'\s+'=""" &
    """'\s+{$1}\s+'kcal/mol'\s*'('\s*{$1}\s*'au)'""" % floatPattern
  let enthalpyPattern {.global.} = peg(enthalpy)
  const entropy =
    """\s*'Total Entropy                    ='\s*{$1}' cal/mol-K'""" %
      floatPattern
  let entropyPattern {.global.} = peg(entropy)
  var captures: array[2, string]
  fd.skipLines(1)
  for i in 0..2:
    assert fd.readLine().match(pattern, captures)
    result.rotationalConstants[i] = captures[0].parseFloat().ReversedCM()
  fd.skipLines(5)
  assert fd.readLine.match(zpePattern, captures)
  fd.skipLines(1)
  result.zpeCorrection = captures[1].parseFloat().Hartree
  assert fd.readLine().match(enthalpyPattern, captures)
  fd.skipLines(1)
  result.enthalpyCorrection = captures[1].parseFloat().Hartree
  assert fd.readLine().match(entropyPattern, captures)
  result.entropy = captures[0].parseFloat()

proc readModes(fd: Stream, rank: Natural): seq[Mode] =
  result = newSeq[Mode]()
  let indexPattern {.global.} = peg"\s+{\d+}"
  var captures: array[6, string]
  fd.skipLines(3)
  while not fd.atEnd():
    stderr.writeLine("NewTable")
    let line = fd.readLine()
    stderr.writeLine(line)
    let indexes =
      line.findAll(indexPattern).mapIt(parseInt(it.strip())-1)
    if indexes.len() == 0:
      break
    result.setLen(indexes.len + result.len)
    fd.skipLines(1)
    let pfreqPattern =
      peg("""\s*'P.Frequency'""" & elemPart.repeat(indexes.len))
    let elemPattern =
      peg("""\s*\d+""" & elemPart.repeat(indexes.len) % floatPattern)
    assert fd.readLine.match(pfreqPattern, captures)
    let displacements_size = rank div 3
    for i in 0..<indexes.len:
      let freq = captures[i].parseFloat()
      result[indexes[i]].frequency = freq.ReversedCM()
      result[indexes[i]].displacements = newSeq[array[3, Bohr]](displacements_size)
    fd.skipLines(1)
    for di in 0..<displacements_size:
      for i in 0..<3:
        assert fd.readLine.match(elemPattern, captures)
        for fi in 0..<indexes.len:
          let displacement = captures[fi].parseFloat()
          result[indexes[fi]].displacements[di][i] = displacement.Bohr
    if indexes.len < 6:
      break
    fd.skipLines(1)

proc readFreq*(fd: Stream): Calculation =
  let rotationalPattern {.global.} = peg"\s*'Rotational Constants'"
  let freqPattern {.global.} =
    peg"\s*'NORMAL MODE EIGENVECTORS IN CARTESIAN COORDINATES'"
  let rankPattern {.global.} = peg"\s*'No. of equations'\s+{\d+}"
  let hessPattern {.global.} = peg"\s+'MASS-WEIGHTED PROJECTED HESSIAN'.*"
  result.kind = CalcType.Frequency
  result.multiplicity = fd.find(multiplicityPattern)[0].parseInt()
  let captures = fd.find(rankPattern, "Can not detect hessian rank")
  let rank = captures[0].parseInt()
  stderr.writeLine("Detected Number of frequencies is " & $rank)
  discard fd.find(hessPattern)
  result.hessian = fd.readHessian(rank)
  stderr.writeLine("Hessian read successfully")
  result.initial.inertia_momentum = fd.readInertiaMoments()
  discard fd.find(rotationalPattern)
  result.termochemistry = readThermal(fd)
  stderr.writeLine("Thermal read successfully")
  discard fd.find(freqPattern)
  result.modes = readModes(fd, rank)
  stderr.writeLine("Modes read successfully")

