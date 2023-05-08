/*
 * Copyright © 2023 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GameMath

@MainActor public final class Renderer {
    let backend: RendererBackend = getDefaultBackend()
    
    lazy var rectOriginCentered: Geometry = {
        let positions: [Float] = [-0.5, -0.5, 0.0,
                                   0.5, -0.5, 0.0,
                                  -0.5,  0.5, 0.0,
                                  -0.5,  0.5, 0.0,
                                   0.5, -0.5, 0.0,
                                   0.5,  0.5, 0.0]
        let uvs: [Float] = [0.0, 0.0,
                            1.0, 0.0,
                            0.0, 1.0,
                            0.0, 1.0,
                            1.0, 0.0,
                            1.0, 1.0]
        let indicies: [UInt16] = [0,1,2,3,4,5]
        let raw = RawGeometry(positions: positions, uvSets: [uvs], normals: nil, tangents: nil, colors: nil, indicies: indicies)
        return Geometry(raw)
    }()
    lazy var rectOriginTopLeft: Geometry = {
        let positions: [Float] = [0.0, 0.0, 0.0,
                                  1.0, 0.0, 0.0,
                                  0.0, 1.0, 0.0,
                                  0.0, 1.0, 0.0,
                                  1.0, 0.0, 0.0,
                                  1.0, 1.0, 0.0]
        let uvs: [Float] = [0.0, 0.0,
                            1.0, 0.0,
                            0.0, 1.0,
                            0.0, 1.0,
                            1.0, 0.0,
                            1.0, 1.0]
        let indicies: [UInt16] = [0,1,2,3,4,5]
        let raw = RawGeometry(positions: positions, uvSets: [uvs], normals: nil, tangents: nil, colors: nil, indicies: indicies)
        return Geometry(raw)
    }()
    
    func draw(_ renderTarget: RenderTarget,
              into destinationRenderTarget: RenderTarget,
              options: RenderTarget.RenderTargetFillOptions,
              sampler: RenderTarget.RenderTargetFillSampleFilter) {
        guard rectOriginCentered.state == .ready else {return}
        
        @_transparent
        func matrices(withSize size: Size2) -> Matrices {
            let ortho = Matrix4x4(orthographicWithTop: 0, left: 0, bottom: size.height, right: size.width, near: 0, far: Float(Int32.max))
            let view = Matrix4x4(position: Position3(x: 0, y: 0, z: 1000000))
            return Matrices(projection: ortho, view: view)
        }

        let material: Material = Material() { material in
            material.vertexShader = SystemShaders.renderTargetVertexShader
            material.channel(0) { channel in
                channel.texture = renderTarget.texture
                if options.contains(.flipHorizontal) {
                    channel.scale.x = -1
                }
                if options.contains(.flipVertical) {
                    channel.scale.y = -1
                }
                switch sampler {
                case .linear:
                    channel.sampleFilter = .linear
                case .nearest:
                    channel.sampleFilter = .nearest
                }
            }
        }
        let size = destinationRenderTarget.size
        
        let scale = Size3(width: destinationRenderTarget.size.width, height: destinationRenderTarget.size.height, depth: 1)
        let transform = Transform3(position: Position3(size.width / 2, size.height/2, 0), scale: scale)
        let matrices = matrices(withSize: size)
        let flags = DrawFlags(depthTest: .always, depthWrite: .disabled, winding: .clockwise)
        
        if let geometryBackend = Game.shared.resourceManager.geometryCache(for: rectOriginCentered.cacheKey)?.geometryBackend {
            let command = DrawCommand(backends: [geometryBackend], transforms: [transform], material: material, flags: flags)
            backend.draw(command, camera: nil, matrices: matrices, renderTarget: destinationRenderTarget)
        }
    }
    
    @inline(__always)
    func draw(_ drawCommand: DrawCommand, camera: Camera?, matrices: Matrices, renderTarget: RenderTarget) {
        self.backend.draw(drawCommand, camera: camera, matrices: matrices, renderTarget: renderTarget)
    }
}

@MainActor internal protocol RendererBackend {
    func draw(_ drawCommand: DrawCommand, camera: Camera?, matrices: Matrices, renderTarget: RenderTarget)
}

@_transparent
@MainActor fileprivate func getDefaultBackend() -> RendererBackend {
#if canImport(Metal)
    return MetalRenderer()
#elseif canImport(WebGL2)
    return WebGL2Renderer()
#elseif canImport(WinSDK)
    return DX12Renderer()
#else
    #error("Not implemented.")
#endif
}
