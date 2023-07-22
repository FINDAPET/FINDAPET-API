import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import APNS

// configures your application
public func configure(_ app: Application) throws {
    
//    MARK: - APNS
    #if DEBUG
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: .init(String(appleECP8PrivateKey).utf8)),
            keyIdentifier: keyIdentifier,
            teamIdentifier: .init(teamIdentifier)
        ),
        topic: .init(topic),
        environment: .sandbox
    )
    #else
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: Data(String(appleECP8PrivateKey).utf8)),
            keyIdentifier: keyIdentifier,
            teamIdentifier: .init(teamIdentifier)
        ),
        topic: .init(topic),
        environment: .production
    )
    #endif
    
//    MARK: - Middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.workingDirectory))
    app.middleware.use(app.sessions.middleware)
    
//    MARK: - Database
    app.databases.use(.postgres(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .psql)
    
//    MARK: - Leaf
    app.views.use(.leaf)
    
    
//    MARK: - Settings
    app.routes.defaultMaxBodySize = "50mb"
    app.http.server.configuration.responseCompression = .enabled
    app.http.server.configuration.requestDecompression = .enabled(limit: .none)
    
//    MARK: - Subscription Manager
    // activate subscription manager
    SubscriptionManager.shared.start(app)

//    MARK: - Routes
    // register routes
    try routes(app)
    
    
//    MARK: - Migrations
    app.migrations.add(
        CreateUser(),
        CreateTitleSubscription(),
        CreateSubscription(),
        CreatePetType(),
        CreatePetBreed(),
        CreateDeal(),
        CreateAd(),
        CreateDeviceToken(),
        CreateUserToken(),
        CreateOffer(),
        CreateChatRoom(),
        CreateComplaint(),
        CreateNotificationScreen(),
        CreateSearchTitle(),
        CreateMessage()
    )
    
//    MARK: - Migration Management
    #if DEBUG
    try app.autoRevert().wait()
    #endif
    
    try app.autoMigrate().wait()
}
