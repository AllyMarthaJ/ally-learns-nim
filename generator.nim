
import math, pixie, suru, strformat, sugar
import constants

const BLACK = rgb(0, 0, 0).asRgbx
const WHITE = rgb(255, 255, 255).asRgbx

{.experimental:"parallel".}

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

type ThreadData = ref object
    y*, xInc*, yInc*: float
    offsetY*: int
    opts*: GraphOpts
    imageAddr*: ptr Image
    bar*: ptr SuruBarController

proc processRow(data: ThreadData) =
    let info = data[]

    var image = info.imageAddr[]

    let offset = info.offsetY * info.opts.width
    var x = info.opts.xMin

    for offsetX in offset ..< offset + info.opts.width:
        let clr = subpixelMatch(x, info.y, info.xInc, info.yInc, info.opts.threshold, info.opts.maybeThreshold, info.opts.subdivisions)
        image.data[offsetX] = case clr
            of true: BLACK
            else: WHITE

        if offsetX mod info.opts.width == info.opts.width - 1:
            if info.opts.showProgress:
                info.bar.inc(info.opts.width)
                info.bar.update

        x += info.xInc

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
        echo "Finished rendering image in ", bar[0].elapsed * 1000, " ms."

    return image

proc generateImageThreaded*(opts: GraphOpts): Image =
    var image = newImage(opts.width, opts.height)
    let imageAddr = image.addr

    let size = opts.width * opts.height
    let xInc: float = (opts.xMax - opts.xMin) / opts.width.float
    let yInc: float = (opts.yMax - opts.yMin) / opts.height.float

    var x = opts.xMin
    var y = opts.yMax

    var bar = initSuruBarThreaded()
    bar[0].total = size

    if opts.showProgress:
        bar.setup()

    var threads: seq[Thread[ThreadData]]
    newSeq(threads, opts.height)

    for offsetY in 0 ..< opts.height:
        let data = ThreadData(
            offsetY: offsetY,
            y: y,
            xInc: xInc,
            yInc: yInc,
            opts: opts,
            imageAddr: imageAddr,
            bar: bar
        )

        threads[offsetY].createThread(processRow, data)
        y -= yInc

    joinThreads(threads)

    if opts.showProgress:
        bar.finish()
        echo "Finished rendering image in ", bar[0].elapsed * 1000, " ms."

    return image