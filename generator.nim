
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
    xMin*, yMax*, xInc*, yInc*: float
    offsetStart*, offsetEnd*: int
    opts*: GraphOpts
    imageAddr*: ptr Image
    bar*: ptr SuruBarController

proc processRow(data: ThreadData) =
    let info = data[]

    var image = info.imageAddr[]

    var x = info.xMin
    var y = info.yMax

    for offset in info.offsetStart ..< info.offsetEnd:
        let clr = subpixelMatch(x, y, info.xInc, info.yInc, info.opts.threshold, info.opts.maybeThreshold, info.opts.subdivisions)

        image.data[offset] = case clr
            of true: BLACK
            else: WHITE

        if offset mod info.opts.width == info.opts.width - 1:
            if info.opts.showProgress:
                info.bar.inc(info.opts.width)
                info.bar.update

            y -= info.yInc
            x = info.opts.xMin

        x += info.xInc

proc generateImageThreaded*(opts: GraphOpts, tc: int = 24): Image =
    var image = newImage(opts.width, opts.height)
    let imageAddr = image.addr

    let threadCount = min(tc, opts.height)
    let threadSize = opts.height.div(threadCount)
    let remaining = opts.height - threadSize * threadCount

    let size = opts.width * opts.height
    let xInc: float = (opts.xMax - opts.xMin) / opts.width.float
    let yInc: float = (opts.yMax - opts.yMin) / opts.height.float

    var y = opts.yMax

    var bar = initSuruBarThreaded()
    bar[0].total = size

    if opts.showProgress:
        bar.setup()

    var threads: seq[Thread[ThreadData]]
    newSeq(threads, threadCount + 1)

    for thread in 0 ..< threadCount:
        let data = ThreadData(
            xMin: opts.xMin,
            yMax: y,
            xInc: xInc,
            yInc: yInc,
            offsetStart: thread * threadSize * opts.width,
            offsetEnd: (thread + 1) * threadSize * opts.width,
            opts: opts,
            imageAddr: imageAddr,
            bar: bar
        )

        threads[thread].createThread(processRow, data)
        y -= threadSize.float * yInc

    if remaining > 0:
        let data = ThreadData(
            xMin: opts.xMin,
            yMax: y,
            xInc: xInc,
            yInc: yInc,
            offsetStart: threadCount * threadSize * opts.width,
            offsetEnd: opts.width * opts.height,
            opts: opts,
            imageAddr: imageAddr,
            bar: bar
        )

        threads[threadCount].createThread(processRow, data)
        y -= threadSize.float * yInc

    joinThreads(threads)

    if opts.showProgress:
        bar.finish()
        echo "Finished rendering image in ", bar[0].elapsed * 1000, " ms."

    return image

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