//
//  OpenGLView.swift
//  iOSSwiftOpenGL
//
//  Created by Bradley Griffith on 6/29/14.
//  Copyright (c) 2014 Bradley Griffith. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

struct Vertex {
    var Position: (x:Float, y:Float, z:Float)
    var Color:  (r:Float, g:Float, b:Float, a:Float)
    var Normal:  (x:Float, y:Float, z:Float)
}
func F3(x:Float, _ y:Float, _ z:Float) -> (x:Float, y:Float, z:Float){
    return (x:x, y:y, z:z)
}

//helper extensions to pass arguments to GL land
extension Int32 {
    func __conversion() -> GLenum {
        return GLuint(self)
    }
    
    func __conversion() -> GLboolean {
        return GLboolean(UInt8(self))
    }
}

extension Int {
    func __conversion() -> Int32 {
        return Int32(self)
    }
    
    func __conversion() -> GLubyte {
        return GLubyte(self)
    }
    
}

struct Utils {
    
    static var timeRecorder = NSMutableDictionary()
    static var analysisRecorder = NSMutableDictionary()
    static var delayRecorder:[Bool] = []
    
    static func setDelay(time:Double = 1, closure:()->()) -> Int {
        let index:Int = delayRecorder.count
        delayRecorder.append(true)
        
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(time * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), {
                if self.delayRecorder[index]{
                    closure()
                }
        })
        
        return index
    }
    
    static func cancelDelay(index:Int = -1){
        if -1 < index && index < delayRecorder.count && delayRecorder[index]{
            delayRecorder[index] = false
        }
    }
}


class CubeView: GLKView {
    
    var _anchor_position:CGPoint!
    var _current_position:CGPoint!
    var _beta:Float!
    var _garma:Float!
    var indexBuffer: GLuint = GLuint()
    var indexBufferSize:Int = 36 * 4 * 1024 * 8
    var vertexBuffer: GLuint = GLuint()
    var vertexBufferSize:Int = 24 * 40 * 1024 * 8
    var vertexArray: GLuint = GLuint()
    var cubeEffect = GLKBaseEffect()
    var controller:GLKViewController?
    var camera:SphereCamera!
    var PI = Float(M_PI)
    let NORMAL:[String:(x:Float, y:Float, z:Float)] = [
        "Y" : F3(0,1,0),
        "-Y" : F3(0,-1,0),
        "X" : F3(1,0,0),
        "-X" : F3(-1,0,0),
        "Z" : F3(0,0,1),
        "-Z" : F3(0,0,-1)
    ]
    var vertices:[Vertex]  = []
    var indices:[GLuint] = []
    var appendIndex:Int = 0
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        
        // Just like with CoreGraphics, in order to do much with OpenGL, we need a context.
        //   Here we create a new context with the version of the rendering API we want and
        //   tells OpenGL that when we draw, we want to do so within this context.
        self.context = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        
        self.drawableColorFormat = GLKViewDrawableColorFormat.RGBA8888
        self.drawableDepthFormat = GLKViewDrawableDepthFormat.Format16
        self.drawableStencilFormat = GLKViewDrawableStencilFormat.Format8
        self.drawableMultisample = GLKViewDrawableMultisample.Multisample4X
        
        if (self.context.isEqual(nil)) {
            print("Failed to initialize OpenGLES 2.0 context!")
            exit(1)
        }
        
        if (!EAGLContext.setCurrentContext(self.context)) {
            print("Failed to set current OpenGL context!")
            exit(1)
        }
        
        EAGLContext.setCurrentContext(self.context)
        glEnable(GLenum(GL_CULL_FACE))
        glEnable(GLenum(GL_DEPTH_TEST));
        
