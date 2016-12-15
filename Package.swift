import PackageDescription

let package = Package(
    name: "PerfectSwiftProject",
    dependencies: [
        .Package(url: "https://github.com/PerfectlySoft/Perfect-HTTPServer.git", majorVersion: 2, minor: 0),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-PostgreSQL.git", majorVersion: 2, minor:0),
        .Package(url: "https://github.com/SwiftORM/Postgres-StORM.git", majorVersion: 0, minor: 0),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-RequestLogger.git", majorVersion: 0),
        .Package(url: "https://github.com/PerfectlySoft/Perfect-Curl.git", majorVersion: 2, minor: 0)

    ]
)
