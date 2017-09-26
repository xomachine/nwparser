
type
  Angstrom* = distinct BiggestFloat
  Bohr* = distinct BiggestFloat
  ReversedCM* = distinct BiggestFloat
  Hartree* = distinct BiggestFloat
  Calloria* = distinct BiggestFloat
  AMU* = distinct BiggestFloat
  Kilo*[T] = distinct T

proc `+`*(x, y: Hartree): Hartree {.borrow.}
proc `==`*(x, y: Angstrom): bool {.borrow.}
proc `==`*(x, y: AMU): bool {.borrow.}
proc `+`*(x, y: AMU): AMU {.borrow.}

converter toCalloria*(input: Hartree): Calloria =
  Calloria(input.BiggestFloat * 627509.474)
converter toAngstrom*(input: Bohr): Angstrom =
  Angstrom(input.BiggestFloat * 0.52918)
converter toBohr*(input: Angstrom): Bohr =
  Bohr(input.BiggestFloat / 0.52918)

proc `$`*(a: Angstrom | Bohr | ReversedCM | Hartree | Calloria | AMU): string =
  $(a.BiggestFloat)

converter toKilo*[T](input: T): Kilo[T] = Kilo[T](input.BiggestFloat / 1000)
converter unKilo*[T](input: Kilo[T]): T = T(input.BiggestFloat * 1000)

