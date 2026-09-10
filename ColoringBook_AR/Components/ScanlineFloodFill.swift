import Foundation
import UIKit
import CoreGraphics

/// High-performance Scanline Flood Fill Engine operating on a direct 32-bit RGBA pixel buffer.
/// Strictly protects black line-art strokes (luminance < threshold) and avoids recursion.
public final class ScanlineFloodFill: @unchecked Sendable {

    /// Threshold below which a pixel is considered black line-art boundary (0...255)
    public static let blackLineThreshold: UInt8 = 65

    /// Color match tolerance for anti-aliasing tolerance (0...255)
    public static let colorTolerance: Int = 32

    /// Executes scanline flood fill on `image` at tap point `(startX, startY)` with `fillColor`.
    /// Returns modified `UIImage` or nil if tap was invalid or on a line-art boundary.
    public static func fill(
        image: UIImage,
        atPoint startPoint: CGPoint,
        withColor fillColor: UIColor
    ) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height

        let startX = Int(startPoint.x)
        let startY = Int(startPoint.y)

        guard startX >= 0 && startX < width && startY >= 0 && startY < height else {
            return nil
        }

        // Allocate RGBA8888 32-bit pixel buffer
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow

        var pixelData = Data(count: totalBytes)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue

        let context = pixelData.withUnsafeMutableBytes { (rawPtr: UnsafeMutableRawBufferPointer) -> CGContext? in
            guard let baseAddress = rawPtr.baseAddress else { return nil }
            return CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo
            )
        }

        guard let ctx = context else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Parse Fill Color RGBA (0...255)
        var fR: CGFloat = 0, fG: CGFloat = 0, fB: CGFloat = 0, fA: CGFloat = 0
        fillColor.getRed(&fR, green: &fG, blue: &fB, alpha: &fA)
        let fillR = UInt8(clamping: Int(fR * 255))
        let fillG = UInt8(clamping: Int(fG * 255))
        let fillB = UInt8(clamping: Int(fB * 255))
        let fillA = UInt8(clamping: Int(fA * 255))

        // Combine fill color into UInt32 (RGBA Big Endian)
        let fillPixel: UInt32 = (UInt32(fillR) << 24) | (UInt32(fillG) << 16) | (UInt32(fillB) << 8) | UInt32(fillA)

        // Perform in-place flood fill on pixel buffer
        let success = pixelData.withUnsafeMutableBytes { (rawPtr: UnsafeMutableRawBufferPointer) -> Bool in
            guard let pixels = rawPtr.bindMemory(to: UInt32.self).baseAddress else { return false }

            let startIndex = startY * width + startX
            let startPixel = pixels[startIndex]

            let sR = UInt8((startPixel >> 24) & 0xFF)
            let sG = UInt8((startPixel >> 16) & 0xFF)
            let sB = UInt8((startPixel >> 8) & 0xFF)

            // 1. Black line boundary check: do NOT fill black lines
            let startLum = (Int(sR) * 299 + Int(sG) * 587 + Int(sB) * 114) / 1000
            if startLum < Int(blackLineThreshold) {
                return false
            }

            // 2. Identity check: do not refill identical color
            if isSameColor(c1: startPixel, c2: fillPixel, tolerance: 10) {
                return false
            }

            // 3. Scanline Flood Fill Algorithm with iterative stack
            var stack: [Int] = [startX, startY]
            stack.reserveCapacity(width * 2)

            while !stack.isEmpty {
                let y = stack.removeLast()
                var x = stack.removeLast()

                var x1 = x
                while x1 > 0 {
                    let nextIdx = y * width + (x1 - 1)
                    let p = pixels[nextIdx]
                    if !canColor(pixel: p, targetPixel: startPixel) {
                        break
                    }
                    x1 -= 1
                }

                var x2 = x
                while x2 < width - 1 {
                    let nextIdx = y * width + (x2 + 1)
                    let p = pixels[nextIdx]
                    if !canColor(pixel: p, targetPixel: startPixel) {
                        break
                    }
                    x2 += 1
                }

                // Fill scanline [x1, x2] at row y
                let rowOffset = y * width
                for fillX in x1...x2 {
                    pixels[rowOffset + fillX] = fillPixel
                }

                // Inspect adjacent row above (y - 1)
                if y > 0 {
                    scanRow(y: y - 1, x1: x1, x2: x2, width: width, pixels: pixels, targetPixel: startPixel, stack: &stack)
                }

                // Inspect adjacent row below (y + 1)
                if y < height - 1 {
                    scanRow(y: y + 1, x1: x1, x2: x2, width: width, pixels: pixels, targetPixel: startPixel, stack: &stack)
                }
            }

            return true
        }

        guard success else { return nil }

        // Render back to CGImage and UIImage
        guard let outputCGImage = ctx.makeImage() else { return nil }
        return UIImage(cgImage: outputCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Scanline Helpers

    @inline(__always)
    private static func scanRow(
        y: Int,
        x1: Int,
        x2: Int,
        width: Int,
        pixels: UnsafeMutablePointer<UInt32>,
        targetPixel: UInt32,
        stack: inout [Int]
    ) {
        var inSpan = false
        let rowOffset = y * width

        for x in x1...x2 {
            let p = pixels[rowOffset + x]
            let match = canColor(pixel: p, targetPixel: targetPixel)

            if !inSpan && match {
                stack.append(x)
                stack.append(y)
                inSpan = true
            } else if inSpan && !match {
                inSpan = false
            }
        }
    }

    @inline(__always)
    private static func canColor(pixel: UInt32, targetPixel: UInt32) -> Bool {
        let r = UInt8((pixel >> 24) & 0xFF)
        let g = UInt8((pixel >> 16) & 0xFF)
        let b = UInt8((pixel >> 8) & 0xFF)

        // Line art protection: do NOT color over black/dark line art
        let lum = (Int(r) * 299 + Int(g) * 587 + Int(b) * 114) / 1000
        if lum < Int(blackLineThreshold) {
            return false
        }

        return isSameColor(c1: pixel, c2: targetPixel, tolerance: colorTolerance)
    }

    @inline(__always)
    private static func isSameColor(c1: UInt32, c2: UInt32, tolerance: Int) -> Bool {
        if c1 == c2 { return true }
        let r1 = Int((c1 >> 24) & 0xFF)
        let g1 = Int((c1 >> 16) & 0xFF)
        let b1 = Int((c1 >> 8) & 0xFF)

        let r2 = Int((c2 >> 24) & 0xFF)
        let g2 = Int((c2 >> 16) & 0xFF)
        let b2 = Int((c2 >> 8) & 0xFF)

        return abs(r1 - r2) <= tolerance && abs(g1 - g2) <= tolerance && abs(b1 - b2) <= tolerance
    }
}
