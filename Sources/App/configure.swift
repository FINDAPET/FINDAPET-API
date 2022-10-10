import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import APNS

// configures your application
public func configure(_ app: Application) throws {
    let appleECP8PrivateKey =
"""
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg7RRS2oUF9Tpy1LPD
WRSI+Pbo/pmBF6+lN13EiZ3vQ2egCgYIKoZIzj0DAQehRANCAATFl2B+xF3n3Jbt
6EPAccB3JU5CzdO7aj3gJvyb9eShAK13/OoPNc/PCYucdNEdG8LsoBxd06EfNuBF
Bz1VuMrd
-----END PRIVATE KEY-----
"""
    
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: Data(appleECP8PrivateKey.utf8)),
            keyIdentifier: "CX7HTV253D",
            teamIdentifier: "FY2MUX2TBL"
        ),
        topic: "com.artemiy.FINDAPET-App",
        environment: .production
    )
    
    // uncomment to serve files from /Public folder
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    
    app.views.use(.leaf)
    
    app.routes.defaultMaxBodySize = "500mb"

    // register routes
    try routes(app)
    
    app.migrations.add(
        CreateAd(),
        CreateDeal(),
        CreateUser(),
        CreateUserToken(),
        CreateOffer(),
        CreateChatRoom(),
        CreateMessage()
    )
    
    #if DEBUG
    try app.autoRevert().wait()
    #endif
    
    try app.autoMigrate().wait()
}
