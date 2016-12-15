//
//  Show.swift
//  PerfectSwiftProject
//
//  Created by Iman Zarrabian on 08/11/2016.
//
//

import PerfectLib
import PerfectHTTP
import PostgresStORM
import StORM
import PerfectCURL
import cURL

enum ModelError: Error {
    case unableToDeserialize
    case unableToLoginToExternal
}

private struct Constants {
    static let tvdbAPIKey = "463033F6887DEE59"
}


class Show: PostgresStORM {

    var id = 0
    var tvdb_show_id = 0
    var last_aired_season = 1
    var last_aired_episode = 1
    var title = ""
    var last_aired_episode_title = ""
    var picture_url = ""
    var last_aired_eposide_on = ""


    override open func table() -> String {
        return "shows"
    }

    override func to(_ this: StORMRow) {
        id  = this.data["id"] as! Int
        tvdb_show_id  = this.data["tvdb_show_id"] as! Int
        title = this.data["title"] as! String
        last_aired_episode_title = this.data["last_aired_episode_title"] as! String
        picture_url = this.data["picture_url"] as! String
        last_aired_season = this.data["last_aired_season"] as! Int
        last_aired_episode = this.data["last_aired_episode"] as! Int
        last_aired_eposide_on = this.data["last_aired_eposide_on"] as! String
    }

    func rows() -> [Show] {
        var rows = [Show]()
        for i in 0..<self.results.rows.count {
            let row = Show()
            row.to(self.results.rows[i])
            rows.append(row)
        }
        return rows
    }


    //Updates the current record from tvdb API
    //throws if unable to log into tvdb or deserialize tvdb response
    func updateFromExternal() throws {
        guard let token = loginToExternal() else {
            throw ModelError.unableToLoginToExternal
        }

        let (someTitle, someBanner) = getShowTitleAndBanner(token: token)

        guard let title = someTitle else {
            throw ModelError.unableToDeserialize
        }

        self.title = title

        if let banner = someBanner {
            self.picture_url = "http://thetvdb.com/banners/_cache/" + banner
        }

        //update the rest of show infos
        let loginCurlObject = CURL(url: "https://api.thetvdb.com/series/\(tvdb_show_id)/episodes/query?airedSeason=\(last_aired_season)")

        //Headers
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Authorization: Bearer " + token)
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Accept: application/json")
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")

        //This is a blocking operation
        //use perform with a closure to makie it asynchronous
        let (_, _, body) = loginCurlObject.performFully()

        let str = UTF8Encoding.encode(bytes: body)

        do {
            if let decoded = try str.jsonDecode() as? [String: Any],
                let episodes = decoded["data"] as? [Any],
                let lastEpisode = episodes.last as? [String: Any] {

                if let episodeTitle = lastEpisode["episodeName"] as? String,
                    let episodeNumber = lastEpisode["airedEpisodeNumber"] as? Int,
                    let episodeAiredOn = lastEpisode["firstAired"] as? String {
                    last_aired_episode_title = episodeTitle
                    last_aired_episode = episodeNumber
                    last_aired_eposide_on = episodeAiredOn + " 14:00:00"
                }
            } else {
                throw ModelError.unableToDeserialize
            }
        }
        catch {
            throw ModelError.unableToDeserialize
        }
    }



    private func loginToExternal() -> String? {

        //Call Login
        //curl -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' -d '{"apikey":"463033F6887DEE59"}' 'https://api.thetvdb.com/login'

        let loginCurlObject = CURL(url: "https://api.thetvdb.com/login")
        let loginString = "{\"apikey\":\""+Constants.tvdbAPIKey+"\"}"
        let byteArray = [UInt8](loginString.utf8)

        //Headers
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Accept: application/json")
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")

        //Post body
        loginCurlObject.setOption(CURLOPT_POSTFIELDSIZE, int:byteArray.count)
        loginCurlObject.setOption(CURLOPT_COPYPOSTFIELDS, v: UnsafeMutablePointer(mutating: byteArray))

        //Behaviour options
        //loginCurlObject.setOption(CURLOPT_VERBOSE, int: 1)

        //This is a blocking operation
        //use perform with a closure to makie it asynchronous
        let (_, _, body) = loginCurlObject.performFully()

        let str = UTF8Encoding.encode(bytes: body)

        do {
            if let decoded = try str.jsonDecode() as? [String: Any],
                let token = decoded["token"] as? String {
                return token
            }
            return nil
        }
        catch {
            print("Something went wrong during login deserialization")
            return nil
        }
    }

    private func getShowTitleAndBanner(token: String) -> (String?, String?) {
        //update the show
        let loginCurlObject = CURL(url: "https://api.thetvdb.com/series/\(tvdb_show_id)")

        //Headers
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Authorization: Bearer " + token)
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Accept: application/json")
        loginCurlObject.setOption(CURLOPT_HTTPHEADER, s: "Content-Type: application/json")

        //This is a blocking operation
        //use perform with a closure to makie it asynchronous
        let (_, _, body) = loginCurlObject.performFully()

        let str = UTF8Encoding.encode(bytes: body)

        do {
            if let decoded = try str.jsonDecode() as? [String: Any],
                let serieData = decoded["data"] as? [String: Any] {

                return (serieData["seriesName"] as? String, serieData["banner"] as? String)
            }
            return (nil, nil)
        } catch {
            return (nil, nil)
        }
    }
}

