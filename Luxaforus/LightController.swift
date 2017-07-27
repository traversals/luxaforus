//
//  LightController.swift
//  Luxaforus
//
//  Created by Mike Gouline on 21/7/17.
//  Copyright © 2017 Traversal Space. All rights reserved.
//

import Cocoa

class LightController {
    
    private var brightness: CGFloat = 1.0
    private var currentColor: NSColor? = nil
    
    private var usbDetector = IOUSBDetector(vendorID: Int(kLuxaforVendorId), productID: Int(kLuxaforProductId))
    
    private weak var delegate: LightControllerDelegate? = nil
    
    init() {
        usbDetector?.callbackQueue = DispatchQueue.global()
        usbDetector?.callback = { (detector, event, service) in
            let connected = event == .matched
            
            self.delegate?.lightController(connectedChanged: connected)
            
            if connected {
                if let color = self.currentColor {
                    sleep(2) // Not great, but have to wait for reconnection flashes to finish.
                    self.update(color: color)
                }
            }
        }
    }
    
    deinit {
        usbDetector?.callback = nil
    }
    
    /// Attaches USB detector for device.
    func attach(delegate theDelegate: LightControllerDelegate) {
        // Check that a delegate was attached
        if delegate != nil { return }
        
        delegate = theDelegate
        
        if usbDetector?.startDetection() == false {
            NSLog("Light: failed to start USB detector")
        }
    }
    
    /// Detaches USB detector for device.
    func detach() {
        // Check that a delegate was attached
        if delegate == nil { return }
     
        usbDetector?.stopDetection()
        
        delegate = nil
    }
    
    /// Updates current color of the light.
    ///
    /// - Parameter theColor: Color value (ignores alpha - set brightness for that).
    func update(color theColor: NSColor) {
        NSLog("Light: color=%@", theColor)
        
        currentColor = theColor
        
        getDevice(onlyConnected: true)?.color = theColor.withAlphaComponent(brightness)
    }
    
    /// Updates transition speed for colors.
    ///
    /// - Parameter theSpeed: Transition speed as a 8-bit integer.
    func update(transitionSpeed theSpeed: Int8) {
        NSLog("Light: transitionSpeed=%d", theSpeed)
        
        getDevice(onlyConnected: true)?.transitionSpeed = theSpeed
    }
    
    /// Updates brightness of the light.
    ///
    /// - Parameter theBrightness: Brightness value within same threshold as alpha.
    func update(brightness theBrightness: CGFloat) {
        brightness = theBrightness
        
        if let replayColor = currentColor {
            update(color: replayColor)
        }
    }
    
    /// Updates dimmed status. Shortcut for updating brightness (see LightBrightness constants).
    ///
    /// - Parameter isDimmed: True for dimmed, false for normal.
    func update(dimmed isDimmed: Bool) {
        update(brightness: isDimmed ? LightBrightness.dimmed : LightBrightness.normal)
    }
    
    /// Retrieves active device from LXDevice.
    ///
    /// - Parameter enabled: True to only return device if connected, false otherwise.
    /// - Returns: Device instance or null.
    private func getDevice(onlyConnected enabled: Bool) -> LXDevice? {
        let device = LXDevice.sharedInstance()
        if device?.connected ?? false || !enabled {
            return device
        }
        return nil
    }
    
}

protocol LightControllerDelegate: class {
    
    /// Light controller connection state changed.
    ///
    /// - Parameter connected: True when connected, false when disconnected.
    func lightController(connectedChanged connected: Bool)
    
}

/// Color states for the light.
class LightColor {
    static let available = NSColor.green
    static let busy = NSColor.red
    static let locked = NSColor.black
}

/// Brightness states for the light.
class LightBrightness {
    static let normal: CGFloat = 1.0
    static let dimmed: CGFloat = 0.1
}
