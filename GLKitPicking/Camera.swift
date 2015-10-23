//
//  Camera.swift
//  GLKitPicking
//
//  Created by Kares Qin on 10/22/15.
//  Copyright © 2015 Kares Qin. All rights reserved.
//

import Foundation
import QuartzCore
import OpenGLES
import GLKit


// <<<-------------- camera ------------------


class SphereCamera : AbstractCamera {
    
    let PI = Float(M_PI)
    var position : GLKVector3!
    var beta : Float
    var garma : Float
    var radius : Float
    var target :GLKVector3
    let up = GLKVector3Make(0.0, 1.0, 0.0)
    
    init (width: CGFloat, height: CGFloat, fieldOfView: GLfloat = 60, near: GLfloat = 2, far: GLfloat = 50, beta:Float = 0, garma:Float = 0, radius:Float = 30, target:GLKVector3 = GLKVector3Make(0,0,0)){
        self.target = target
        self.radius = radius
        self.beta = beta
        self.garma = garma
        super.init(width: width, height: height, fieldOfView: fieldOfView, near: near, far: far)
        update(beta: self.beta, garma: self.garma, radius: self.radius, target: self.target)
    }
    
    func update(beta beta:Float, garma:Float){
        update(beta: beta, garma: garma, radius: self.radius, target: self.target)
    }
    
    func update(beta beta:Float){
        update(beta: beta, garma: self.garma, radius: self.radius, target: self.target)
    }
    
    func update(garma garma:Float){
        update(beta: beta, garma: garma, radius: self.radius, target: self.target)
    }
    
    func update(radius radius:Float){
        update(beta: beta, garma: garma, radius: radius, target: self.target)
    }
    
    func update(target target:GLKVector3){
        update(beta: beta, garma: garma, radius: radius, target: target)
    }
    
    func update(beta beta:Float, garma:Float, radius:Float, target:GLKVector3){
        
        let x:Float = radius * Float(sin(beta - PI/2)) * Float(sin(PI - garma)) + target.x
        let y:Float = radius * Float(cos(beta - PI/2)) + target.y
        let z:Float = radius * Float(sin(beta - PI/2)) * Float(cos(PI - garma)) + target.z
        
        self.radius = radius
        self.beta = beta
        self.garma = garma
        self.target = target
        
        position = GLKVector3Make(x,y,z)
        
//        print("beta:" + String(beta))
//        print("garma:" + String(garma))
//        print("camera position : " + String(position.x) + " " + String(position.y) + " " + String(position.z))
        
        
        view = GLKMatrix4MakeLookAt(position.x, position.y, position.z, self.target.x, self.target.y, self.target.z, self.up.x, self.up.y, self.up.z)
        
    }
}

class AbstractCamera : NSObject {
    
    var projection:GLKMatrix4
    var view:GLKMatrix4!
    var fov:GLfloat
    var width:CGFloat
    var height:CGFloat
    var near:GLfloat
    var far:GLfloat
    
    init (width:CGFloat, height:CGFloat, fieldOfView:GLfloat, near:GLfloat, far:GLfloat){
        self.fov = fieldOfView
        self.width = width
        self.height = height
        self.near = near
        self.far = far
        self.projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fieldOfView), GLfloat(width/height), near, far)
        super.init()
    }
}

// -------------- camera ------------------>>>