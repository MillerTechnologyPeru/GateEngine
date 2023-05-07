/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GameMath

extension PlatformSystem {
    enum Phase: UInt {
        case preUpdating
        case postDeffered
        case postRendering
    }
}

/// PlaformSystems are private and reserved for internal use by the engine.
@MainActor internal class PlatformSystem {
    required init() {}
    
    private(set) lazy var backgroundTask = BackgroundTask(system: self)
    public class BackgroundTask {
        unowned let system: PlatformSystem
        init(system: PlatformSystem) {
            self.system = system
        }
        public enum State {
            ///Not running and never finished
            case initial
            case running
            case finished
        }
        public private(set) var state: State = .initial
        @inline(__always)
        nonisolated public var isRunning: Bool {
            return state == .running
        }
        
        @MainActor public func run(_ block: @escaping ()->Void) {
            assert(self.isRunning == false, "A Task cannot be run when it's running.")
            self.state = .running
            Task(priority: .background) {
                block()
                Task { @MainActor in
                    //Update the state between simulation ticks
                    self.state = .finished
                }
            }
        }
    }
        
    internal final func willUpdate(game: Game, input: HID, layout: WindowLayout, withTimePassed deltaTime: Float) {
        if didSetup == false {
            didSetup = true
            setup(game: game)
        }
        if shouldUpdate(withTimePassed: deltaTime) {
            update(game: game, input: input, layout: layout, withTimePassed: deltaTime)
        }
    }

    private var didSetup = false
    
    /**
     Called once when the system is first inserted into the game.
     
     Use `setup()` to create any system specific data and add it to the game.
     - note: The call to `setup()` is deffered until the next update frame after the system has been inserted and will be called immediatled before `update(withTimePassed:)`.
     */
    open func setup(game: Game) {
        
    }
    
    /**
     Called before `update(withTimePassed:)`. Return `true` if you would like `update(withTimePassed:)` to be called, otherwise return `false`.
     - parameter deltaTime: The duration of time since the last update frame.
     */
    open func shouldUpdate(withTimePassed deltaTime: Float) -> Bool {
        return true
    }
    
    /**
     Called every update frame.
     - parameter deltaTime: The duration of time since the last update frame.
     */
    open func update(game: Game, input: HID, layout: WindowLayout, withTimePassed deltaTime: Float) {
        preconditionFailure("Must Override \"\(#function)\" in \(type(of: Self.self))")
    }
    
    /**
     Called when the system is removed from the game.
        
     Use teardown to cleanup any system specific data within the game.
     - note: The call to `teardown()` happens immediatley updon removal from the game.
     */
    open func teardown(game: Game) {
        
    }

    /**
     The major sort order for systems.
    
     The phase value is simply a suggestion for grouping your systems.
     The value returned will not affect how or if the system is updated.
     */
    open class var phase: Phase {
        preconditionFailure("Must Override \"\(#function)\" in \(type(of: Self.self))")
    }
    /// The minor sort order for systems
    open class func sortOrder() -> Int? {
        return nil
    }
}

extension PlatformSystem: Hashable {
    public static func ==(lhs: PlatformSystem, rhs: PlatformSystem) -> Bool {
        return Swift.type(of: lhs) == Swift.type(of: rhs)
    }
    public func hash(into hasher: inout Hasher) {
        hasher.combine("\(type(of: self))")
    }
}
