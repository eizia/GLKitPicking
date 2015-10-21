//
//  ViewController.swift
//  OpenGLPicking
//
//  Created by Kares Qin on 10/21/15.
//  Copyright © 2015 Kares Qin. All rights reserved.
//

import UIKit
import QuartzCore
import OpenGLES
import GLKit

class GLController: GLKViewController {
    
    
    @IBOutlet var cubeView: CubeView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredFramesPerSecond = 60
        self.cubeView.controller = self
        self.cubeView.resize()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.paused = !self.paused
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

