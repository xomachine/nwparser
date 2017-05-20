
import macros
from parseutils import parseBiggestFloat, parseInt
from streams import Stream, readLine, atEnd
from pegs import peg, match, Peg, `=~`
from errors import IncompleteCalculationError

const floatPattern* = """\-?\d+\.\d+"""

proc parseFloat*(s: string): BiggestFloat =
  assert s.parseBiggestFloat(result, 0) > 0

proc parseInt*(s: string): int =
  assert s.parseInt(result) > 0

proc find*(s: Stream, pattern: Peg,
           message: string = "Incomplete calculation"): array[10, string] =
  while not s.readLine().match(pattern, result):
    if s.atEnd():
      raise newException(IncompleteCalculationError, message)

macro skipLines*(fd: Stream, count: Natural): typed =
  result = newStmtList()
  let count = count.intVal
  let skipexpr = quote do:
    discard `fd`.readLine()
  for i in 0..<count:
    result.add(skipexpr)

macro associate*(line: string, fd: Stream,
                 associations: varargs[untyped]): typed =
  when defined(debug):
    hint associations.treerepr
  if associations.len > 0:
    result = newNimNode(nnkIfExpr)
    for association in associations.children():
      association.expectKind(nnkExprColonExpr)
      association.expectMinLen(2)
      let pattern = association[0]
      let handler = association[1]
      let res = newIdentNode("result")
      let handler_invocation = quote do:
        `res`.add(`handler`(`fd`))
      let condition = quote do:
        `line`.match(`pattern`)
      let expression = newTree(nnkElifExpr, condition.last, handler_invocation)
      result.add(expression)
  else:
    result = newEmptyNode()
  when defined(debug):
    hint result.treeRepr
    hint result.repr

