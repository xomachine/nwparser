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
    dx, dy, dz: Angstrom
  Bond* = tuple
    first, second: Natural
    order: range[1..3]
  TermoData* = tuple
    zpeCorrection: Hartree
    enthalpyCorrection: Hartree
    entropy: BiggestFloat
    rotationalConstants: array[3, ReversedCM]
  Geometry* = tuple
    atoms: seq[Atom]
    bonds: seq[Bond]
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

proc getLine*(line: Natural): Slice[int] =
  let upper = ((line+1)*(line+2)) shr 1
  let lower = (line*(line+1)) shr 1
  lower..upper

proc getElement*(h: Hessian, c1, c2: Natural): Hartree =
  ## gets the value from the hessian matrix. it does not matter in which
  ## sequence you will supply colomn and row since the matrix is
  ## orthogonalized
  let n = min(c1, c2)
  let m = max(c1, c2)
  let theline = getLine(m)
  h.matrix[theline][n]

proc setElement*(h: var Hessian, c1, c2: Natural, elem: Hartree) =
  let line = max(c1, c2)
  let col = min(c1, c2)
  let idxStart = (line*(line+1)) shr 1
  h.matrix[idxStart+col] = elem

