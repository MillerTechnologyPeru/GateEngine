/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

public final class StateMachineSystem: System {
    public override func update(game: Game, input: HID, withTimePassed deltaTime: Float) async {
        for entity in game.entities.filter({$0.hasComponent(StateMachineComponent.self)}) {
            let stateMachineComponent = entity[StateMachineComponent.self]
            if stateMachineComponent.shouldApplyInitialState {
                applyInitialStateIfNeeded(for: stateMachineComponent, of: entity, inGame: game, input: input)
            }
            stateMachineComponent.stateMachine.updateState(for: entity, game: game, input: input, deltaTime: deltaTime)
        }
    }
    
    func applyInitialStateIfNeeded(for component: StateMachineComponent, of entity: Entity, inGame game: Game, input: HID) {
        component.stateMachine.currentState.apply(to: entity, previousState: component.stateMachine.currentState, game: game, input: input)
        component.shouldApplyInitialState = false
    }
    
    public override class var phase: System.Phase {return .updating}
}
