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
    var Position: (x:CFloat, y:CFloat, z:CFloat)
    var Color: (CFloat, CFloat, CFloat, CFloat)
    var Normal: (CFloat, CFloat, CFloat)
}

var Vertices = [
    Vertex(Position: (1, -1, 1) , Color: (1, 0, 0, 1), Normal:(0,0,1) ),
    Vertex(Position: (1, 1, 1)  , Color: (0, 1, 0, 1), Normal:(0,0,1) ),
    Vertex(Position: (-1, 1, 1) , Color: (0, 0, 1, 1), Normal:(0,0,1) ),
    Vertex(Position: (-1, -1, 1), Color: (0, 0, 0, 1), Normal:(0,0,1) ),
    
    Vertex(Position: (1, 1, -1) , Color: (1, 0, 0, 1), Normal:(0,0,-1) ),
    Vertex(Position: (-1, -1, -1)  , Color: (0, 1, 0, 1), Normal:(0,0,-1) ),
    Vertex(Position: (1, -1, -1) , Color: (0, 0, 1, 1), Normal:(0,0,-1) ),
    Vertex(Position: (-1, 1, -1), Color: (0, 0, 0, 1), Normal:(0,0,-1) ),
    
    Vertex(Position: (-1, -1, 1) , Color: (1, 0, 0, 1), Normal:(-1,0,1) ),
    Vertex(Position: (-1, 1, 1)  , Color: (0, 1, 0, 1), Normal:(-1,0,1) ),
    Vertex(Position: (-1, 1, -1) , Color: (0, 0, 1, 1), Normal:(-1,0,1) ),
    Vertex(Position: (-1, -1, -1), Color: (0, 0, 0, 1), Normal:(0-1,0,1) ),
    
    Vertex(Position: (1, -1, -1) , Color: (1, 0, 0, 1), Normal:(1,0,1) ),
    Vertex(Position: (1, 1, -1)  , Color: (0, 1, 0, 1), Normal:(1,0,1) ),
    Vertex(Position: (1, 1, 1) , Color: (0, 0, 1, 1), Normal:(1,0,1) ),
    Vertex(Position: (1, -1, 1), Color: (0, 0, 0, 1), Normal:(1,0,1) ),
    
    Vertex(Position: (1, 1, 1) , Color: (1, 0, 0, 1), Normal:(0,1,0) ),
    Vertex(Position: (1, 1, -1)  , Color: (0, 1, 0, 1), Normal:(0,1,0) ),
    Vertex(Position: (-1, 1, -1) , Color: (0, 0, 1, 1), Normal:(0,1,0) ),
    Vertex(Position: (-1, 1, 1), Color: (0, 0, 0, 1), Normal:(0,1,0) ),
    
    Vertex(Position: (1, -1, -1) , Color: (1, 0, 0, 1), Normal:(0,-1,0) ),
    Vertex(Position: (1, -1, 1)  , Color: (0, 1, 0, 1), Normal:(0,-1,0) ),
    Vertex(Position: (-1, -1, 1) , Color: (0, 0, 1, 1), Normal:(0,-1,0) ),
    Vertex(Position: (-1, -1, -1), Color: (0, 0, 0, 1), Normal:(0,-1,0) )
]
var Indices: [GLubyte] = [
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right 
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom 
    20, 21, 22,
    22, 23, 20
]


//helper extensions to pass arguments to GL land
extension Array {
    func size () -> Int {
        return self.count * sizeofValue(self[0])
    }
}

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

class CubeView: GLKView {
    
