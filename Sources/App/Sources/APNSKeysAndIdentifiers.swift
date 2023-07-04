//
//  File.swift
//  
//
//  Created by Artemiy Zuzin on 10.10.2022.
//

import Foundation
import JWTKit

let appleECP8PrivateKey: StaticString =
"""
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg69Ku2pgPfIdO/ETn
k5xNNIuzzTja9SsdlztTgB+SWxegCgYIKoZIzj0DAQehRANCAAQWvcQqtJOEVhhM
bbW2pGKxyoXCmQbU2E+It3+mZGdoWx822Smb4ANiJ2GAwsJCb/hwHvyZk8TzEPHs
Wbn+pTYy
-----END PRIVATE KEY-----
"""
let keyIdentifier: JWKIdentifier = "35PB3PQBA3"
let teamIdentifier: StaticString = "FY2MUX2TBL"
let topic: StaticString = "com.artemiy.FINDAPET-App"
