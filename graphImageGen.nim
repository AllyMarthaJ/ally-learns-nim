
import math, pixie

const BLACK = rgb(0, 0, 0).asRgbx
const WHITE = rgb(255, 255, 255).asRgbx

type
    GraphOpts* = object
        xMin*, xMax*, yMin*, yMax*, threshold*, maybeThreshold*: float
        width*, height*, subdivisions*: int

const GRAPH_FN_NAME* = "(y - sin(x)) * (max(|x + y| + |x - y| - 1, 0) + max(0.25 - x^2 - y^2, 0)) = 0"
proc graphFn(x: float, y: float): float =
    return (y-sin(x))*(max(abs(x+y)+abs(x-y)-1,0)+max(0.25-x^2-y^2,0))

proc subpixelMatch(x: float, y: float, xInc: float, yInc: float, threshold: float, maybeThreshold: float, subdivisions: int): bool =
    let val = abs(graphFn(x, y))

    if val <= threshold:
        return true

    if subdivisions == 0 or val > maybeThreshold:
        return false

    let uInc: float = xInc / subdivisions.float
    let vInc: float = yInc / subdivisions.float

    var u = x
    var v = y + yInc

    for offset in countup(0, subdivisions ^ 2 - 1):
        if abs(graphFn(u, v)) <= threshold:
            return true

        if offset mod subdivisions == 0:
            v -= vInc
            u = x

        u += uInc

    return false

proc generateImage*(opts: GraphOpts): Image =
    var image = newImage(opts.width, opts.height)

    let size = opts.width * opts.height
    let xInc: float = (opts.xMax - opts.xMin) / opts.width.float
    let yInc: float = (opts.yMax - opts.yMin) / opts.height.float

    let threshold = opts.threshold
    let maybeThreshold = opts.maybeThreshold
    let subdivisions = opts.subdivisions
    let xMin = opts.xMin
    let width = opts.width

    var x = opts.xMin
    var y = opts.yMax

    for offset in countup(0, size - 1):
        image.data[offset] = case subpixelMatch(x, y, xInc, yInc, threshold, maybeThreshold, subdivisions)
            of true: BLACK
            else: WHITE

        if offset mod width == 0:
            y -= yInc
            x = xMin

        x += xInc

    return image