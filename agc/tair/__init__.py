"""`tair`: tensor programs. A shape-typed list of whole-tensor statements (elementwise maps and
reductions over the last axis), with a text form and a NumPy interpreter. It is the high-level
input a generator compiles straight into machine IR (design D4)."""
from .ir import Call, Const, Expr, Program, Stmt, TairError, Var
from .text import parse, print_program
from .interp import evaluate

__all__ = ["Call", "Const", "Expr", "Program", "Stmt", "TairError", "Var", "parse", "print_program", "evaluate"]
