import math

const GRAPH_FN_NAME* = "(y - sin(x)) * (max(|x + y| + |x - y| - 1, 0) + max(0.25 - x^2 - y^2, 0)) = 0"

proc graphFn*(x: float, y: float): float =
    return (y-sin(x))*(max(abs(x+y)+abs(x-y)-1,0)+max(0.25-x^2-y^2,0))

const X_MIN*: float = -1
const X_MAX*: float = 1
const Y_MIN*: float = -1
const Y_MAX*: float = 1

const THRESHOLD*: float = 10.float.pow(-4)
const MAYBE_THRESHOLD*: float = 10.float.pow(-1)