from structures import Geometry, Atom
from utils import skipLines, parseFloat, associate, floatPattern
from units import Angstrom, Bohr, toAngstrom
from streams import Stream, atEnd, readLine
from strutils import `%`
import pegs

let headerPattern = peg"\s*'Output coordinates'.*"
let gradientPattern = peg"\s*\ident\s'ENERGY GRADIENTS'.*"
# no tag charge x y z
let coordTablePattern =
  peg("""\s*{\d+}\s{\ident}\s+{$1}\s+{$1}\s+{$1}\s+{$1}""" % floatPattern)
let gradTablePattern =
  peg("""\s*{\d+}\s{\ident}\s+{$1}\s+{$1}\s+{$1}\s+{$1}\s+{$1}\s+{$1}""" %
      floatPattern)

proc readGeometry(fd: Stream): Geometry =
  result = newSeq[Atom]()
  fd.skipLines(3)
  var captures = newSeq[string](6)
  while fd.readLine().match(coordTablePattern, captures):
    let atom: Atom = (symbol: captures[1], x: captures[3].parseFloat().Angstrom,
                                           y: captures[4].parseFloat().Angstrom,
                                           z: captures[5].parseFloat().Angstrom,
                                           dx: 0.0,
                                           dy: 0.0,
                                           dz: 0.0)
    result.add(atom)

proc readGradient(fd: Stream): Geometry =
  result = newSeq[Atom]()
  fd.skipLines(3)
  var captures = newSeq[string](8)
  while fd.readLine().match(gradTablePattern, captures):
    let atom: Atom = (symbol: captures[1], x: captures[2].parseFloat().Bohr().toAngstrom(),
                                           y: captures[3].parseFloat().Bohr().toAngstrom(),
                                           z: captures[4].parseFloat().Bohr().toAngstrom(),
                                           dx: captures[5].parseFloat(),
                                           dy: captures[6].parseFloat(),
                                           dz: captures[7].parseFloat())
    result.add(atom)

proc findGeometry*(fd: Stream): Geometry =
  result = newSeq[Atom]()
  while (not fd.atEnd()):
    let line = fd.readLine()
    if line.match(headerPattern):
      return readGeometry(fd)
    elif line.match(gradientPattern):
      return readGradient(fd)

