from structures import PESPoint, Mode, Hessian, TermoData, CalcType,
                       Calculation

type
  MolSystem* = object
    point*: PESPoint
    modes*: seq[Mode]
    hessian*: Hessian
    thermal*: TermoData
    multiplicity*: Natural

proc fromCalcs*(calcs: seq[Calculation]): MolSystem =
  for calc in calcs:
    if result.multiplicity == 0:
      result.multiplicity = calc.multiplicity
    else:
      assert calc.multiplicity == result.multiplicity
    case calc.kind
    of CalcType.Energy:
      result.point = calc.final
    of CalcType.Frequency:
      result.modes = calc.modes
      result.hessian = calc.hessian
      result.thermal = calc.termochemistry
      if result.point.geometry.atoms == nil:
        result.point.geometry = calc.initial
    of CalcType.Optimization:
      result.point = calc.path[^1]
    else:
      continue

