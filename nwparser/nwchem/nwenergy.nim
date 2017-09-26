from streams import Stream
from pegs import peg
from ../strutils import `%`
from ../units import Hartree
from ../utils import find, floatPattern, parseFloat

proc readEnergy*(fd: Stream): Hartree =
  let energyPattern {.global.} =
    peg("""\s*'Total ''DFT'?'SCF'?' energy ='\s+{$1}""" % floatPattern)
  fd.find(energyPattern, "Can not find energy!")[0].parseFloat().Hartree()
