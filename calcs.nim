

type
  CalcType* = enum
    Energy
    Optimization
    Frequency
    MEP
  Atom* = tuple
    symbol: string
    x, y, z: BiggestFloat
    dx, dy, dz: BiggestFloat
  TermoData* = tuple
    zpeCorrection: BiggestFloat
    enthalpyCorrection: BiggestFloat
    entropy: BiggestFloat
    rotationalConstants: array[3, BiggestFloat]
  Geometry* = seq[Atom]
  PESPoint* = tuple
    geometry: Geometry
    energy: BiggestFloat
  Mode* = tuple
    frequency: BiggestFloat
    intensity: BiggestFloat
  Calculation* = object
    initial*: Geometry
    case kind*: CalcType
    of Optimization, MEP:
      path*: seq[PESPoint]
    of Energy, Frequency:
      modes*: seq[Mode]
      termochemistry*: TermoData
      final*: PESPoint

