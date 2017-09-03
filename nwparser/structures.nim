from units import Angstrom, Hartree, ReversedCM, Bohr, AMU

type
  CalcType* = enum
    Energy
    Optimization
    Frequency
    MEP
  InertiaMatrix* = array[9, AMU]
  Atom* = tuple
    id: Natural
    symbol: string
    mass: AMU
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
    inertia_momentum: InertiaMatrix
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
    multiplicity*: Natural
    case kind*: CalcType
    of Optimization, MEP:
      path*: seq[PESPoint]
    of Frequency:
      modes*: seq[Mode]
      hessian*: Hessian
      termochemistry*: TermoData
      energy*: Hartree
    of Energy:
      final*: PESPoint
  MolSystem* = tuple
    multiplicity: Natural
    state: PESPoint
    modes: seq[Mode]
    hessian: Hessian
    termochemistry: TermoData

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

proc toMolSystem*(calculations: seq[Calculation]): MolSystem =
  ## Merges multiple coherent calculation to one molecular system description
  for calculation in calculations:
    if calculation.multiplicity > 0:
      if result.multiplicity > 0:
        assert(result.multiplicity == calculation.multiplicity,
               "Calculations multiplicity is not coherent!")
      else:
        result.multiplicity = calculation.multiplicity
    case calculation.kind
    of Energy:
      result.state = calculation.final
    of Optimization:
      result.state = calculation.path[^1]
    of Frequency:
      result.hessian = calculation.hessian
      result.modes = calculation.modes
      if result.state.geometry.atoms.len == 0:
        result.state.geometry = calculation.initial
        result.state.energy = calculation.energy
    else:
      discard
