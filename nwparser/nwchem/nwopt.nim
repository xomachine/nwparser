from streams import Stream, atEnd
from strutils import `%`
from pegs import peg, match
from utils import find, floatPattern, parseFloat, parseInt
from units import Hartree
from structures import Calculation, CalcType, PESPoint
from nwgeometry import findGeometry

const OptHeader* = """^\s*'NWChem Geometry Optimization'$"""

proc readOpt*(fd: Stream): Calculation =
  let energyPattern {.global.} =
    peg("""^'@'\s*{\d+}\s*{$1}\s*.*$""" % floatPattern)
  let stepPattern {.global.} = peg"^\s*'Step'\s+\d+\s*$"
  let multiplicityPattern {.global.} =
    peg"[mM]ult[^\d]+{\d+}[^\d]*$"
  result.kind = CalcType.Optimization
  result.path = newSeq[PESPoint]()
  while not fd.atEnd():
    discard fd.find(stepPattern)
    let stepGeometry = fd.findGeometry()
    let multiplicityCaptures = fd.find(multiplicityPattern)
    let multiplicity = multiplicityCaptures[0].parseInt()
    if result.multiplicity == 0: result.multiplicity = multiplicity
    else:
      assert(multiplicity == result.multiplicity, "Multiplicity doesn't match")
    let energyCaptures = fd.find(energyPattern)
    let energy = energyCaptures[1].parseFloat().Hartree()
    let point = (geometry: stepGeometry, energy: energy)
    result.path.add(point)
