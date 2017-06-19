
import strtabs
import xmltree
from strutils import `%`, join
from sequtils import mapIt, map, filterIt
from structures import Bond, Atom
from units import Hartree, `+`
from molsystem import MolSystem

type
  DOSC* = enum
    ClassicalRotors = "ClassicalRotors"
    QC = "quantum mechanics"
  Molecule* = tuple
    id: string
    description: string
    DOSCMethod: DOSC
    weight: Natural
    energy: Hartree
    atoms: seq[Atom]
    bonds: seq[Bond]
    rotationals: seq[float]
    frequencies: seq[float]
    scale_factor: float
    multiplicity: Natural

proc toMolecule*(id: string, s: MolSystem): Molecule =
  result.id = id
  result.description = id
  result.atoms = s.point.geometry.atoms
  result.bonds = s.point.geometry.bonds
  result.energy = s.point.energy + s.thermal.zpeCorrection
  result.rotationals = newSeq[float](3)
  for i, c in pairs(s.thermal.rotationalConstants):
    result.rotationals[i] = float(c)
  result.scale_factor = 1.0
  result.frequencies = s.modes.mapIt(it.frequency.float)
  result.multiplicity = s.multiplicity

proc toXML*(self: Bond): XmlNode =
  let refs = "a$1 a$2" % [$self.first, $self.second]
  let order = if self.order < 2: 1 else: self.order
  result = <>bond(atomRefs2=refs, order= $order)

proc toXML*(self: seq[Bond]): XmlNode =
  let bonds = self.map(toXML)
  newXmlTree("bondArray", bonds)

proc toXML*(self: Atom): XmlNode =
  <>atom(id="a" & $self.id, elementType=self.symbol)

proc toXML*(self: seq[float]): XmlNode =
  result = <>array(units="cm-1", newText(self.mapIt($it).join(" ")))

proc toXML*[I, U](self: array[I, U]): XmlNode = toXML(@self)

proc toXML*(self: float|int|float64|Natural, units: string = ""): XmlNode =
  result = <>scalar(newText($self))
  if units != nil and units.len > 0:
    var st = newStringTable(modeCaseSensitive)
    st["units"] = units
    result.attrs = st

proc toXML*(self: Hartree): XmlNode =
  <>scalar(units="Hartree", convention="computational", newText($self.float64))

proc toXML*(self: XmlNode): XmlNode = self

proc toBond*(first: Atom, second: Atom, distance: float): Bond =
  (first: first.id, second: second.id, order: range[1..3](1))
  # TODO: order from distance

proc newProperty[T](name: string, p: T): XmlNode =
  #result = newElement("property")
  #var kv = newStringTable(modeCaseSensitive)
  #kv["dictRef"] = name
  #result.attrs = kv
  #echo result.kind.repr
  #add(result, toXML(p))
  <>property(dictRef=name, toXML(p))

proc toXML*(self: Molecule): XmlNode =
  result = <>molecule(id=self.id, description=self.description)
  result.add(newXmlTree("atomArray", self.atoms.map(toXML)))
  result.add(self.bonds.toXML())
  var properties = newElement("propertyList")
  properties.add(newProperty("me:frequenciesScaleFactor", self.scale_factor))
  properties.add(newProperty("me:vibFreqs", self.frequencies.filterIt(it > 0)))
  properties.add(newProperty("me:rotConsts", self.rotationals))
  properties.add(newProperty("me:ZPE", self.energy))
  properties.add(newProperty("me:spinMultiplicity", self.multiplicity))
  let imaginaries = self.frequencies.filterIt(it < 0).mapIt(-it)
  if imaginaries.len > 0:
    properties.add(newProperty("me:imFreqs", imaginaries))
  if self.weight > 0:
    properties.add(newProperty("me:MW", toXML(self.weight, "amu")))
  result.add(properties)
  var doscm = newElement("me:DOSCMethod")
  doscm.add(newText($self.DOSCMethod))
  result.add(doscm)

