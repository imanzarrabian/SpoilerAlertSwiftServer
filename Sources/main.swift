import PerfectLib
import PerfectHTTP
import PerfectHTTPServer
import PerfectRequestLogger



//Connect DB
DBHandler.connectDB()

// Create HTTP server.
let server = HTTPServer()
let apiRoutes = makeURLRoutes()

// Add the routes to the server.
server.addRoutes(apiRoutes)

// Set a listen port of 8181
server.serverPort = 8181

do {
    // Launch the HTTP server.
    try server.start()
} catch PerfectError.networkError(let err, let msg) {
    print("Network error thrown: \(err) \(msg)")
}

// Instantiate a logger
let myLogger = RequestLogger()

// Add the filters
// Request filter at high priority to be executed first
server.setRequestFilters([(myLogger, .low)])
