from xmltree import `$`
from ../structures import Calculation
from mesmer import toMolecule, toXML
from molsystem import fromCalcs

proc toMESMER*(calcs: seq[Calculation], id: string): string =
  $(toMolecule(id, calcs.fromCalcs()).toXML())

