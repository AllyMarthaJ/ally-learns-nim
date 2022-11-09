import times, math, strutils, sequtils, strformat, pixie, os, sugar

const X_MIN: float = -1
const X_MAX: float = 1
const Y_MIN: float = -1
const Y_MAX: float = 1

const BLACK = rgb(0, 0, 0).asRgbx
const WHITE = rgb(255, 255, 255).asRgbx

proc functionImage*(width: int, height: int): seq[int] =
    var size = width * height
    var image = newSeq[int](size)

    let xInc: float = (X_MAX - X_MIN) / width.float
    let yInc: float = (Y_MAX - Y_MIN) / height.float

    var x = X_MIN
    var y = Y_MIN

    for tmpX in countup(0, width - 1):
        y = Y_MAX

        for tmpY in countup(0, height - 1):
            let offset = tmpY * width + tmpX

            image[offset] = case abs(y - x) <= 0.01
                of true: 1
                else: 0
            y -= yInc

        x += xInc

    return image

proc generateImage*(width: int, height: int): Image =
    var image = newImage(width, height)

    let xInc: float = (X_MAX - X_MIN) / width.float
    let yInc: float = (Y_MAX - Y_MIN) / height.float

    var x = X_MIN
    var y = Y_MAX

    for tmpX in countup(0, width - 1):
        y = Y_MAX

        for tmpY in countup(0, height - 1):
            let offset = tmpY * width + tmpX

            image.data[offset] = case abs((y-sin(x))*(max(abs(x+y)+abs(x-y)-1,0)+max(0.25-x^2-y^2,0))) <= 0.01
                of true: BLACK
                else: WHITE
            y -= yInc

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
let image = generateImage(1024, 1024)
let delta = (getTime() - t0).inMilliseconds

echo "Wrote image in ", delta, " ms."

image.writeFile("output.png")
discard execShellCmd("open output.png")