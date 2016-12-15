//
//  DBHandler.swift
//  PerfectSwiftProject
//
//  Created by Iman Zarrabian on 08/11/2016.
//
//

import PostgreSQL
import PostgresStORM

struct DBHandler {
    static func connectDB() {

         connect = PostgresConnect(
            host: "localhost",
            username: "perfectserver",
            password: "perfect",
            database: "spoilalert",
            port: 5432
        )
    }
}
