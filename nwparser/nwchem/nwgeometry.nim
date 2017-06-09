from structures import Geometry, Atom, Bond
from utils import skipLines, parseFloat, associate, floatPattern, parseInt, find
from units import Angstrom, Bohr, toAngstrom
from streams import Stream, atEnd, readLine
from strutils import `%`
import pegs

proc readBonds(fd: Stream): seq[Bond] =
  let bondPattern {.global.} = peg"\s*'internuclear distances'"
  let bondDataPattern {.global.} =
    peg("""\s*{\d+}\s\w+\s+'|'\s+{\d+}\s\w+\s+'|'\s+{$1}\s+'|'\s+{$1}""" %
        floatPattern)
  discard fd.find(bondPattern, "Bonds not found")
  fd.skipLines(3)
  var captures: array[4, string]
  result = newSeq[Bond]()
  while fd.readLine.match(bondDataPattern, captures):
    let atom1 = captures[0].parseInt().Natural
    let atom2 = captures[1].parseInt().Natural
    let distance = captures[3].parseFloat().Angstrom
    # FIXME: distance should be used to obtain the bond order
    result.add((first: atom1, second: atom2, order: range[1..3](1)))

proc readGeometry(fd: Stream): Geometry =
  # no tag charge x y z
  let coordTablePattern {.global.} =
    peg("""\s*{\d+}\s{\ident}\s+{$1}\s+{$1}\s+{$1}\s+{$1}""" % floatPattern)
  result.atoms = newSeq[Atom]()
  fd.skipLines(3)
  var captures = newSeq[string](6)
  while fd.readLine().match(coordTablePattern, captures):
    let atom: Atom = (symbol: captures[1], x: captures[3].parseFloat().Angstrom,
                                           y: captures[4].parseFloat().Angstrom,
                                           z: captures[5].parseFloat().Angstrom,
                                           dx: 0.0.Angstrom,
                                           dy: 0.0.Angstrom,
                                           dz: 0.0.Angstrom)
    result.atoms.add(atom)
  result.bonds = fd.readBonds()

proc readGradient(fd: Stream): Geometry =
  let gradTablePattern {.global.} =
    peg("""\s*{\d+}\s{\ident}\s+{$1}\s+{$1}\s+{$1}\s+{$1}\s+{$1}\s+{$1}""" %
        floatPattern)
  result.atoms = newSeq[Atom]()
  fd.skipLines(3)
  var captures = newSeq[string](8)
  while fd.readLine().match(gradTablePattern, captures):
    let atom: Atom = (symbol: captures[1], x: captures[2].parseFloat().Bohr().toAngstrom(),
                                           y: captures[3].parseFloat().Bohr().toAngstrom(),
                                           z: captures[4].parseFloat().Bohr().toAngstrom(),
                                           dx: captures[5].parseFloat().Bohr.toAngstrom(),
                                           dy: captures[6].parseFloat().Bohr.toAngstrom(),
                                           dz: captures[7].parseFloat().Bohr.toAngstrom())
    result.atoms.add(atom)

proc findGeometry*(fd: Stream): Geometry =
  let headerPattern {.global.} = peg"\s*'Output coordinates'.*"
  let gradientPattern {.global.} = peg"\s*\ident\s'ENERGY GRADIENTS'.*"
  while (not fd.atEnd()):
    let line = fd.readLine()
    if line.match(headerPattern):
      return readGeometry(fd)
    elif line.match(gradientPattern):
      return readGradient(fd)

