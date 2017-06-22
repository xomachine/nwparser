from streams import Stream, atEnd, readLine
from pegs import peg, match
from utils import find, findAny, floatPattern, parseFloat, parseInt
from units import Hartree, `$`
from structures import Calculation, CalcType, PESPoint
from nwgeometry import findGeometry

const OptHeader* = """^\s*'NWChem Geometry Optimization'$"""
let multiplicityPattern* = peg"^\s*('Spin'\s+)?[mM]'ult'\D+{\d+}\D*$"

proc readOpt*(fd: Stream): Calculation =
  let energyPattern {.global.} =
    peg("""^'@'\s+{\d+}\s+{""" & floatPattern & """}.*$""")
  let stepPattern {.global.} = peg"^\s*'Step'\s+{\d+}.*$"
  let convergedPattern {.global.} = peg"^\s*'Optimization converged'\s*$"
  let endPattern {.global.} = peg"^\s*'Task'\s+'times'\s+'cpu:'.*$"
  result.kind = CalcType.Optimization
  result.path = newSeq[PESPoint]()
  stderr.writeLine("Reading optimization calculation...")
  while not fd.atEnd():
    let patternIndex = fd.findAny(stepPattern, convergedPattern, endPattern)
    case patternIndex
    of 1:
      let energyCaptures = fd.find(energyPattern, "Can not find energy")
      result.path[^1].geometry = fd.findGeometry()
      result.path[^1].energy = energyCaptures[1].parseFloat().Hartree()
      break
    of 2:
      stderr.writeLine("Found end...")
      break
    else: discard
    let stepGeometry = fd.findGeometry(nobonds = true)
    if result.multiplicity == 0:
      let multiplicityCaptures = fd.find(multiplicityPattern,
                                         "Can not find multiplicity")
      result.multiplicity = multiplicityCaptures[0].parseInt()
      stderr.writeLine("Multiplicity = " & $result.multiplicity)
    let energyCaptures = fd.find(energyPattern, "Can not find energy")
    let energy = energyCaptures[1].parseFloat().Hartree()
    stderr.writeLine("Energy = " & $energy)
    let point = (geometry: stepGeometry, energy: energy)
    result.path.add(point)
