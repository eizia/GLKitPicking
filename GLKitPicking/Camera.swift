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


func Vector3DDirectionToAngle(direction:GLKVector3 ) -> GLKVector3 {
    // Convert direction vector to angle
    var rotation = Float(acos(direction.y > 0 ? -direction.x : direction.x))
    
    if direction.y > 0{
        rotation  = Float(M_PI);
    }
    else{
        rotation  = Float(M_PI_2);
    }
    return GLKVector3Make(0, rotation, 0);
}


// Transforms a GLKVector3 by the given matrix
func Vector3Transform(vector:GLKVector3 , transform:GLKMatrix4 ) -> GLKVector3{
    return GLKVector3Make(
        ((vector.x * transform.m00) + (vector.y * transform.m10) + (vector.z * transform.m20) + transform.m30),
        ((vector.x * transform.m01) + (vector.y * transform.m11) + (vector.z * transform.m21) + transform.m31),
        ((vector.x * transform.m02) + (vector.y * transform.m12) + (vector.z * transform.m22) + transform.m32)
    )
}


// Creates a new rotation matrix from a specified yaw, pitch and roll angles
//func Matrix4MakeFromYawPitchRoll(yaw:Float , pitch:Float , roll:Float ) -> GLKMatrix4{
//    let quaternion = QuaternionMakeFromYawPitchRoll(yaw, pitch: pitch, roll: roll);
//
//    return GLKMatrix4MakeWithQuaternion(quaternion);
//}

// Creates a new quaternion from specified yaw, pitch and roll angles
//func QuaternionMakeFromYawPitchRoll(yaw:Float , pitch:Float , roll:Float) -> GLKQuaternion{
//    var quaternion = GLKQuaternion()
//
//    quaternion.x = cos(yaw * 0.5) * sin(pitch * 0.5) * cos(roll * 0.5) + sin(yaw * 0.5) * cos(pitch * 0.5) * sin(roll * 0.5)
//    quaternion.y = cos(yaw * 0.5) * sin(pitch * 0.5) * cos(roll * 0.5) - cos(yaw * 0.5) * sin(pitch * 0.5) * sin(roll * 0.5)
//    quaternion.z = cos(yaw * 0.5) * cos(pitch * 0.5) * sin(roll * 0.5) - sin(yaw * 0.5) * sin(pitch * 0.5) * cos(roll * 0.5)
//    quaternion.w = cos(yaw * 0.5) * cos(pitch * 0.5) * cos(roll * 0.5) + sin(yaw * 0.5) * sin(pitch * 0.5) * sin(roll * 0.5)
//
//    return quaternion;
//}

func projectOntoSurface(width:Float, _ height:Float, _ position:GLKVector3) -> GLKVector3{
    let radius = width/3;
    let center = GLKVector3Make(width/2, height/2, 0)
    let P = GLKVector3Subtract(position, center)
    // Flip the y-axis because pixel coords increase toward the bottom.
    var x = P.x
    var y = P.y * -1
    var z:GLfloat = 0
    
    
    let radius2 = radius * radius
    let length2 = x*x + y*y
    
    if length2 <= radius2 {
        z = sqrt(radius2 - length2);
    }
    else{
        x *= radius / sqrt(length2);
        y *= radius / sqrt(length2);
        z = 0;
    }
    
    return GLKVector3Normalize(GLKVector3Make(x,y,z));
}

func getSphereCameraPositionByPoint(width:GLfloat, height:GLfloat, x:GLfloat, y:GLfloat) -> GLKVector3{
    return projectOntoSurface(width, height, GLKVector3Make(x, y, 0))
}

func computeQuaternion(start:GLKVector3, _ end:GLKVector3) -> GLKQuaternion{
    
    let axis  = GLKVector3CrossProduct(start, end);
    let dot = GLKVector3DotProduct(start, end);
    let angle = acosf(dot);
    
    let quaternion = GLKQuaternionMakeWithAngleAndVector3Axis(angle * 2, axis);
    return GLKQuaternionNormalize(quaternion);
}


class SphereCamera : AbstractCamera {
    
    var position : GLKVector3!
    var target : GLKVector3!
    var beta : Float = 0
    var garma : Float = 0
    var radius : Float = 10
    let PI = Float(M_PI)
    let up = GLKVector3Make(0.0, 1.0, 0.0)
    
    init (width: CGFloat, height: CGFloat, fieldOfView: GLfloat, near: GLfloat, far: GLfloat, target:GLKVector3){
        super.init(width: width, height: height, fieldOfView: fieldOfView, near: near, far: far)
        self.target = target
        update(beta: self.beta, garma: self.garma, target: self.target)
    }
    
    
    func update(beta beta:Float, garma:Float, target:GLKVector3){
        
        let x:Float = radius * Float(sin(beta - PI/2)) * Float(sin(PI - garma)) + target.x
        let y:Float = radius * Float(cos(beta - PI/2)) + target.y
        let z:Float = radius * Float(sin(beta - PI/2)) * Float(cos(PI - garma)) + target.z
        
        position = GLKVector3Make(x,y,z)
        
        view = GLKMatrix4MakeLookAt(position.x, position.y, position.z, self.target.x, self.target.y, self.target.z, self.up.x, self.up.y, self.up.z)
        
    }
}

class AbstractCamera : NSObject {
    
    var projection:GLKMatrix4!
    var view:GLKMatrix4!
    
    init (width:CGFloat, height:CGFloat, fieldOfView:GLfloat, near:GLfloat, far:GLfloat){
        super.init()
        self.projection = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(fieldOfView), GLfloat(width/height), near, far)
    }
}

// -------------- camera ------------------>>>