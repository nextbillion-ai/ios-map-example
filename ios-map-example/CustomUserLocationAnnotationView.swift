
import UIKit
import Nbmap

let CustomUserLocationDotSize: CGFloat = 10

class CustomUserLocationAnnotationView: NGLUserLocationAnnotationView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update() {
        updateFrame(with: intrinsicContentSize)
        setNeedsDisplay()
    }
    
    override var intrinsicContentSize: CGSize {
        let carSize = CGSize(width: 30, height: 60)
        return (mapView?.userTrackingMode == .followWithCourse) ? carSize : dotSize()
    }
    
    func dotSize() -> CGSize {
        let minDotSize: CGFloat = 30
        let dotSize = max(minDotSize, accuracyInPoints())
        return CGSize(width: dotSize, height: dotSize)
    }
    
    func updateFrame(with size: CGSize) {
        if frame.size.equalTo(size) {
            return
        }
        
        // Update frame size, keeping the existing center point.
        var newFrame = frame
        let oldCenter = center
        newFrame.size = size
        frame = newFrame
        center = oldCenter
    }
    
    func accuracyInPoints() -> CGFloat {
        guard let mapView = mapView, let userLocation = userLocation else {
            return 0
        }
        let metersPerPoint = mapView.metersPerPoint(atLatitude: userLocation.coordinate.latitude)
        return CGFloat((userLocation.location?.horizontalAccuracy ?? 0) / metersPerPoint)
    }
    
    override func draw(_ rect: CGRect) {
        if mapView?.userTrackingMode == .followWithCourse {
            drawCar()
        } else {
            drawDot()
        }
    }
    
    func drawDot() {
        // Accuracy
        let accuracy = accuracyInPoints()
        let center = bounds.size.width / 2.0 - accuracy / 2.0
        let accuracyPath = UIBezierPath(ovalIn: CGRect(x: center, y: center, width: accuracy, height: accuracy))
        let accuracyColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.4)
        accuracyColor.setFill()
        accuracyPath.fill()
        
        // Dot
        let dotCenter = bounds.size.width / 2.0 - CustomUserLocationDotSize / 2.0
        let dotPath = UIBezierPath(ovalIn: CGRect(x: dotCenter, y: dotCenter, width: CustomUserLocationDotSize, height: CustomUserLocationDotSize))
        UIColor.green.setFill()
        dotPath.fill()
        
        UIColor.black.setStroke()
        dotPath.lineWidth = 1
        dotPath.stroke()
        
        // Accuracy text
        let font = UIFont.systemFont(ofSize: 11)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .backgroundColor: UIColor(white: 0, alpha: 0.5),
            .foregroundColor: UIColor.white
        ]
        let accuracyText = NSString(format: "%.0f", accuracy)
        accuracyText.draw(at: CGPoint.zero, withAttributes: attributes)
    }
    
    func drawCar() {
        let fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        let strokeColor = UIColor(red: 0.592, green: 0.592, blue: 0.592, alpha: 1)
        let fillColor2 = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
        
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPoint(x: 30, y: 7.86))
        bezier2Path.addLine(to: CGPoint(x: 30, y: 52.66))
        bezier2Path.addCurve(to: CGPoint(x: 0, y: 52.66), controlPoint1: CGPoint(x: 30, y: 62.05), controlPoint2: CGPoint(x: 0, y: 62.84))
        bezier2Path.addCurve(to: CGPoint(x: 0, y: 7.86), controlPoint1: CGPoint(x: 0, y: 42.48), controlPoint2: CGPoint(x: 0, y: 17.89))
        bezier2Path.addCurve(to: CGPoint(x: 30, y: 7.86), controlPoint1: CGPoint(x: -0, y: -2.17), controlPoint2: CGPoint(x: 30, y: -3.05))
        bezier2Path.close()
        bezier2Path.usesEvenOddFillRule = true
        
        fillColor.setFill()
        bezier2Path.fill()
        
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPoint(x: 30, y: 7.86))
        bezier3Path.addLine(to: CGPoint(x: 30, y: 52.66))
        bezier3Path.addCurve(to: CGPoint(x: 0, y: 52.66), controlPoint1: CGPoint(x: 30, y: 62.05), controlPoint2: CGPoint(x: 0, y: 62.84))
        bezier3Path.addCurve(to: CGPoint(x: 0, y: 7.86), controlPoint1: CGPoint(x: 0, y: 42.48), controlPoint2: CGPoint(x: 0, y: 17.89))
        bezier3Path.addCurve(to: CGPoint(x: 30, y: 7.86), controlPoint1: CGPoint(x: 0, y: -2.17), controlPoint2: CGPoint(x: 30, y: -3.05))
        bezier3Path.close()
        strokeColor.setStroke()
        bezier3Path.lineWidth = 1
        bezier3Path.stroke()
        
        let bezier4Path = UIBezierPath()
        bezier4Path.move(to: CGPoint(x: 15.56, y: 4.26))
        bezier4Path.addCurve(to: CGPoint(x: 26, y: 6), controlPoint1: CGPoint(x: 21, y: 4.26), controlPoint2: CGPoint(x: 26, y: 6))
        bezier4Path.addCurve(to: CGPoint(x: 23, y: 21), controlPoint1: CGPoint(x: 26, y: 6), controlPoint2: CGPoint(x: 29, y: 17))
        bezier4Path.addCurve(to: CGPoint(x: 16, y: 21), controlPoint1: CGPoint(x: 20.03, y: 22.98), controlPoint2: CGPoint(x: 16, y: 21))
        bezier4Path.addCurve(to: CGPoint(x: 7, y: 21), controlPoint1: CGPoint(x: 16, y: 21), controlPoint2: CGPoint(x: 9.02, y: 23.53))
        bezier4Path.addCurve(to: CGPoint(x: 4, y: 6), controlPoint1: CGPoint(x: 3, y: 16), controlPoint2: CGPoint(x: 4, y: 6))
        bezier4Path.addCurve(to: CGPoint(x: 15.56, y: 4.26), controlPoint1: CGPoint(x: 4, y: 6), controlPoint2: CGPoint(x: 10.12, y: 4.26))
        bezier4Path.close()
        bezier4Path.usesEvenOddFillRule = true
        
        fillColor2.setFill()
        bezier4Path.fill()
        
        let rectanglePath = UIBezierPath()
        rectanglePath.move(to: CGPoint(x: 25, y: 46))
        rectanglePath.addCurve(to: CGPoint(x: 21, y: 55), controlPoint1: CGPoint(x: 31, y: 46), controlPoint2: CGPoint(x: 28.5, y: 55))
        rectanglePath.addCurve(to: CGPoint(x: 9, y: 55), controlPoint1: CGPoint(x: 13.5, y: 55), controlPoint2: CGPoint(x: 14, y: 55))
        rectanglePath.addCurve(to: CGPoint(x: 5, y: 46), controlPoint1: CGPoint(x: 4, y: 55), controlPoint2: CGPoint(x: 0, y: 46))
        rectanglePath.addCurve(to: CGPoint(x: 25, y: 46), controlPoint1: CGPoint(x: 10, y: 46), controlPoint2: CGPoint(x: 19, y: 46))
        rectanglePath.close()
        UIColor.white.setFill()
        rectanglePath.fill()
        
        let bezierPath = UIBezierPath()
        UIColor.white.setFill()
        bezierPath.fill()
        
        let rectangle2Path = UIBezierPath()
        rectangle2Path.move(to: CGPoint(x: 2, y: 35))
        rectangle2Path.addCurve(to: CGPoint(x: 4.36, y: 35), controlPoint1: CGPoint(x: 2, y: 39), controlPoint2: CGPoint(x: 4.36, y: 35))
        rectangle2Path.addCurve(to: CGPoint(x: 4.36, y: 22), controlPoint1: CGPoint(x: 4.36, y: 35), controlPoint2: CGPoint(x: 5.55, y: 26))
        rectangle2Path.addCurve(to: CGPoint(x: 2, y: 22), controlPoint1: CGPoint(x: 3.18, y: 18), controlPoint2: CGPoint(x: 2, y: 22))
        rectangle2Path.addCurve(to: CGPoint(x: 2, y: 35), controlPoint1: CGPoint(x: 2, y: 22), controlPoint2: CGPoint(x: 2, y: 31))
        rectangle2Path.close()
        UIColor.white.setFill()
        rectangle2Path.fill()
        
        let rectangle3Path = UIBezierPath()
        rectangle3Path.move(to: CGPoint(x: 28, y: 35))
        rectangle3Path.addCurve(to: CGPoint(x: 25.64, y: 35), controlPoint1: CGPoint(x: 28, y: 39), controlPoint2: CGPoint(x: 25.64, y: 35))
        rectangle3Path.addCurve(to: CGPoint(x: 25.64, y: 22), controlPoint1: CGPoint(x: 25.64, y: 35), controlPoint2: CGPoint(x: 24.45, y:26))
        rectangle3Path.addCurve(to: CGPoint(x: 28, y: 22), controlPoint1: CGPoint(x: 25.82, y: 18), controlPoint2: CGPoint(x: 28, y:22))
        rectangle3Path.addCurve(to: CGPoint(x: 28, y: 35), controlPoint1: CGPoint(x: 28, y: 22), controlPoint2: CGPoint(x: 28, y:31))
        rectangle3Path.close()
        UIColor.white.setFill()
        rectangle3Path.fill()
    }
}
