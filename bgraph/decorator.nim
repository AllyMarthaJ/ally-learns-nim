import pixie, std/options, strformat
import generator, constants

type DataOpts* = ref object
    showXAxis*, showYAxis*, showXGrid*, showYGrid*, showAttribution*: bool
    xInc*, yInc*, axisWidth*, gridWidth*: float
    fontFile*, axisColor*, gridColor*, author*: string

proc createLerp(x0: float, y0: float, x1: float, y1: float): proc(
        x: float): float =
    let lCoeff = (y1 - y0) / (x1 - x0)
    return proc(x: float): float =
        y0 + lCoeff * (x - x0)

proc getTAxis(tMin: float, tMax: float, size: int): Option[float] =
    let lerp = createLerp(tMin, 0, tMax, size.float)

    let lerpValue = lerp(0)

    if lerpValue < 0 or lerpValue > size.float:
        return none(float)

    return some(lerpValue)

proc newFont(tf: Typeface, size: float32, color: Color): Font =
    result = newFont(tf)
    result.size = size
    result.paint.color = color

proc decorateGraph*(gData: DataOpts, gOpts: GraphOpts, img: ptr Image) =
    let imgContext = newContext(img[])

    # Axes
    imgContext.strokeStyle = gData.axisColor
    imgContext.lineWidth = gData.axisWidth

    let optionalXAxisPoint = getTAxis(gOpts.xMin, gOpts.xMax, gOpts.width)
    let optionalYAxisPoint = getTAxis(gOpts.yMax, gOpts.yMin, gOpts.height)

    if gData.showXAxis and optionalXAxisPoint.isSome:
        let xAxisPoint: float = optionalXAxisPoint.get
        imgContext.strokeSegment(segment(vec2(xAxisPoint, 0), vec2(xAxisPoint,
                gOpts.height.float)))

    if gData.showYAxis and optionalYAxisPoint.isSome:
        let yAxisPoint: float = optionalYAxisPoint.get
        imgContext.strokeSegment(segment(vec2(0, yAxisPoint), vec2(
                gOpts.width.float, yAxisPoint)))

    # Grids
    imgContext.strokeStyle = gData.gridColor
    imgContext.lineWidth = gData.gridWidth

    if gData.showXGrid and optionalXAxisPoint.isSome:
        var x: float = optionalXAxisPoint.get
        let coordXInc = gData.xInc * gOpts.width.float / (gOpts.xMax - gOpts.xMin)

        while x > 0:
            x -= coordXInc

            imgContext.strokeSegment(segment(vec2(x, 0), vec2(x,
                    gOpts.height.float)))

        x = optionalXAxisPoint.get

        while x < gOpts.width.float:
            x += coordXInc

            imgContext.strokeSegment(segment(vec2(x, 0), vec2(x,
                    gOpts.height.float)))

    if gData.showYGrid and optionalYAxisPoint.isSome:
        var y: float = optionalYAxisPoint.get
        let coordYInc = gData.yInc * gOpts.height.float / (gOpts.yMax - gOpts.yMin)

        while y > 0:
            y -= coordYInc

            imgContext.strokeSegment(segment(vec2(0, y), vec2(gOpts.width.float, y)))

        y = optionalYAxisPoint.get

        while y < gOpts.height.float:
            y += coordYInc

            imgContext.strokeSegment(segment(vec2(0, y), vec2(gOpts.width.float, y)))

    # Attribution
    let tf = readTypeface(gData.fontFile)

    let fontFactor = 0.01
    let baseSize = fontFactor * gOpts.height.float
    let spans = @[
        newSpan(&"{gData.author}\n", newFont(tf, 2 * baseSize, color(0, 0, 0))),
        newSpan(&"{GRAPH_FN_NAME}\n", newFont(tf, baseSize, color(0, 0, 0))),
        newSpan(&"\nDomain: ({gOpts.xMin}, {gOpts.xMax})x({gOpts.yMin}, {gOpts.yMax})\n", newFont(tf, baseSize, color(0, 0, 0))),
        newSpan(&"Dimensions: {gOpts.width}x{gOpts.height}\n", newFont(tf, baseSize, color(0, 0, 0))),
        newSpan(&"Thresholds: {gOpts.threshold}, {gOpts.maybeThreshold}", newFont(tf, baseSize, color(0, 0, 0))),
        newSpan(&"Subdivisions: {gOpts.subdivisions}", newFont(tf, baseSize, color(0, 0, 0))),
    ]
    let spanArrangement = typeset(spans)

    imgContext.fillStyle = color(0,0,0,0.1)
    imgContext.fillRect(rect(10, 10, spanArrangement.layoutBounds.x, spanArrangement.layoutBounds.y))

    img[].fillText(spanArrangement, translate(vec2(10, 10)))
