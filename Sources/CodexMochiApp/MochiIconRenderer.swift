import AppKit

enum MochiIconRenderer {
    static func image(
        remainingPercent: Double?,
        burnUrgency: Int,
        phase: Int,
        hasError: Bool,
        isLoading: Bool
    ) -> NSImage {
        let size = NSSize(width: 20, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            let context = NSGraphicsContext.current?.cgContext
            context?.setShouldAntialias(true)

            let quotaUrgency: Int
            if hasError { quotaUrgency = 0 }
            else if let remainingPercent, remainingPercent < 20 { quotaUrgency = 3 }
            else if let remainingPercent, remainingPercent < 50 { quotaUrgency = 2 }
            else { quotaUrgency = 1 }
            let urgency = min(4, max(quotaUrgency, burnUrgency))

            let step = urgency >= 3 ? phase : (urgency == 2 ? phase / 2 : phase / 4)
            let bob = step.isMultiple(of: 2) ? CGFloat(0) : CGFloat(1)
            let blink = !hasError && !isLoading && phase % 17 == 0
            let originY = 2 + bob

            NSColor.labelColor.setStroke()
            NSColor.labelColor.setFill()

            let head = NSBezierPath(roundedRect: NSRect(x: 3, y: originY, width: 14, height: 12), xRadius: 5, yRadius: 5)
            head.lineWidth = 1.45
            head.stroke()

            let leftEar = NSBezierPath()
            leftEar.move(to: NSPoint(x: 4.2, y: originY + 9.5))
            leftEar.line(to: NSPoint(x: 5.2, y: originY + 14))
            leftEar.line(to: NSPoint(x: 8, y: originY + 11.5))
            leftEar.lineWidth = 1.45
            leftEar.lineJoinStyle = .round
            leftEar.stroke()

            let rightEar = NSBezierPath()
            rightEar.move(to: NSPoint(x: 12, y: originY + 11.5))
            rightEar.line(to: NSPoint(x: 14.8, y: originY + 14))
            rightEar.line(to: NSPoint(x: 15.8, y: originY + 9.5))
            rightEar.lineWidth = 1.45
            rightEar.lineJoinStyle = .round
            rightEar.stroke()

            if hasError {
                drawLine(from: NSPoint(x: 7, y: originY + 7), to: NSPoint(x: 9, y: originY + 5))
                drawLine(from: NSPoint(x: 9, y: originY + 7), to: NSPoint(x: 7, y: originY + 5))
                drawLine(from: NSPoint(x: 11, y: originY + 7), to: NSPoint(x: 13, y: originY + 5))
                drawLine(from: NSPoint(x: 13, y: originY + 7), to: NSPoint(x: 11, y: originY + 5))
            } else if isLoading {
                let dot = NSBezierPath(ovalIn: NSRect(x: CGFloat(6 + phase % 7), y: originY + 5.5, width: 1.4, height: 1.4))
                dot.fill()
            } else if blink {
                drawLine(from: NSPoint(x: 6.5, y: originY + 6), to: NSPoint(x: 8.5, y: originY + 6))
                drawLine(from: NSPoint(x: 11.5, y: originY + 6), to: NSPoint(x: 13.5, y: originY + 6))
            } else {
                NSBezierPath(ovalIn: NSRect(x: 7, y: originY + 5.5, width: 1.45, height: 2)).fill()
                NSBezierPath(ovalIn: NSRect(x: 11.55, y: originY + 5.5, width: 1.45, height: 2)).fill()
            }

            let mouth = NSBezierPath()
            mouth.move(to: NSPoint(x: 8.7, y: originY + 3.8))
            mouth.curve(
                to: NSPoint(x: 11.3, y: originY + 3.8),
                controlPoint1: NSPoint(x: 9.2, y: originY + 2.7),
                controlPoint2: NSPoint(x: 10.8, y: originY + 2.7)
            )
            mouth.lineWidth = 1
            mouth.stroke()

            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Mochi cat"
        return image
    }

    private static func drawLine(from: NSPoint, to: NSPoint) {
        let path = NSBezierPath()
        path.move(to: from)
        path.line(to: to)
        path.lineWidth = 1.1
        path.lineCapStyle = .round
        path.stroke()
    }
}
