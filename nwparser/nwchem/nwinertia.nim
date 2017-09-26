from streams import Stream, readLine
from strutils import `%`
from pegs import peg, match
from ../structures import InertiaMatrix
from ../units import AMU
from ../utils import skipLines, find, floatPattern, parseFloat

proc readInertiaMoments*(fd: Stream): InertiaMatrix =
  let inertiaPattern {.global.} = peg"' moments of inertia (a.u.)'"
  let matrixLinePattern {.global.} =
    peg("""^\s*{$1}\s+{$1}\s+{$1}""" % floatPattern)
  var captures: array[3, string]
  discard fd.find(inertiaPattern, "Inertia moments not found!")
  fd.skipLines(1)
  for i in 0..2:
    let shift = i*3
    assert fd.readLine().match(matrixLinePattern, captures)
    result[shift] = captures[0].parseFloat().AMU
    result[shift+1] = captures[1].parseFloat().AMU
    result[shift+2] = captures[2].parseFloat().AMU

