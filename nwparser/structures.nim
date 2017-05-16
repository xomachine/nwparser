from units import Angstrom, Hartree, ReversedCM

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
  Mode* = tuple
    frequency: ReversedCM
    intensity: BiggestFloat | seq[ReversedCM]
  Calculation* = object
    initial*: Geometry
    case kind*: CalcType
    of Optimization, MEP:
      path*: seq[PESPoint]
    of Energy, Frequency:
      modes*: seq[Mode]
      termochemistry*: TermoData
      final*: PESPoint

