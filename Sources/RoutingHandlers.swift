//
//  RoutingHandlers.swift
//  PerfectSwiftProject
//
//  Created by Iman Zarrabian on 04/11/2016.
//
//


import PerfectHTTP
import PerfectLib

func makeURLRoutes() -> Routes {

    //main API routes
    var routes = Routes()
    var api = Routes()

    //GET /shows
    api.add(method: .get, uri: "/shows", handler: {
        request, response in

        let show = Show()
        do {
            try show.select(
                whereclause: "",
                params: [],
                orderby: ["id"])

            let results = show.rows()

            let jsonArray = results.map { show -> [String: Any] in
                let showDict: [String: Any] = ["id": show.id, "tvdb_show_id": show.tvdb_show_id, "title": show.title, "last_aired_episode_title": show.last_aired_episode_title, "last_aired_season": show.last_aired_season, "last_aired_espisode": show.last_aired_episode, "picture_url": show.picture_url, "last_aired_eposide_on": show.last_aired_eposide_on]
                return showDict
            }


            let encoded = try! jsonArray.jsonEncodedString()
            response.setBody(string: encoded)
        }
        catch {
            print("error catched \(error)")
        }

        response.completed()
    })

    //POST /shows
    api.add(method: .post, uri: "/shows", handler: {
        request, response in

        guard let externalId = request.param(name: "tvdb_show_id"),
            let integerExternal = Int(externalId),
            let lastAiredSeason = request.param(name: "last_aired_season"),
            let integerSeason = Int(lastAiredSeason) else {

            response.status = .badRequest
            let reponseDict = ["error" : "missing tvdb_show_id or last_aired_season"]
            try! response.setBody(json: reponseDict)

            response.completed()
            return
        }


        let show = Show()

        //try to fetch an existing show with the same tvdb_show_id in DB
        do {
            try show.find([("tvdb_show_id", integerExternal)])
            let results = show.rows()
            if results.count == 1 {
                //If we found one matching show and excatly one, we just update it
                show.id = results.first!.id
            }
        } catch {
            response.status = .internalServerError
            let reponseDict = ["error" : "unknown error"]
            try! response.setBody(json: reponseDict)

            response.completed()
        }

        //update the rest of the show
        show.tvdb_show_id = integerExternal
        show.last_aired_season = integerSeason

        do {
            try show.updateFromExternal()
            try show.save {
                show_id in show.id = show_id as! Int
            }

            //update the show synchronously
            let showDict: [String: Any] = ["id": show.id, "tvdb_show_id": show.tvdb_show_id, "title": show.title, "last_aired_episode_title": show.last_aired_episode_title, "last_aired_season": show.last_aired_season, "last_aired_espisode": show.last_aired_episode, "picture_url": show.picture_url, "last_aired_eposide_on": show.last_aired_eposide_on]


            try! response.setBody(json: showDict)

        } catch ModelError.unableToLoginToExternal {
            print("Unable to login")
            
            response.status = .internalServerError
            let reponseDict = ["error" : "unable to login to exernal"]
            try! response.setBody(json: reponseDict)

            response.completed()

        } catch ModelError.unableToDeserialize {
            print("Unable to deserialize")

            response.status = .internalServerError
            let reponseDict = ["error" : "unable to deserialize from external"]
            try! response.setBody(json: reponseDict)

            response.completed()
        } catch  {
            response.status = .internalServerError
            let reponseDict = ["error" : "unknown error"]
            try! response.setBody(json: reponseDict)

            response.completed()
            print("error catched \(error)")
        }


        response.completed()
    })


    //PUT /shows
    api.add(method: .put, uri: "/shows", handler: {
        request, response in
        let updateString = request.param(name: "update", defaultValue: "false")
        response.setBody(string: "put api " + request.path + " called with update " + updateString!)

        //Show.updateShows()

        response.completed()
    })

    //GET /shows/{id}
    api.add(method: .get, uri: "/shows/{id}", handler: {
        request, response in
        let id = request.urlVariables["id"]
        response.setBody(string: "get api " + request.path + " called with id " + id!)
        response.completed()
    })

    //version specific API routes
    var apiRoutesV1 = Routes(baseUri: "/v1")
    var apiRoutesV2 = Routes(baseUri: "/v2")

    apiRoutesV2.add(method: .get, uri: "/favs", handler: {
        request, response in
        response.setBody(string: "get favs api " + request.path + " called")
        response.completed()
    })

    apiRoutesV1.add(routes: api)
    apiRoutesV2.add(routes: api)
    routes.add(routes: apiRoutesV1)
    routes.add(routes : apiRoutesV2)

    return routes
}