    var _anchor_position:CGPoint!
    var _current_position:CGPoint!
    var _beta:Float!
    var _garma:Float!
    var indexBuffer: GLuint = GLuint()
    var vertexBuffer: GLuint = GLuint()
    var vertexArray: GLuint = GLuint()
    var cubeEffect = GLKBaseEffect()
    var controller:GLKViewController?
    var camera:SphereCamera!
    var PI = Float(M_PI)
    
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
        
        
        self.cubeEffect.light0.enabled = GLboolean(GL_TRUE);
        self.cubeEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1.0);
        self.cubeEffect.light0.position = GLKVector4Make(1, 1, 0, 1);
        self.cubeEffect.light0.diffuseColor = GLKVector4Make(0, 1, 1, 1);
        self.cubeEffect.light0.ambientColor = GLKVector4Make(0, 0, 0, 1);
        self.cubeEffect.light0.specularColor = GLKVector4Make(0, 0, 0, 1);
        

        

        glGenVertexArraysOES(1, &vertexArray);
        glBindVertexArrayOES(vertexArray);
        
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), Vertices.size(), Vertices, GLenum(GL_DYNAMIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)), UnsafePointer<Int>(bitPattern: 0))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Color.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Color.rawValue), 4, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)),  UnsafePointer<Int>(bitPattern: sizeof(CFloat) * 3))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.Normal.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.Normal.rawValue), 3, GLenum(GL_FLOAT), GLboolean(UInt8(GL_FALSE)), GLsizei(sizeof(Vertex)),  UnsafePointer<Int>(bitPattern: sizeof(CFloat) * 7))
        
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), Indices.size(), Indices, GLenum(GL_DYNAMIC_DRAW))
        

        glBindVertexArrayOES(0);
        
    }
        
    func resize(){
            
        if self.controller != nil {
            self.camera = SphereCamera(width: self.frame.width, height: self.frame.height, fieldOfView: 60, near: 2, far: 30, target: GLKVector3Make(0, 0, 0))
            self.cubeEffect.transform.projectionMatrix = self.camera.projection
        }
    }
    
    func intersectsTriangle(position:GLKVector3, ray:GLKVector3, a: GLKVector3, b: GLKVector3, c: GLKVector3) -> (intersect:Bool, result:GLKVector3?){
        //follow http://sarvanz.blogspot.com/2012/03/probing-using-ray-casting-in-opengl.html
        let u = GLKVector3Subtract(b, a)
        let v = GLKVector3Subtract(c, a)
        let normal = GLKVector3CrossProduct(u, v)
        let nDotL = GLKVector3DotProduct(normal, ray)
        //是否跟三角面在同一平面
        if (nDotL > -0.00001 && nDotL < 0.00001) {
            return (intersect:false, result:nil)
        }
        
        let d = GLKVector3DotProduct(normal, GLKVector3Subtract(a, position)) / nDotL
        //是否背对三角面
        if (d < 0 || d > 1) {
            return (intersect:false, result:nil)
        }
        
        let p = GLKVector3Add(position, GLKVector3MultiplyScalar(ray, d))
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
        let hLength = vLength * width / height
        
        vVector3 = GLKVector3MultiplyScalar(vVector3, vLength)
        hVector3 = GLKVector3MultiplyScalar(hVector3, hLength)
        
        // translate mouse coordinates so that the origin lies in the center
        // of the view port
        var xPoint = x - width / 2
        var yPoint = y - height / 2
        xPoint = xPoint/height * 2
        yPoint = yPoint/height * 2
        
        
        // compute direction of picking ray by subtracting intersection point
        
        var direction = GLKVector3Add(GLKVector3MultiplyScalar(viewVector3, self.camera.near), GLKVector3MultiplyScalar(hVector3, xPoint))
        direction = GLKVector3Add(direction, GLKVector3MultiplyScalar(vVector3, yPoint))
        
        // linear combination to compute intersection of picking ray with
        // view port plane
        let position = GLKVector3Add(self.camera.position, direction)
        
        print("direction : " + String(direction.x) + " " + String(direction.y) + " " + String(direction.z))
        print("position : " + String(position.x) + " " + String(position.y) + " " + String(position.z))
        
        for var index = 1; index <= Indices.count; index++ {
            if index != 1 && index % 3 == 0{
                let aa = Vertices[Int(Indices[index-3])].Position
                let bb = Vertices[Int(Indices[index-2])].Position
                let cc = Vertices[Int(Indices[index-1])].Position
                let a = GLKVector3Make(aa.x, aa.y, aa.z)
                let b = GLKVector3Make(bb.x, bb.y, bb.z)
                let c = GLKVector3Make(cc.x, cc.y, cc.z)
//                let data = intersectsTriangle(GLKVector3Make(0, 0, 8), ray:GLKVector3Make(0, 0, -20),  a: a, b: b, c: c)
                let data = intersectsTriangle(position, ray:GLKVector3MultiplyScalar(direction, 100),  a: a, b: b, c: c)
                if data.intersect {
                    print(String( data.result!.x) + " " + String( data.result!.y) + " " + String( data.result!.z) + " ")
                }
            }
        }
        
        
    }
    
    override func touchesBegan(touchSet: Set<UITouch>, withEvent event: UIEvent!) {
        //        self.paused = !self.paused
        
        let touches = Array(touchSet)
        if touches.count >= 1{
            let touch:UITouch = touches.first!
            _anchor_position = touch.locationInView(self)
            _current_position = _anchor_position
            _beta = self.camera.beta
            _garma = self.camera.garma
            pick(x: Float(_anchor_position.x), y: Float(_anchor_position.y))
        }
        
    }
    
    override func touchesMoved(touchSet: Set<UITouch>, withEvent event: UIEvent!) {
        //        self.paused = !self.paused
        
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
    
    
    
    override func drawRect(rect:CGRect){
        if self.controller != nil {
            
            self.cubeEffect.prepareToDraw()
            
//            var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, 0.0)
//            modelViewMatrix = GLKMatrix4Multiply(modelViewMatrix, self.camera.view)
            self.cubeEffect.transform.modelviewMatrix = self.camera.view
            
            
            glClearColor(1, 1, 1, 1.0);
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
            glBindVertexArrayOES(vertexArray);
        
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count), GLenum(GL_UNSIGNED_BYTE), UnsafePointer<Int>(bitPattern: 0))
            
        }
    }
    
    
}
