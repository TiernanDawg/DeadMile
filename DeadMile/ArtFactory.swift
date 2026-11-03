import UIKit
import SpriteKit

enum ArtFactory {
    static func vehicle(colorHex: String, scale: CGFloat = 1, style: Int = 0) -> SKTexture {
        let size = CGSize(width: 260 * scale, height: 112 * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            let c = ctx.cgContext
            c.translateBy(x:0,y:size.height)
            c.scaleBy(x:1,y:-1)
            let body: UIBezierPath
            switch style {
            case 2:
                body = UIBezierPath(roundedRect:CGRect(x:12*scale,y:21*scale,width:238*scale,height:70*scale),cornerRadius:9*scale)
            case 3:
                body = UIBezierPath()
                body.move(to:CGPoint(x:13*scale,y:27*scale))
                body.addLine(to:CGPoint(x:34*scale,y:57*scale))
                body.addQuadCurve(to:CGPoint(x:91*scale,y:78*scale),controlPoint:CGPoint(x:55*scale,y:84*scale))
                body.addLine(to:CGPoint(x:166*scale,y:78*scale))
                body.addQuadCurve(to:CGPoint(x:220*scale,y:55*scale),controlPoint:CGPoint(x:207*scale,y:80*scale))
                body.addLine(to:CGPoint(x:248*scale,y:27*scale))
                body.close()
            case 4:
                body = UIBezierPath(roundedRect:CGRect(x:8*scale,y:20*scale,width:244*scale,height:73*scale),cornerRadius:7*scale)
            case 5:
                body = UIBezierPath()
                body.move(to:CGPoint(x:12*scale,y:24*scale))
                body.addLine(to:CGPoint(x:18*scale,y:62*scale))
                body.addLine(to:CGPoint(x:46*scale,y:70*scale))
                body.addLine(to:CGPoint(x:68*scale,y:88*scale))
                body.addLine(to:CGPoint(x:156*scale,y:88*scale))
                body.addLine(to:CGPoint(x:186*scale,y:61*scale))
                body.addLine(to:CGPoint(x:243*scale,y:55*scale))
                body.addLine(to:CGPoint(x:250*scale,y:24*scale))
                body.close()
            case 6,9:
                body = UIBezierPath()
                body.move(to:CGPoint(x:8*scale,y:24*scale))
                body.addLine(to:CGPoint(x:22*scale,y:68*scale))
                body.addLine(to:CGPoint(x:52*scale,y:88*scale))
                body.addLine(to:CGPoint(x:195*scale,y:88*scale))
                body.addLine(to:CGPoint(x:229*scale,y:70*scale))
                body.addLine(to:CGPoint(x:252*scale,y:24*scale))
                body.close()
            case 7:
                body = UIBezierPath()
                body.move(to:CGPoint(x:8*scale,y:22*scale))
                body.addLine(to:CGPoint(x:55*scale,y:22*scale))
                body.addLine(to:CGPoint(x:55*scale,y:63*scale))
                body.addLine(to:CGPoint(x:82*scale,y:88*scale))
                body.addLine(to:CGPoint(x:238*scale,y:88*scale))
                body.addLine(to:CGPoint(x:250*scale,y:60*scale))
                body.addLine(to:CGPoint(x:243*scale,y:22*scale))
                body.close()
            case 8:
                body = UIBezierPath(roundedRect:CGRect(x:11*scale,y:21*scale,width:239*scale,height:75*scale),cornerRadius:17*scale)
            default:
                body = UIBezierPath()
                body.move(to: CGPoint(x: 16*scale,y: 26*scale))
                body.addLine(to: CGPoint(x: 28*scale,y: 62*scale))
                body.addQuadCurve(to: CGPoint(x: 76*scale,y: 86*scale), controlPoint: CGPoint(x: 42*scale,y: 91*scale))
                body.addLine(to: CGPoint(x: 178*scale,y: 86*scale))
                body.addQuadCurve(to: CGPoint(x: 222*scale,y: 54*scale), controlPoint: CGPoint(x: 218*scale,y: 84*scale))
                body.addLine(to: CGPoint(x: 244*scale,y: 27*scale))
                body.close()
            }
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
            let window = UIBezierPath(roundedRect: CGRect(x:style == 4 ? 44*scale : 78*scale,y:65*scale,width:style == 4 ? 38*scale : 80*scale,height:23*scale), cornerRadius: 5*scale)
            UIColor(red:0.10,green:0.17,blue:0.2,alpha:1).setFill(); window.fill()
            UIColor.white.withAlphaComponent(0.5).setStroke(); window.lineWidth=2*scale; window.stroke()
            if style == 4 {
                for x in stride(from:92,through:220,by:31) {
                    UIColor(red:0.10,green:0.17,blue:0.2,alpha:1).setFill()
                    UIBezierPath(rect:CGRect(x:CGFloat(x)*scale,y:64*scale,width:17*scale,height:19*scale)).fill()
                }
            }
            if [1,5,8,9].contains(style) {
                c.setStrokeColor(UIColor(white:0.62,alpha:1).cgColor)
                c.setLineWidth(5*scale)
                c.move(to:CGPoint(x:72*scale,y:88*scale))
                c.addLine(to:CGPoint(x:82*scale,y:103*scale))
                c.addLine(to:CGPoint(x:166*scale,y:103*scale))
                c.addLine(to:CGPoint(x:178*scale,y:86*scale))
                c.strokePath()
            }
            if [2,6,7,9].contains(style) {
                UIColor(red:0.24,green:0.25,blue:0.23,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:92*scale,y:87*scale,width:72*scale,height:17*scale),cornerRadius:3*scale).fill()
                UIColor(white:0.68,alpha:1).setStroke()
                let rack=UIBezierPath(rect:CGRect(x:87*scale,y:85*scale,width:82*scale,height:20*scale))
                rack.lineWidth=3*scale; rack.stroke()
            }
            if [3,7].contains(style) {
                UIColor(red:0.92,green:0.2,blue:0.12,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:93*scale,y:91*scale,width:15*scale,height:8*scale),cornerRadius:2*scale).fill()
                UIColor(red:0.2,green:0.65,blue:0.95,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:132*scale,y:91*scale,width:15*scale,height:8*scale),cornerRadius:2*scale).fill()
            }
            if style >= 5 {
                UIColor(white:0.28,alpha:1).setFill()
                let plate=UIBezierPath(roundedRect:CGRect(x:198*scale,y:22*scale,width:48*scale,height:14*scale),cornerRadius:3*scale)
                plate.fill()
                UIColor(white:0.72,alpha:1).setStroke(); plate.lineWidth=2*scale; plate.stroke()
            }

            c.setStrokeColor(UIColor.black.withAlphaComponent(0.65).cgColor)
            c.setLineWidth(2*scale)
            c.move(to:CGPoint(x:158*scale,y:36*scale))
            c.addLine(to:CGPoint(x:158*scale,y:75*scale))
            c.strokePath()
            let doorHandle=UIBezierPath(roundedRect:CGRect(x:142*scale,y:45*scale,width:12*scale,height:3*scale),cornerRadius:1.5*scale)
            UIColor(white:0.84,alpha:0.8).setFill(); doorHandle.fill()
            for x in [40,52,170,182] {
                UIColor(white:0.78,alpha:0.8).setFill()
                UIBezierPath(ovalIn:CGRect(x:CGFloat(x)*scale,y:52*scale,width:4*scale,height:4*scale)).fill()
            }
            c.setStrokeColor(UIColor(white:0.68,alpha:0.9).cgColor)
            c.setLineWidth(4*scale)
            c.move(to:CGPoint(x:23*scale,y:20*scale))
            c.addLine(to:CGPoint(x:235*scale,y:20*scale))
            c.strokePath()
            UIColor(red:1,green:0.78,blue:0.3,alpha:1).setFill()
            UIBezierPath(roundedRect:CGRect(x:224*scale,y:36*scale,width:18*scale,height:12*scale),cornerRadius:3*scale).fill()
            UIColor(red:0.72,green:0.12,blue:0.08,alpha:1).setFill()
            UIBezierPath(roundedRect:CGRect(x:17*scale,y:38*scale,width:14*scale,height:11*scale),cornerRadius:2*scale).fill()

            if style == 5 {
                c.setStrokeColor(UIColor(white:0.22,alpha:1).cgColor)
                c.setLineWidth(7*scale)
                c.move(to:CGPoint(x:178*scale,y:82*scale))
                c.addLine(to:CGPoint(x:198*scale,y:108*scale))
                c.addLine(to:CGPoint(x:224*scale,y:108*scale))
                c.strokePath()
                c.setStrokeColor(UIColor(white:0.72,alpha:1).cgColor)
                c.setLineWidth(3*scale)
                c.move(to:CGPoint(x:195*scale,y:96*scale))
                c.addLine(to:CGPoint(x:221*scale,y:96*scale))
                c.strokePath()
            }
            if style == 7 {
                UIColor(white:0.18,alpha:1).setFill()
                UIBezierPath(rect:CGRect(x:12*scale,y:70*scale,width:43*scale,height:19*scale)).fill()
                UIColor(white:0.55,alpha:1).setStroke()
                let cargoSeam=UIBezierPath(rect:CGRect(x:67*scale,y:31*scale,width:169*scale,height:48*scale))
                cargoSeam.lineWidth=2*scale
                cargoSeam.stroke()
                for x in stride(from:82,through:218,by:26) {
                    c.setStrokeColor(UIColor.black.withAlphaComponent(0.36).cgColor)
                    c.setLineWidth(2*scale)
                    c.move(to:CGPoint(x:CGFloat(x)*scale,y:34*scale))
                    c.addLine(to:CGPoint(x:CGFloat(x)*scale,y:75*scale))
                    c.strokePath()
                }
            }
            if style == 9 {
                UIColor(white:0.12,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:45*scale,y:71*scale,width:144*scale,height:14*scale),cornerRadius:3*scale).fill()
                c.setStrokeColor(UIColor(white:0.72,alpha:0.88).cgColor)
                c.setLineWidth(3*scale)
                c.move(to:CGPoint(x:30*scale,y:32*scale))
                c.addLine(to:CGPoint(x:226*scale,y:32*scale))
                c.strokePath()
            }
            let wheelCenters: [CGFloat] = style == 4 ? [40,112,190,235] : (style == 7 ? [42,112,174,218] : [62,194])
            for x in wheelCenters {
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
        let type = ((variant % 10) + 10) % 10
        let size = CGSize(width:64,height:92)
        let image = UIGraphicsImageRenderer(size:size).image { _ in
            let skins = [
                UIColor(red:0.55,green:0.68,blue:0.43,alpha:1),
                UIColor(red:0.64,green:0.57,blue:0.43,alpha:1),
                UIColor(red:0.39,green:0.55,blue:0.48,alpha:1),
                UIColor(red:0.73,green:0.69,blue:0.48,alpha:1),
                UIColor(red:0.47,green:0.59,blue:0.42,alpha:1),
                UIColor(red:0.67,green:0.39,blue:0.35,alpha:1),
                UIColor(red:0.43,green:0.51,blue:0.39,alpha:1),
                UIColor(red:0.76,green:0.72,blue:0.58,alpha:1),
                UIColor(red:0.35,green:0.48,blue:0.42,alpha:1),
                UIColor(red:0.70,green:0.73,blue:0.66,alpha:1)
            ]
            let shirts = [
                UIColor(red:0.35,green:0.18,blue:0.16,alpha:1),
                UIColor(red:0.19,green:0.25,blue:0.3,alpha:1),
                UIColor(red:0.25,green:0.29,blue:0.2,alpha:1),
                UIColor(red:0.65,green:0.54,blue:0.12,alpha:1),
                UIColor(red:0.16,green:0.22,blue:0.18,alpha:1),
                UIColor(red:0.42,green:0.12,blue:0.16,alpha:1),
                UIColor(red:0.27,green:0.30,blue:0.32,alpha:1),
                UIColor(red:0.75,green:0.64,blue:0.20,alpha:1),
                UIColor(red:0.18,green:0.24,blue:0.26,alpha:1),
                UIColor(red:0.30,green:0.31,blue:0.29,alpha:1)
            ]
            let skin = skins[type]
            let shirt = shirts[type]
            let torsoRect = CGRect(x:[2,6,9].contains(type) ? 12 : 18,y:type == 9 ? 52 : 36,width:[2,6].contains(type) ? 40 : (type == 9 ? 42 : 30),height:type == 1 ? 34 : (type == 9 ? 22 : 38))
            let torso = UIBezierPath(roundedRect:torsoRect,cornerRadius:7)
            shirt.setFill(); torso.fill()
            UIColor.black.setStroke(); torso.lineWidth=3; torso.stroke()
            let head = UIBezierPath(ovalIn:CGRect(x:19,y:7,width:28,height:31))
            skin.setFill(); head.fill(); UIColor.black.setStroke(); head.lineWidth=3; head.stroke()
            if [3,7].contains(type) {
                UIColor(white:0.12,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:19,y:19,width:29,height:11),cornerRadius:4).fill()
                UIColor(red:0.84,green:0.76,blue:0.26,alpha:1).setStroke()
                let visor=UIBezierPath(roundedRect:CGRect(x:22,y:20,width:22,height:5),cornerRadius:2)
                visor.lineWidth=2; visor.stroke()
            } else if [4,8].contains(type) {
                UIColor(white:0.22,alpha:1).setFill()
                UIBezierPath(roundedRect:CGRect(x:16,y:5,width:34,height:13),cornerRadius:5).fill()
                UIColor(white:0.68,alpha:1).setStroke()
                let helmet=UIBezierPath(roundedRect:CGRect(x:16,y:5,width:34,height:13),cornerRadius:5)
                helmet.lineWidth=2; helmet.stroke()
                UIColor(red:0.8,green:0.15,blue:0.1,alpha:1).setFill()
                UIBezierPath(ovalIn:CGRect(x:26,y:20,width:5,height:4)).fill()
            } else {
                if type == 5 {
                    UIColor(red:0.72,green:0.12,blue:0.10,alpha:1).setFill()
                    UIBezierPath(roundedRect:CGRect(x:17,y:14,width:31,height:8),cornerRadius:3).fill()
                }
                for x in [27,39] {
                    UIColor(red:0.85,green:0.12,blue:0.08,alpha:1).setFill()
                    UIBezierPath(ovalIn:CGRect(x:x,y:19,width:5,height:4)).fill()
                }
            }
            let armStartLeft = CGPoint(x:torsoRect.minX,y:44)
            let armStartRight = CGPoint(x:torsoRect.maxX,y:44)
            let arm1=UIBezierPath(); arm1.move(to:armStartLeft); arm1.addLine(to:CGPoint(x:5,y:65))
            let arm2=UIBezierPath(); arm2.move(to:armStartRight); arm2.addLine(to:CGPoint(x:59,y:61))
            UIColor.black.setStroke(); arm1.lineWidth=10; arm2.lineWidth=10; arm1.stroke(); arm2.stroke()
            skin.setStroke(); arm1.lineWidth=6; arm2.lineWidth=6; arm1.stroke(); arm2.stroke()
            for x in [24,39] {
                let leg=UIBezierPath(); leg.move(to:CGPoint(x:x,y:70)); leg.addLine(to:CGPoint(x:x-4,y:89))
                UIColor.black.setStroke(); leg.lineWidth=10; leg.stroke()
                UIColor(white:0.16,alpha:1).setStroke(); leg.lineWidth=6; leg.stroke()
            }
            if [2,4,6,8].contains(type) {
                UIColor(white:0.55,alpha:1).setStroke()
                let armor=UIBezierPath(roundedRect:CGRect(x:19,y:43,width:27,height:18),cornerRadius:3)
                armor.lineWidth=3; armor.stroke()
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
