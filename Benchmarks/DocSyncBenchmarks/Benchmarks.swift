import Benchmark
import DocSyncKit
import Foundation

let benchmarks: @Sendable () -> Void = {
    Benchmark.defaultConfiguration = .init(
        metrics: [.wallClock],
        warmupIterations: 1,
        maxDuration: .seconds(3),
    )

    Benchmark("check_small") { benchmark in
        let fixture = try FixtureBuilder.build(rules: 20, sourcesPerRule: 10, fileSizeKB: 8)
        defer { FixtureBuilder.cleanup(fixture) }
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let runner = CheckRunner(configURL: fixture.configURL)
            try await blackHole(runner.run())
        }
    }

    Benchmark("check_large") { benchmark in
        let fixture = try FixtureBuilder.build(rules: 100, sourcesPerRule: 5, fileSizeKB: 4)
        defer { FixtureBuilder.cleanup(fixture) }
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let runner = CheckRunner(configURL: fixture.configURL)
            try await blackHole(runner.run())
        }
    }

    Benchmark("update_small") { benchmark in
        for _ in benchmark.scaledIterations {
            let fixture = try FixtureBuilder.build(rules: 20, sourcesPerRule: 10, fileSizeKB: 8)
            defer { FixtureBuilder.cleanup(fixture) }
            let runner = UpdateRunner(configURL: fixture.configURL)
            try await runner.run()
        }
    }

    Benchmark("update_large") { benchmark in
        for _ in benchmark.scaledIterations {
            let fixture = try FixtureBuilder.build(rules: 100, sourcesPerRule: 5, fileSizeKB: 4)
            defer { FixtureBuilder.cleanup(fixture) }
            let runner = UpdateRunner(configURL: fixture.configURL)
            try await runner.run()
        }
    }

    Benchmark(
        "check_realistic",
        configuration: .init(metrics: [.wallClock], warmupIterations: 1, maxDuration: .seconds(20)),
    ) { benchmark in
        let fixture = try FixtureBuilder.build(
            rules: 12,
            sourcesPerRule: 5,
            fileSizeKB: 4,
            extraFiles: 50000,
            useGlobPatterns: true,
        )
        defer { FixtureBuilder.cleanup(fixture) }
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let runner = CheckRunner(configURL: fixture.configURL)
            try await blackHole(runner.run())
        }
    }
}
