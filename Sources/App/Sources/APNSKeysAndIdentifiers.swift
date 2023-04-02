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
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg7RRS2oUF9Tpy1LPD
WRSI+Pbo/pmBF6+lN13EiZ3vQ2egCgYIKoZIzj0DAQehRANCAATFl2B+xF3n3Jbt
6EPAccB3JU5CzdO7aj3gJvyb9eShAK13/OoPNc/PCYucdNEdG8LsoBxd06EfNuBF
Bz1VuMrd
-----END PRIVATE KEY-----
"""
let keyIdentifier: JWKIdentifier = "CX7HTV253D"
let teamIdentifier: StaticString = "FY2MUX2TBL"
let topic: StaticString = "com.artemiy.FINDAPET-App"