        self.cubeEffect.colorMaterialEnabled = GLboolean(GL_TRUE)
        self.cubeEffect.light0.enabled = GLboolean(GL_TRUE)
        self.cubeEffect.light0.position = GLKVector4Make(0, 10, 0, 1)
        //        self.cubeEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1.0);
        //        self.cubeEffect.light0.ambientColor = GLKVector4Make(1, 1, 1, 1);
        //        self.cubeEffect.light0.specularColor = GLKVector4Make(0, 0, 0, 1);
        
//        vertices.appendContentsOf(genOneCubeVertices(GLKVector3Make(0, 0, 0), color: (1,0.5,0,1)))
//        indices.appendContentsOf(genOneCubeIndices(0))
//
        
        
//        
//        for var index = 0; index < 1000; ++index {
//            let ves = genOneCubeVertices(GLKVector3Make(Float(appendIndex % 10), Float(appendIndex%100 / 10), Float(appendIndex/100)), color: (Float(appendIndex % 10) / Float(10), Float(appendIndex % 100) / Float(100), Float(appendIndex)/1000, 1))
//            let ins = genOneCubeIndices(appendIndex)
//            vertices.appendContentsOf(ves)
//            indices.appendContentsOf(ins)
//            appendIndex++
//        }
        
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertexBufferSize, vertices, GLenum(GL_DYNAMIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)), UnsafePointer<Int>(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Color.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Color.rawValue), 4, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)),  UnsafePointer<Int>(bitPattern: sizeof(Float) * 3))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)),  UnsafePointer<Int>(bitPattern: sizeof(Float) * 7))
        
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBufferSize, &indices, GLenum(GL_DYNAMIC_DRAW))
        

        glBindVertexArrayOES(0)
        
        
    }
    
    func pushVertexBuffer(cubeIndex:Int, number:Int){
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), GLintptr(cubeIndex * 24 * sizeof(Vertex)), GLsizeiptr(number * 24 * sizeof(Vertex)), &vertices + cubeIndex * 24 * sizeof(Vertex))
    }
    func pushIndexBuffer(cubeIndex:Int, number:Int){
        glBufferSubData(GLenum(GL_ELEMENT_ARRAY_BUFFER), cubeIndex * 36 * sizeof(GLuint), number * 36 * sizeof(GLuint), &indices + cubeIndex * 36 * sizeof(GLuint))
    }
        
    func resize(){
            
        if self.controller != nil {
            self.camera = SphereCamera(width: self.frame.width, height: self.frame.height)
            self.cubeEffect.transform.projectionMatrix = self.camera.projection
            
            Utils.setDelay(2, closure: testCreating)
        }
    }
    
    
    func genOneCubeVertices(position:GLKVector3, color:(r:Float, g:Float, b:Float, a:Float)) -> [Vertex]{
        
        let x = position.x
        let y = position.y
        let z = position.z
        return [
            Vertex(Position: F3(x+0.5, y-0.5, z+0.5) ,   Color: color, Normal:NORMAL["Z"]! ), //0
            Vertex(Position: F3(x+0.5, y+0.5, z+0.5)  ,  Color: color, Normal:NORMAL["Z"]! ), //1
            Vertex(Position: F3(x-0.5, y+0.5, z+0.5) ,   Color: color, Normal:NORMAL["Z"]! ), //2
            Vertex(Position: F3(x-0.5, y-0.5, z+0.5),    Color: color, Normal:NORMAL["Z"]! ), //3
            
            Vertex(Position: F3(x+0.5, y+0.5, z-0.5) ,   Color: color, Normal:NORMAL["-Z"]! ), //4
            Vertex(Position: F3(x-0.5, y-0.5, z-0.5),    Color: color, Normal:NORMAL["-Z"]! ), //5
            Vertex(Position: F3(x+0.5, y-0.5, z-0.5) ,   Color: color, Normal:NORMAL["-Z"]! ), //6
            Vertex(Position: F3(x-0.5, y+0.5, z-0.5),    Color: color, Normal:NORMAL["-Z"]! ), //7
            
            Vertex(Position: F3(x-0.5, y-0.5, z+0.5),    Color: color, Normal:NORMAL["-X"]! ), //8
            Vertex(Position: F3(x-0.5, y+0.5, z+0.5)  ,  Color: color, Normal:NORMAL["-X"]! ), //9
            Vertex(Position: F3(x-0.5, y+0.5, z-0.5) ,   Color: color, Normal:NORMAL["-X"]! ), //10
            Vertex(Position: F3(x-0.5, y-0.5, z-0.5),    Color: color, Normal:NORMAL["-X"]! ), //11
            
            Vertex(Position: F3(x+0.5, y-0.5, z-0.5) ,   Color: color, Normal:NORMAL["X"]! ), // 12
            Vertex(Position: F3(x+0.5, y+0.5, z-0.5)  ,  Color: color, Normal:NORMAL["X"]! ), //13
            Vertex(Position: F3(x+0.5, y+0.5, z+0.5),    Color: color, Normal:NORMAL["X"]! ), //14
            Vertex(Position: F3(x+0.5, y-0.5, z+0.5),    Color: color, Normal:NORMAL["X"]! ), //15
            
            Vertex(Position: F3(x+0.5, y+0.5, z+0.5),    Color: color, Normal:NORMAL["Y"]!), //16
            Vertex(Position: F3(x+0.5, y+0.5, z-0.5) ,   Color: color, Normal:NORMAL["Y"]! ), //17
            Vertex(Position: F3(x-0.5, y+0.5, z-0.5),    Color: color, Normal:NORMAL["Y"]! ), // 18
            Vertex(Position: F3(x-0.5, y+0.5, z+0.5),    Color: color, Normal:NORMAL["Y"]! ), //19
            
            Vertex(Position: F3(x+0.5, y-0.5, z-0.5) ,   Color: color, Normal:NORMAL["-Y"]! ), //20
            Vertex(Position: F3(x+0.5, y-0.5, z+0.5) ,   Color: color, Normal:NORMAL["-Y"]! ), //21
            Vertex(Position: F3(x-0.5, y-0.5, z+0.5),    Color: color, Normal:NORMAL["-Y"]! ), //22
            Vertex(Position: F3(x-0.5, y-0.5, z-0.5),    Color: color, Normal:NORMAL["-Y"]! ) //23
        ]
    }
    
    func genOneCubeIndices(index:Int) -> [GLuint]{
        let vertexCount = GLuint(index * 24)
        return [
            vertexCount, vertexCount+1, vertexCount+2,
            vertexCount+2, vertexCount+3, vertexCount,
            
            vertexCount+4, vertexCount+6, vertexCount+5,
            vertexCount+4, vertexCount+5, vertexCount+7,
            
            vertexCount+8, vertexCount+9, vertexCount+10,
            vertexCount+10, vertexCount+11, vertexCount+8,
            
            vertexCount+12, vertexCount+13, vertexCount+14,
            vertexCount+14, vertexCount+15, vertexCount+12,
            
            vertexCount+16, vertexCount+17, vertexCount+18,
            vertexCount+18, vertexCount+19, vertexCount+16,
            
            vertexCount+20, vertexCount+21, vertexCount+22,
            vertexCount+22, vertexCount+23, vertexCount+20
        ]
    }
    
    func intersectsTriangle(near:GLKVector3, far:GLKVector3, a: GLKVector3, b: GLKVector3, c: GLKVector3, normal:GLKVector3) -> (intersect:Bool, result:GLKVector3?){
        //follow http://sarvanz.blogspot.com/2012/03/probing-using-ray-casting-in-opengl.html
        
        let ray = GLKVector3Subtract(far, near)
        let nDotL = GLKVector3DotProduct(normal, ray)
        //是否跟三角面在同一平面或者背对三角面
        if nDotL >= 0 {
            return (intersect:false, result:nil)
        }
        
        let d = GLKVector3DotProduct(normal, GLKVector3Subtract(a, near)) / nDotL
        //是否在最近点和最远点之外
        if (d < 0 || d > 1) {
            return (intersect:false, result:nil)
        }
        
        let p = GLKVector3Add(near, GLKVector3MultiplyScalar(ray, d))
        let n1 = GLKVector3CrossProduct( GLKVector3Subtract(b, a),  GLKVector3Subtract(p, a))
        let n2 = GLKVector3CrossProduct( GLKVector3Subtract(c, b),  GLKVector3Subtract(p, b))
        let n3 = GLKVector3CrossProduct( GLKVector3Subtract(a, c),  GLKVector3Subtract(p, c))
        
        if GLKVector3DotProduct(normal, n1) >= 0 &&
            GLKVector3DotProduct(normal, n2) >= 0 &&
            GLKVector3DotProduct(normal, n3) >= 0{
                return (intersect:true, result:p)
        }else{
            return (intersect:false, result:nil)
        }
    }
    
    func testCreating(){
        
        var delay:Int = -1
        
        
        func delayFn(){
            
            let ves = genOneCubeVertices(GLKVector3Make(Float(appendIndex % 10), Float(appendIndex%100 / 10), Float(appendIndex/100)), color: (Float(appendIndex % 10) / Float(10), Float(appendIndex % 100) / Float(100), Float(appendIndex)/1000, 1))
            let ins = genOneCubeIndices(appendIndex)
            vertices.appendContentsOf(ves)
            indices.appendContentsOf(ins)
            pushVertexBuffer(appendIndex, number: 1)
            pushIndexBuffer(appendIndex, number: 1)
            appendIndex++
            
            if delay < 1000{
                delay = Utils.setDelay(0.005, closure: delayFn)
            }
            
        }
        delayFn()

    }
    
    func pick(x x:Float, y:Float){
        
        //follow http://schabby.de/picking-opengl-ray-tracing/
        let viewVector3 = GLKVector3Normalize(GLKVector3Subtract(self.camera.target, self.camera.position))
        var hVector3 = GLKVector3Normalize(GLKVector3CrossProduct(viewVector3, self.camera.up))
        var vVector3 = GLKVector3Normalize(GLKVector3CrossProduct(hVector3, viewVector3))
        
        let width = Float(self.camera.width)
        let height = Float(self.camera.height)
        
        // convert fovy to radians
        let rad = self.camera.fov * PI / 180
        let vLength = tan( rad / 2 ) * self.camera.near
        let hLength = vLength * (width / height)
        
        vVector3 = GLKVector3MultiplyScalar(vVector3, vLength)
        hVector3 = GLKVector3MultiplyScalar(hVector3, hLength)
        
        // translate mouse coordinates so that the origin lies in the center
        // of the view port
        var xPoint = x - width / 2
        var yPoint = y - height / 2
        xPoint = xPoint/width * 2
        yPoint = -yPoint/height * 2
        
        
        
        
        // compute direction of picking ray by subtracting intersection point
        
        var direction = GLKVector3Add(GLKVector3MultiplyScalar(viewVector3, self.camera.near), GLKVector3MultiplyScalar(hVector3, xPoint))
        direction = GLKVector3Add(direction, GLKVector3MultiplyScalar(vVector3, yPoint))
        
        // linear combination to compute intersection of picking ray with
        // view port plane
        let near = GLKVector3Add(self.camera.position, direction)
        let far = GLKVector3Add(self.camera.position, GLKVector3MultiplyScalar(direction, self.camera.far / self.camera.near))
        
        //print("near : " + String(near.x) + " " + String(near.y) + " " + String(near.z))
        //print("far : " + String(far.x) + " " + String(far.y) + " " + String(far.z))
        
        for var index = 1; index <= indices.count; index++ {
            if index != 1 && index % 3 == 0{
                let aa = vertices[Int(indices[index-3])].Position
                let bb = vertices[Int(indices[index-2])].Position
                let cc = vertices[Int(indices[index-1])].Position
                let nn = vertices[Int(indices[index-1])].Normal
                let a = GLKVector3Make(aa.x, aa.y, aa.z)
                let b = GLKVector3Make(bb.x, bb.y, bb.z)
                let c = GLKVector3Make(cc.x, cc.y, cc.z)
                let n = GLKVector3Make(Float(nn.x), Float(nn.y), Float(nn.z))
                let data = intersectsTriangle(near, far:far,  a: a, b: b, c: c, normal:n)
                if data.intersect {
                    print(String( data.result!.x) + " " + String( data.result!.y) + " " + String( data.result!.z) + " ")
                }
            }
        }
        
        
    }
    
    override func touchesBegan(touchSet: Set<UITouch>, withEvent event: UIEvent!) {
        self.controller?.paused = false
        let touches = Array(touchSet)
        if touches.count >= 1{
            let touch:UITouch = touches.first!
            _anchor_position = touch.locationInView(self)
            _current_position = _anchor_position
            _beta = self.camera.beta
            _garma = self.camera.garma
            pick(x: Float(_anchor_position.x), y: Float(_anchor_position.y))
            
//            let previousIndex = appendIndex
//            for var index = 0; index < 10; ++index {
//                let ves = genOneCubeVertices(GLKVector3Make(Float(appendIndex % 10), Float(appendIndex%100 / 10), Float(appendIndex/100)), color: (Float(appendIndex % 10) / Float(10), Float(appendIndex % 100) / Float(100), Float(appendIndex)/1000, 1))
//                let ins = genOneCubeIndices(appendIndex)
//                vertices.appendContentsOf(ves)
//                indices.appendContentsOf(ins)
//                appendIndex++
//            }
//            
//            pushVertexBuffer(previousIndex, number: 10)
//            pushIndexBuffer(previousIndex, number: 10)
        }
        
    }
    
    override func touchesMoved(touchSet: Set<UITouch>, withEvent event: UIEvent!) {
        self.controller?.paused = false
        let touches = Array(touchSet)
        if touches.count >= 1{
            let touch:UITouch = touches.first!
            _current_position = touch.locationInView(self)
            let diff = CGPointMake(_current_position.x - _anchor_position.x, _current_position.y - _anchor_position.y)
            let beta = GLKMathDegreesToRadians(Float(diff.y) / 2.0);
            let garma = GLKMathDegreesToRadians(Float(diff.x) / 2.0);
            
            self.camera.update(beta: _beta + beta, garma: _garma + garma)
            
            
        }
        
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
//        self.controller?.paused = true
    }
    
    
    
    override func drawRect(rect:CGRect){
        if self.controller != nil {
            
            self.cubeEffect.prepareToDraw()
            self.cubeEffect.transform.modelviewMatrix = self.camera.view
            
            glClearColor(1, 1, 1, 1.0);
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
            glBindVertexArrayOES(vertexArray);
        
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(indices.count), GLenum(GL_UNSIGNED_INT), UnsafePointer<Int>(bitPattern: 0))
            
        }
    }
    
    
}
