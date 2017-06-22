
type
  Angstrom* = distinct BiggestFloat
  Bohr* = distinct BiggestFloat
  ReversedCM* = distinct BiggestFloat
  Hartree* = distinct BiggestFloat
  Calloria* = distinct BiggestFloat
  Kilo*[T] = distinct T

proc `+`*(x, y: Hartree): Hartree {.borrow.}
proc `==`*(x, y: Angstrom): bool {.borrow.}

converter toAngstrom*(input: Bohr): Angstrom =
  Angstrom(input.BiggestFloat * 0.52918)
converter toBohr*(input: Angstrom): Bohr =
  Bohr(input.BiggestFloat / 0.52918)

proc `$`*(a: Angstrom | Bohr | ReversedCM | Hartree | Calloria): string =
  $(a.BiggestFloat)

converter toKilo*[T](input: T): Kilo[T] = Kilo[T](input.BiggestFloat * 1000)
converter Unkilo*[T](input: Kilo[T]): T = T(input.BiggestFloat / 1000)

