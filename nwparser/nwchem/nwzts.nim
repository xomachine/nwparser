from streams import Stream, atEnd, readLine
from pegs import peg, match
from structures import Calculation, CalcType, PESPoint
from utils import skipLines, parseFloat, parseInt, floatPattern
from units import Hartree
from nwgeometry import findGeometry

const prefix = """\@'zts'?"""
const ZTS_header* = prefix & """' String method'\."""

type
  BeadNotFound = object of Exception
  Bead = tuple
    index: Natural
    point: PESPoint

proc readBead(fd: Stream): Bead =
  let beadEnergyPattern {.global.} =
    peg("""\s*'string: finished bead'\s+{\d+}' energy='\s+{""" &
        floatPattern & "}")
  result.point.geometry = findGeometry(fd)
  var captures = newSeq[string](2)
  while (not fd.atEnd()):
    let line = fd.readLine()
    if line.match(beadEnergyPattern, captures):
      result.index = captures[0].parseInt()
      result.point.energy = captures[1].parseFloat().Hartree
      return
  raise newException(BeadNotFound, "Bead energy not found!")

proc readZeroIteration(fd: Stream, nbeads: Natural): seq[PESPoint] =
  result = newSeq[PESPoint](nbeads)
  for i in 1..nbeads:
    let bead = readBead(fd)
    assert bead.index == i
    result[i-1] = bead.point

proc readIteration(fd: Stream, path: seq[PESPoint]): seq[PESPoint] =
  var newpath = path
  let iterationPattern {.global.} = peg("""\s*'string: iteration #'\s+{\d+}""")
  let beadStartPattern {.global.} = peg"\s*'string: running bead'\s+{\d+}"
  while not fd.atEnd():
    let nextline = fd.readLine()
    if nextline.match(beadStartPattern):
      let bead = readBead(fd)
      newpath[bead.index-1] = bead.point
    elif nextline.match(iterationPattern):
      return newpath
  return path

proc readZTS*(fd: Stream): Calculation =
  let nBeadsPattern {.global.} =
    peg(prefix & """' Number of replicas'\s+\=\s+{\d+}""")
  stderr.writeLine "Found ZTS pattern"
  result.kind = CalcType.MEP
  fd.skipLines(4)
  var captures = newSeq[string](1)
  let line = fd.readLine()
  stderr.writeLine line
  assert(line.match(nBeadsPattern, captures))
  let nbeads = parseInt(captures[0])
  result.path = readZeroIteration(fd, nbeads)
  var iteration = 0
  while not fd.atEnd():
    iteration += 1
    try:
      stderr.writeLine "Reading beads for iteration " & $iteration
      result.path = readIteration(fd, result.path)
    except BeadNotFound: break

