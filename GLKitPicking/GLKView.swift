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
    var Position: (CFloat, CFloat, CFloat)
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
    
    var _increasing:Bool = false
    var _curRed:Float = 0.5
    var _rotation:Float = 0
    var indexBuffer: GLuint = GLuint()
    var vertexBuffer: GLuint = GLuint()
    var vertexArray: GLuint = GLuint()
    var cubeEffect = GLKBaseEffect()
    var controller:GLKViewController?
    
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
            self.cubeEffect.transform.projectionMatrix = GLKMatrix4MakePerspective(
                GLKMathDegreesToRadians(25),
                Float(self.controller!.view.bounds.size.width / self.controller!.view.bounds.size.height), 2, 30)
        }
    }
    
    
    
    override func drawRect(rect:CGRect){
        if self.controller != nil {
            
            self.cubeEffect.prepareToDraw()
            
            _rotation += 10 * Float(self.controller!.timeSinceLastDraw)
            
            var modelViewMatrix = GLKMatrix4MakeTranslation(0.0, 0.0, -15.0)
            modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(25), 1, 0, 0)
            modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 1, 0)
            
            self.cubeEffect.transform.modelviewMatrix = GLKMatrix4Rotate(
                    modelViewMatrix,
                    GLKMathDegreesToRadians(_rotation), 0, 0, 1);
            
            
            glClearColor(1, 1, 1, 1.0);
            glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        
            glBindVertexArrayOES(vertexArray);
        
            glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count), GLenum(GL_UNSIGNED_BYTE), UnsafePointer<Int>(bitPattern: 0))
            
        }
    }
    
    
}



