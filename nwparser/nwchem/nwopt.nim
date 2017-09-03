from streams import Stream, atEnd, readLine
from pegs import peg, match
from utils import find, findAny, floatPattern, parseFloat, parseInt
from units import Hartree, `$`
from structures import Calculation, CalcType, PESPoint, InertiaMatrix
from nwgeometry import findGeometry
from nwinertia import readInertiaMoments

const OptHeader* = """^\s*'NWChem Geometry Optimization'$"""
let multiplicityPattern* = peg"^\s*('Spin'\s+)?[mM]'ult'\D+{\d+}\D*$"
let endPattern = peg"^\s*'Task'\s+'times'\s+'cpu:'.*$"
proc readStepper(fd: Stream): Calculation
proc readDriver(fd: Stream): Calculation

proc readOpt*(fd: Stream): Calculation =
  let driverPattern {.global.} = peg"^\s*'Energy Minimization'\s*$"
  let stepperPattern {.global.} = peg"^\s*'NWChem STEPPER Module'\s*$"
  while not fd.atEnd():
    let line = fd.readLine()
    if line.match(driverPattern):
      result = fd.readDriver()
    elif line.match(stepperPattern):
      result = fd.readStepper()
    else: continue
    break

proc readStepper(fd: Stream): Calculation =
  stderr.writeLine("Reading stepper optimization calculation...")
  let stepStartPattern {.global.} = peg"^\s*'Walk statistics for step:'\s*{\d+}\s*$"
  let energyPattern {.global.} = peg("""^\s*'Current actual total energy:'\s*{""" &
                                     floatPattern & """D[+-]\d+}\s*$""")
  result.multiplicity = fd.find(multiplicityPattern)[0].parseInt()
  result.kind = CalcType.Optimization
  result.path = newSeq[PESPoint]()
  while not fd.atEnd():
    let patternIndex = fd.findAny(stepStartPattern, endPattern)
    if patternIndex == 1:
      break
    let energyCapture = fd.find(energyPattern)
    let geometry = fd.findGeometry()
    let energy = energyCapture[0].parseFloat().Hartree()
    let point = (geometry: geometry, energy: energy)
    result.path.add(point)

proc readDriver(fd: Stream): Calculation =
  stderr.writeLine("Reading driver optimization calculation...")
  result.kind = CalcType.Optimization
  let energyPattern {.global.} =
    peg("""^'@'\s+{\d+}\s+{""" & floatPattern & """}.*$""")
  let stepPattern {.global.} = peg"^\s*'Step'\s+{\d+}.*$"
  let alreadyPattern {.global.} = peg"\s*'The '\ident' is already converged'"
  let performPattern {.global.} = peg"\s*'Caching 1-el integrals'"
  let convergedPattern {.global.} = peg"\s*'Optimization converged'\s*"
  var nextInertia: InertiaMatrix
  result.path = newSeq[PESPoint]()
  while not fd.atEnd():
    let patternIndex = fd.findAny(stepPattern, endPattern)
    if patternIndex == 0:
      var stepGeometry = fd.findGeometry(bonds = false)
      let scfConverged = fd.findAny(performPattern, alreadyPattern) == 1
      if result.multiplicity == 0:
        let multiplicityCaptures = fd.find(multiplicityPattern,
                                           "Can not find multiplicity")
        result.multiplicity = multiplicityCaptures[0].parseInt()
        stderr.writeLine("Multiplicity = " & $result.multiplicity)
      if scfConverged or stepGeometry.atoms.len < 2:
        stepGeometry.inertia_momentum = nextInertia
      else:
        stepGeometry.inertia_momentum = fd.readInertiaMoments()
      let energyCaptures = fd.find(energyPattern, "Can not find energy")
      let energy = energyCaptures[1].parseFloat().Hartree()
      stderr.writeLine("Energy = " & $energy)
      let point = (geometry: stepGeometry, energy: energy)
      result.path.add(point)
      let optConverged = fd.findAny(performPattern, convergedPattern) == 1
      if optConverged:
        stderr.writeLine("Optimization converged!")
        let energyCaptures = fd.find(energyPattern, "Can not find energy")
        stderr.writeLine("Energy found!")
        result.path[^1].geometry = fd.findGeometry()
        result.path[^1].energy = energyCaptures[1].parseFloat().Hartree()
        if result.path.len > 1:
          result.path[^1].geometry.inertia_momentum =
            result.path[^2].geometry.inertia_momentum
      else:
        nextInertia = fd.readInertiaMoments()
    else: break
