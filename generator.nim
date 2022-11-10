
import math, pixie, suru
import constants

const BLACK = rgb(0, 0, 0).asRgbx
const WHITE = rgb(255, 255, 255).asRgbx

type
    GraphOpts* = object
        xMin*, xMax*, yMin*, yMax*, threshold*, maybeThreshold*: float
        width*, height*, subdivisions*: int
        showProgress*: bool

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

    for offset in 0 ..< subdivisions^2:
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

    var x = opts.xMin
    var y = opts.yMax

    var bar = initSuruBar()
    bar[0].total = size

    if opts.showProgress:
        bar.setup()

    for offset in 0 ..< size:
        image.data[offset] = case subpixelMatch(x, y, xInc, yInc, opts.threshold, opts.maybeThreshold, opts.subdivisions)
            of true: BLACK
            else: WHITE

        if offset mod opts.width == 0:
            y -= yInc
            x = opts.xMin
            if opts.showProgress:
                bar[0].inc(opts.width)
                bar.update

        x += xInc

    if opts.showProgress:
        bar.finish()

    return image