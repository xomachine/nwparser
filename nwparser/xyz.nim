from streams import Stream, writeLine
from strutils import `%`
from structures import Calculation, Geometry, CalcType
from units import `$`

proc toXYZ(geometry: Geometry, target: Stream, comment: string = "") =
  target.writeLine(geometry.atoms.len)
  target.writeLine(comment)
  for atom in geometry.atoms:
    target.writeLine("  $1    $2  $3  $4" %
                     [atom.symbol, $atom.x, $atom.y, $atom.z])

proc toStream*(calculation: Calculation, target: Stream) =
  case calculation.kind
  of CalcType.MEP:
    for point in calculation.path:
      toXYZ(point.geometry, target, "Energy: " & $point.energy)
  else:
    if not calculation.final.geometry.atoms.isNil:
      toXYZ(calculation.final.geometry, target, $calculation.final.energy)
    else:
      toXYZ(calculation.initial, target)

