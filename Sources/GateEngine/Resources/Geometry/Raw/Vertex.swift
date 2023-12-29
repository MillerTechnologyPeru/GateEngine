/*
 * Copyright © 2023-2024 Dustin Collins (Strega's Gate)
 * All Rights Reserved.
 *
 * http://stregasgate.com
 */

import GameMath

//TODO: Subscripts index by 0..<2 for all sub types would be nice

/// A 3D point and associated values. This is used to construct `Triangle`s.
public struct Vertex: Codable, Equatable, Hashable {
    internal var storage: [Float] = Array(repeating: 0, count: 17)

    /// The x component of the position
    public var x: Float {
        get {
            return storage[0]
        }
        set {
            storage[0] = newValue
        }
    }
    /// The y component of the position
    public var y: Float {
        get {
            return storage[1]
        }
        set {
            storage[1] = newValue
        }
    }
    /// The z component of the position
    public var z: Float {
        get {
            return storage[2]
        }
        set {
            storage[2] = newValue
        }
    }
    /// The x component of the normal
    public var nx: Float {
        get {
            return storage[3]
        }
        set {
            storage[3] = newValue
        }
    }
    /// The y component of the normal
    public var ny: Float {
        get {
            return storage[4]
        }
        set {
            storage[4] = newValue
        }
    }
    /// The z component of the normal
    public var nz: Float {
        get {
            return storage[5]
        }
        set {
            storage[5] = newValue
        }
    }
    /// The horizontal vertical texture coordinate
    public var u1: Float {
        get {
            return storage[6]
        }
        set {
            storage[6] = newValue
        }
    }
    /// The vertical texture coordinate
    public var v1: Float {
        get {
            return storage[7]
        }
        set {
            storage[7] = newValue
        }
    }

    /// The horizontal vertical texture coordinate
    public var u2: Float {
        get {
            return storage[8]
        }
        set {
            storage[8] = newValue
        }
    }
    /// The vertical texture coordinate
    public var v2: Float {
        get {
            return storage[9]
        }
        set {
            storage[9] = newValue
        }
    }
    /// The tangent. Used to compute tangent space normals of a `Triangle`.
    var tangent: Direction3 {
        get {
            return Direction3(x: storage[10], y: storage[11], z: storage[12])
        }
        set {
            storage[10] = newValue.x
            storage[11] = newValue.y
            storage[12] = newValue.z
        }
    }
    /// The vertex color.
    public var color: Color {
        get {
            return Color(storage[13], storage[14], storage[15], storage[16])
        }
        set {
            storage[13] = newValue.red
            storage[14] = newValue.green
            storage[15] = newValue.blue
            storage[16] = newValue.alpha

        }
    }
    /// The location in 3D space
    public var position: Position3 {
        get {
            return Position3(x: x, y: y, z: z)
        }
        set {
            x = newValue.x
            y = newValue.y
            z = newValue.z
        }
    }
    /// The direction this vertex points, used for shading
    public var normal: Direction3 {
        get {
            return Direction3(x: nx, y: ny, z: nz)
        }
        set {
            nx = newValue.x
            ny = newValue.y
            nz = newValue.z
        }
    }
    /// Texture coordante
    public var texturePosition1: Position2 {
        get {
            return Position2(x: u1, y: v1)
        }
        set {
            u1 = newValue.x
            v1 = newValue.y
        }
    }

    /// Texture coordante
    public var texturePosition2: Position2 {
        get {
            return Position2(x: u2, y: v2)
        }
        set {
            u2 = newValue.x
            v2 = newValue.y
        }
    }

    public init(
        _ position: Position3 = .zero,
        _ normal: Direction3 = .zero,
        _ uvSet1: Position2 = .zero,
        _ uvSet2: Position2 = .zero,
        color: SIMD4<Float> = SIMD4(0.5, 0.5, 0.5, 1)
    ) {
        self.init(
            px: position.x,
            py: position.y,
            pz: position.z,
            nx: normal.x,
            ny: normal.y,
            nz: normal.z,
            tu1: uvSet1.x,
            tv1: uvSet1.y,
            tu2: uvSet2.x,
            tv2: uvSet2.y,
            cr: color[0],
            cg: color[1],
            cb: color[2],
            ca: color[3]
        )
    }

    public init(
        px: Float,
        py: Float,
        pz: Float,
        nx: Float = 0,
        ny: Float = 0,
        nz: Float = 0,
        tu1: Float = 0,
        tv1: Float = 0,
        tu2: Float = 0,
        tv2: Float = 0,
        cr: Float = 0.5,
        cg: Float = 0.5,
        cb: Float = 0.5,
        ca: Float = 1
    ) {
        self.storage = [px, py, pz, nx, ny, nz, tu1, tv1, tu2, tv2, 0, 0, 0, cr, cg, cb, ca]
    }

    /// - returns: `true` if `self` is within `threshold` of `v`.
    internal func isSimilar(to vertex: Vertex, threshold: Float = 0.001) -> Bool {
        guard threshold > 0 else { return self.storage == vertex.storage }
        guard self.position.distance(from: vertex.position) <= threshold else { return false }
        guard self.normal.angle(to: vertex.normal) <= Radians(threshold) else { return false }
        guard self.texturePosition1.distance(from: vertex.texturePosition1) <= threshold else {
            return false
        }
        return true
    }

    public static func * (lhs: Self, rhs: Matrix4x4) -> Self {
        var lhs = lhs
        lhs.position = lhs.position * rhs
        let m3 = Matrix3x3(rhs)
        lhs.normal = lhs.normal * m3
        lhs.tangent = lhs.tangent * m3
        return lhs
    }
}
extension Vertex {
    public static func *= (lhs: inout Vertex, rhs: Float) {
        lhs = lhs * rhs
    }
    public static func * (lhs: Vertex, rhs: Float) -> Vertex {
        return Vertex(lhs.position * rhs, lhs.normal * rhs, lhs.texturePosition1)
    }

    public static func /= (lhs: inout Vertex, rhs: Float) {
        lhs = lhs * rhs
    }
    public static func / (lhs: Vertex, rhs: Float) -> Vertex {
        return Vertex(lhs.position / rhs, lhs.normal / rhs, lhs.texturePosition1)
    }
}

extension Array where Element == Vertex {
    /// An array of triangles constructed from the vertex array
    public var triangles: [Triangle] {
        return stride(from: 0, to: count, by: 3).map({
            let slice = Array(self[$0 ..< Swift.min($0 + 3, count)])
            return Triangle(v1: slice[0], v2: slice[1], v3: slice[2], repairIfNeeded: false)
        })
    }
}
