from units import Angstrom, Hartree, ReversedCM, Bohr

type
  CalcType* = enum
    Energy
    Optimization
    Frequency
    MEP
  Atom* = tuple
    symbol: string
    x, y, z: Angstrom
    dx, dy, dz: BiggestFloat
  TermoData* = tuple
    zpeCorrection: Hartree
    enthalpyCorrection: Hartree
    entropy: BiggestFloat
    rotationalConstants: array[3, BiggestFloat]
  Geometry* = seq[Atom]
  PESPoint* = tuple
    geometry: Geometry
    energy: Hartree
  Hessian* = tuple
    rank: Natural
    matrix: seq[Hartree]
  Mode* = tuple
    frequency: ReversedCM
    intensity: BiggestFloat
    displacements: seq[array[3, Bohr]]
  Calculation* = object
    initial*: Geometry
    case kind*: CalcType
    of Optimization, MEP:
      path*: seq[PESPoint]
    of Frequency:
      modes*: seq[Mode]
      hessian*: Hessian
      termochemistry*: TermoData
    of Energy:
      final*: PESPoint

proc initHessian*(rank: Natural): Hessian =
  result.rank = rank
  result.matrix = newSeq[Hartree](((rank + 1)*rank) shr 1)

proc getLine*(h: Hessian, line: Natural): seq[Hartree] =
  let upper = ((line+1)*(line+2)) shr 1
  let lower = (line*(line+1)) shr 1
  h.matrix[lower..upper]

proc getElement*(h: Hessian, c1, c2: Natural): Hartree =
  ## gets the value from the hessian matrix. it does not matter in which
  ## sequence you will supply colomn and row since the matrix is
  ## orthogonalized
  let n = min(c1, c2)
  let m = max(c1, c2)
  let theline = h.getLine(m)
  theline[n]

