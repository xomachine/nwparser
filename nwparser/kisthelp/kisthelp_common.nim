from ../structures import CalcType, Mode, MolSystem, InertiaMatrix
from ../units import ReversedCM, Hartree, `$`, AMU, `+`
from strutils import repeat, join
from sequtils import mapIt, foldl, filterIt

type
  Field* = tuple
    name: string
    data: string
    depth: Natural

proc `$`*(self: Field): string =
  let ast = "*".repeat(self.depth + 1)
  ast & self.name & "\n" & $self.data & "\n" & ast & "END"

proc `$`*(self: seq[Field]): string =
  self.mapIt($it).join("\n")

proc `$`(self: seq[Mode]): string =
  self.mapIt(it.frequency.BiggestFloat).filterIt(abs(it) > 1.0)
      .mapIt(if it > 0: $it else: $abs(it) & 'i').join("\n")

proc `$`[N](self: array[N, ReversedCM]): string =
  self.mapIt($it).join("\n")

proc `$`(self: InertiaMatrix): string =
  [self[4], self[0], self[8]].join("\n")

proc newField[T](name: string, data: T): Field =
  result.name = name
  result.data = $data
  result.depth = 0
  when type(data) is Field:
    result.depth = data.depth + 1
  when type(data) is seq[Field]:
    assert(data.len > 0, "Empty sequence cannot be enfielded!")
    result.depth = data[0].depth + 1

proc toPoint*(data: seq[Field], coordinate: BiggestFloat): Field =
  newField("POINT", newField("IRC", coordinate) & data)


proc toFields*(molecule: MolSystem): seq[Field] =
  let mass = molecule.state.geometry.atoms.mapIt(it.mass).foldl(a + b)
  stderr.writeLine("Frequencies No: " & $molecule.modes.len)
  result = @[
    newField("MASS (in amu)", mass),
    newField("NUMBER OF SYMMETRY", 1),
    newField("FREQUENCIES (in cm-1)", molecule.modes),
    newField("ELECTRONIC DEGENERACY", molecule.multiplicity),
    newField("MOMENT OF INERTIA (in Amu.bohr**2)",
                        molecule.state.geometry.inertia_momentum),
    newField("LINEAR", "not linear"),
    newField("POTENTIAL ENERGY (in hartree)", molecule.state.energy),
  ]

