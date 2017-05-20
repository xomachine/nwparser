from utils import skipLines, floatPattern, parseInt, parseFloat, find
from structures import Calculation, CalcType, Mode, TermoData, Hessian
from structures import initHessian
from units import ReversedCM, Bohr
from streams import Stream, atEnd, readLine
from pegs import peg, findAll, match
from sequtils import mapIt
from strutils import `%`, repeat

const FreqHeader* = """\s*'NWChem Nuclear Hessian and Frequency Analysis'.*"""
let rotationalPattern = peg"'Rotational constants'"
let freqPattern = peg"\s*'NORMAL MODE EIGENVECTORS IN CARTESIAN COORDINATES'"
let indexPattern = peg"\s+{\d+}"
let rankPattern = peg"\s*'No. of equations'\s+{\d+}"
let hessPattern = peg"\s+'MASS-WEIGHTED PROJECTED HESSIAN'.*"

proc readHessian(fd: Stream, rank: Natural): Hessian =
  result = initHessian(rank)
proc readThermal(fd: Stream): TermoData =
  discard
proc readModes(fd: Stream): seq[Mode] =
  result = newSeq[Mode]()
  var captures = newSeq[string](6)
  const elemPart = """(\s+{$1})?""" % floatPattern
  fd.skipLines(3)
  while not fd.atEnd():
    let indexes = fd.readLine().findAll(indexPattern).mapIt(parseInt(it)-1)
    if indexes.len() == 0:
      break
    result.setLen(indexes.len + result.len)
    fd.skipLines(1)
    let pfreqPattern = peg("'P.Frequency'" & elemPart.repeat(indexes.len))
    let elemPattern =
      peg(("""\s*$1""" & elemPart.repeat(indexes.len - 1)) % floatPattern)
    assert fd.readLine().match(pfreqPattern, captures)
    let displacements_size = Natural(indexes.len/3)
    for i in 0..<indexes.len:
      let freq = captures[i].parseFloat()
      result[indexes[i]].frequency = freq.ReversedCM()
      result[indexes[i]].displacements = newSeq[array[3, Bohr]](displacements_size)
    fd.skipLines(1)
    for di in 0..<displacements_size:
      for i in 0..<3:
        assert fd.readLine().match(elemPattern, captures)
        for fi in 0..<indexes.len:
          let displacement = captures[fi].parseFloat()
          result[indexes[fi]].displacements[di][i] = displacement.Bohr
    if indexes.len < 6:
      break

proc readFreq*(fd: Stream): Calculation =
  result.kind = CalcType.Frequency
  let captures = fd.find(rankPattern, "Can not detect hessian rank")
  let rank = captures[0].parseInt()
  discard fd.find(hessPattern)
  result.hessian = fd.readHessian(rank)
  discard fd.find(rotationalPattern)
  result.termochemistry = readThermal(fd)
  discard fd.find(freqPattern)
  result.modes = readModes(fd)

