import Fluent
import FluentPostgresDriver
import Leaf
import Vapor
import APNS

// configures your application
public func configure(_ app: Application) throws {
    
    app.apns.configuration = try .init(
        authenticationMethod: .jwt(
            key: .private(pem: Data(appleECP8PrivateKey.utf8)),
            keyIdentifier: keyIdentifier,
            teamIdentifier: teamIdentifier
        ),
        topic: topic,
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
    
    app.routes.defaultMaxBodySize = "2mb"
    
    // activate subscription manager
    SubscriptionManager.shared.start(app)

    // register routes
    try routes(app)
    
    app.migrations.add(
        CreateAd(),
        CreateDeal(),
        CreateUser(),
        CreateUserToken(),
        CreateOffer(),
        CreateChatRoom(),
        CreateMessage(),
        CreateComplaint(),
        CreateNotificationScreen(),
        CreatePetBreed(),
        CreatePetType(),
        CreateSubscription(),
        CreateTitleSubscription()
    )
    
    #if DEBUG
    try app.autoRevert().wait()
    #endif
    
    try app.autoMigrate().wait()
}
