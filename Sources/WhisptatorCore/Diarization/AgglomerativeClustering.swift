import Foundation

public enum EmbeddingMath {
    public static func l2Normalize(_ vector: [Double]) -> [Double] {
        var norm = 0.0
        for v in vector { norm += v * v }
        norm = norm.squareRoot()
        guard norm > 1e-9 else { return vector }
        return vector.map { $0 / norm }
    }

    /// Cosine distance in [0, 2]; assumes normalized inputs for speed.
    public static func cosineDistance(_ a: [Double], _ b: [Double]) -> Double {
        precondition(a.count == b.count)
        var dot = 0.0
        var na = 0.0
        var nb = 0.0
        for i in 0..<a.count {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let denom = (na * nb).squareRoot()
        guard denom > 1e-12 else { return 1.0 }
        return 1.0 - dot / denom
    }
}

/// Average-linkage agglomerative clustering on cosine distance.
public enum AgglomerativeClustering {
    public static func cluster(vectors: [[Double]], distanceThreshold: Double) -> [Int] {
        let n = vectors.count
        guard n > 0 else { return [] }
        let normalized = vectors.map { EmbeddingMath.l2Normalize($0) }
        guard n > 1 else { return [0] }

        var dist = [[Double]](repeating: [], count: n)
        for i in 0..<n {
            var row = [Double](repeating: 0, count: n)
            for j in 0..<i {
                let d = EmbeddingMath.cosineDistance(normalized[i], normalized[j])
                row[j] = d
                dist[j].append(d)
            }
            dist[i] = row
        }

        var memberships: [[Int]] = (0..<n).map { [$0] }
        var active = Array(repeating: true, count: n)
        var activeCount = n

        while activeCount > 1 {
            var bestI = -1
            var bestJ = -1
            var bestDistance = Double.infinity
            for i in 0..<n where active[i] {
                for j in 0..<i where active[j] {
                    let d = averageLinkageDistance(i: i, j: j, dist: dist, memberships: memberships)
                    if d < bestDistance {
                        bestDistance = d
                        bestI = i
                        bestJ = j
                    }
                }
            }
            if bestI < 0 || bestDistance > distanceThreshold { break }

            memberships[bestI].append(contentsOf: memberships[bestJ])
            memberships[bestJ] = []
            active[bestJ] = false
            activeCount -= 1
        }

        var labels = [Int](repeating: -1, count: n)
        var clusterIndex = 0
        for i in 0..<n where active[i] {
            for member in memberships[i] {
                labels[member] = clusterIndex
            }
            clusterIndex += 1
        }
        return labels
    }

    private static func averageLinkageDistance(
        i: Int,
        j: Int,
        dist: [[Double]],
        memberships: [[Int]]
    ) -> Double {
        let groupI = memberships[i]
        let groupJ = memberships[j]
        guard !groupI.isEmpty, !groupJ.isEmpty else { return .infinity }
        var sum = 0.0
        for a in groupI {
            for b in groupJ {
                let lo = max(a, b)
                let hi = min(a, b)
                sum += dist[lo][hi]
            }
        }
        return sum / Double(groupI.count * groupJ.count)
    }
}
