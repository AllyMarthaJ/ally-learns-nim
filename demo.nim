import times, math, strutils, sequtils, strformat, pixie, os, sugar

const X_MIN: float = -1
const X_MAX: float = 1
const Y_MIN: float = -1
const Y_MAX: float = 1

const BLACK = rgb(0, 0, 0).asRgbx
const WHITE = rgb(255, 255, 255).asRgbx

const THRESHOLD: float = 10.float.pow(-4)
const MAYBE_THRESHOLD: float = 10.float.pow(-1)

proc fn(x: float, y: float): float =
    return (y-sin(x))*(max(abs(x+y)+abs(x-y)-1,0)+max(0.25-x^2-y^2,0))

proc subpixelMatch(x: float, y: float, xInc: float, yInc: float, subdivisions: int): bool =
    if abs(fn(x, y)) <= THRESHOLD:
        return true

    if abs(fn(x, y)) > MAYBE_THRESHOLD:
        return false

    let uInc: float = xInc / subdivisions.float
    let vInc: float = yInc / subdivisions.float

    var u = x
    var v = y + yInc

    for offset in countup(0, subdivisions ^ 2 - 1):
        if abs(fn(u, v)) <= THRESHOLD:
            return true

        if offset mod subdivisions == 0:
            v -= vInc
            u = x

        u += uInc

    return false

proc generateImage*(width: int, height: int): Image =
    var image = newImage(width, height)

    let size = width * height
    let xInc: float = (X_MAX - X_MIN) / width.float
    let yInc: float = (Y_MAX - Y_MIN) / height.float

    var x = X_MIN
    var y = Y_MAX

    for offset in countup(0, size - 1):
        image.data[offset] = case subpixelMatch(x, y, xInc, yInc, 10)
                of true: BLACK
                else: WHITE

        if offset mod width == 0:
            y -= yInc
            x = X_MIN

        x += xInc

    return image

proc testFunctionImage =
    for exponent in countup(0, 15):
        var times: array[0..9, int64]

        for round in countup(0, 9):
            let t0 = getTime()

            discard generateImage(2^exponent, 2^exponent)

            let delta = getTime() - t0

            times[round] = delta.inMilliseconds

        let average = times.foldl(a + b, 0.int64).float / 10.0

        # echo 2^exponent, " -- ", "times: ", msg, "ms : ", average, "ms average"
        echo fmt"{2^exponent}x{2^exponent} yields average {average} ms."

# testFunctionImage()
let t0 = getTime()
let image = generateImage(2048, 2048)
let delta = (getTime() - t0).inMilliseconds

echo "Wrote image in ", delta, " ms."

image.writeFile("output.png")
discard execShellCmd("open output.png")