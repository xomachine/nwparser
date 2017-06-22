from streams import Stream, atEnd
from strutils import `%`
from pegs import peg, match
from utils import find, floatPattern, parseFloat
from units import Hartree
from structures import Calculation, CalcType, PESPoint
from nwgeometry import findGeometry

const OptHeader* = """^\s*'NWChem Geometry Optimization'$"""

proc readOpt*(fd: Stream): Calculation =
  let energyPattern {.global.} =
    peg("""^'@'\s*{\d+}\s*{$1}\s*.*$""" % floatPattern)
  result.kind = CalcType.Optimization
  result.path = newSeq[PESPoint]()
  while not fd.atEnd():
    let stepGeometry = fd.findGeometry()
    let energyCaptures = fd.find(energyPattern)
    let energy = energyCaptures[1].parseFloat().Hartree()
    let point = (geometry: stepGeometry, energy: energy)
    result.path.add(point)
