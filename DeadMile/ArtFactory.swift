import UIKit
import SpriteKit

enum ArtFactory {
    static func vehicle(colorHex: String, scale: CGFloat = 1) -> SKTexture {
        let size = CGSize(width: 260 * scale, height: 112 * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            let body = UIBezierPath()
            body.move(to: CGPoint(x: 16*scale,y: 26*scale))
            body.addLine(to: CGPoint(x: 28*scale,y: 62*scale))
            body.addQuadCurve(to: CGPoint(x: 76*scale,y: 86*scale), controlPoint: CGPoint(x: 42*scale,y: 91*scale))
            body.addLine(to: CGPoint(x: 178*scale,y: 86*scale))
            body.addQuadCurve(to: CGPoint(x: 222*scale,y: 54*scale), controlPoint: CGPoint(x: 218*scale,y: 84*scale))
            body.addLine(to: CGPoint(x: 244*scale,y: 27*scale))
            body.close()
            let color = UIColor(hex: colorHex)
            c.saveGState()
            c.addPath(body.cgPath)
            c.clip()
            let colors = [color.withAlphaComponent(1).cgColor, color.darker().cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0,1]) {
                c.drawLinearGradient(gradient, start: CGPoint(x:0,y:90*scale), end: CGPoint(x:0,y:20*scale), options: [])
            }
            c.restoreGState()
            c.setStrokeColor(UIColor.black.withAlphaComponent(0.85).cgColor)
            c.setLineWidth(5*scale)
            c.addPath(body.cgPath); c.strokePath()
            let window = UIBezierPath(roundedRect: CGRect(x:78*scale,y:65*scale,width:80*scale,height:23*scale), cornerRadius: 5*scale)
            UIColor(red:0.10,green:0.17,blue:0.2,alpha:1).setFill(); window.fill()
            UIColor.white.withAlphaComponent(0.5).setStroke(); window.lineWidth=2*scale; window.stroke()
            for x in [62,194] {
                let wheel = CGRect(x:CGFloat(x)*scale,y:3*scale,width:47*scale,height:47*scale)
                UIColor(white:0.08,alpha:1).setFill(); UIBezierPath(ovalIn:wheel).fill()
                UIColor(white:0.48,alpha:1).setStroke()
                let rim=UIBezierPath(ovalIn:wheel.insetBy(dx:8*scale,dy:8*scale)); rim.lineWidth=4*scale; rim.stroke()
                UIColor(white:0.68,alpha:1).setFill()
                UIBezierPath(ovalIn:wheel.insetBy(dx:19*scale,dy:19*scale)).fill()
            }
            UIColor(red:1,green:0.83,blue:0.45,alpha:1).setFill()
            UIBezierPath(roundedRect:CGRect(x:232*scale,y:39*scale,width:12*scale,height:10*scale),cornerRadius:3*scale).fill()
            UIColor(red:0.65,green:0.08,blue:0.05,alpha:1).setFill()
            UIBezierPath(roundedRect:CGRect(x:16*scale,y:38*scale,width:10*scale,height:13*scale),cornerRadius:2*scale).fill()
            for i in 0..<5 {
                UIColor.black.withAlphaComponent(0.25).setFill()
                UIBezierPath(ovalIn:CGRect(x:CGFloat(36+i*17)*scale,y:54*scale,width:5*scale,height:3*scale)).fill()
            }
        }
        return SKTexture(image: image)
    }

    static func zombie(variant: Int) -> SKTexture {
        let size = CGSize(width: 64, height: 92)
        let image = UIGraphicsImageRenderer(size:size).image { _ in
            let skin = [UIColor(red:0.55,green:0.68,blue:0.43,alpha:1), UIColor(red:0.64,green:0.57,blue:0.43,alpha:1), UIColor(red:0.39,green:0.55,blue:0.48,alpha:1)][variant % 3]
            let shirt = [UIColor(red:0.35,green:0.18,blue:0.16,alpha:1), UIColor(red:0.19,green:0.25,blue:0.3,alpha:1), UIColor(red:0.38,green:0.34,blue:0.18,alpha:1)][variant % 3]
            let torso=UIBezierPath(roundedRect:CGRect(x:18,y:36,width:30,height:38),cornerRadius:7)
            shirt.setFill(); torso.fill(); UIColor.black.setStroke(); torso.lineWidth=3; torso.stroke()
            let head=UIBezierPath(ovalIn:CGRect(x:21,y:8,width:26,height:29))
            skin.setFill(); head.fill(); UIColor.black.setStroke(); head.lineWidth=3; head.stroke()
            for x in [28,39] { UIColor(red:0.85,green:0.12,blue:0.08,alpha:1).setFill(); UIBezierPath(ovalIn:CGRect(x:x,y:19,width:5,height:4)).fill() }
            let arm1=UIBezierPath(); arm1.move(to:CGPoint(x:19,y:43)); arm1.addLine(to:CGPoint(x:5,y:65))
            let arm2=UIBezierPath(); arm2.move(to:CGPoint(x:46,y:43)); arm2.addLine(to:CGPoint(x:59,y:61))
            UIColor.black.setStroke(); arm1.lineWidth=10; arm2.lineWidth=10; arm1.stroke(); arm2.stroke()
            skin.setStroke(); arm1.lineWidth=6; arm2.lineWidth=6; arm1.stroke(); arm2.stroke()
            for x in [24,39] {
                let leg=UIBezierPath(); leg.move(to:CGPoint(x:x,y:70)); leg.addLine(to:CGPoint(x:x-4,y:89))
                UIColor.black.setStroke(); leg.lineWidth=10; leg.stroke()
                UIColor(white:0.16,alpha:1).setStroke(); leg.lineWidth=6; leg.stroke()
            }
        }
        return SKTexture(image:image)
    }
}

private extension UIColor {
    convenience init(hex: String) {
        let value = UInt(hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted), radix:16) ?? 0xA65F3D
        self.init(red:CGFloat((value>>16)&255)/255,green:CGFloat((value>>8)&255)/255,blue:CGFloat(value&255)/255,alpha:1)
    }
    func darker() -> UIColor { var h: CGFloat=0,s:CGFloat=0,b:CGFloat=0,a:CGFloat=0; getHue(&h,saturation:&s,brightness:&b,alpha:&a); return UIColor(hue:h,saturation:s,brightness:b*0.58,alpha:a) }
}
