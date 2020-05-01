//
// Created by freeapp on 20.04.2020.
//

import Foundation
import SwiftyJSON

//Represents a game object on SCM, typically received from the game endpoint
public struct Game {
    public let id: String, title: String, songCount: UInt;
    public var songs: [PartialSongField];
    public init(_ id: String) throws {
        self.id = id;
        guard let e = performGetRequest(url: "https://smashcustommusic.net/json/game/\(self.id)") else {
            throw SCMError.httpRequestError
        };
        let json = JSON(data: e.1);
        guard let state = json["ok"].bool else {
            throw SCMError.otherApiError
        }
        if (state != true){
            if (json["error"].string! == "404") {
                throw SCMError.objectNotFoundError
            } else {
                throw SCMError.otherApiError
            }
        }
        self.title = json["game_name"].string!;
        self.songs = [];
        self.songCount = UInt(json["track_count"].int!);
        guard let songs = json["songs"].array else {return}
        for song in songs{
            let songo = PartialSongField(id: String(song["song_id"].int!),
                    title: song["song_name"].string!,
                    secLength:  UInt(song["song_length"].string!)!,
                    uploader: song["song_uploader"].string ?? "unknown",
                    canDownload: song["song_available"].int! == 1,
                    downloadCount: UInt(song["song_downloads"].string!)!);
            self.songs.append(songo);
        }
    }
}



//The struct for game information received from the song endpoint
public struct PartialGameField{
    public let id: String, title: String;
    public func resolveGame() throws -> Game{ //Get full Game object for this PartialGame
        do{
            let e = try Game(self.id);
            return e;
        } catch SCMError.httpRequestError {
            throw SCMError.httpRequestError
        } catch SCMError.objectNotFoundError {
            throw SCMError.objectNotFoundError
        } catch SCMError.otherApiError {
            throw SCMError.otherApiError
        }
    }
}

//The struct for game information from gamelist
public struct GameListGameField {
    public let id: String, title: String, songCount: UInt;
    public func resolveGame() throws -> Game{ //Get full Game object for this PartialGame
        do{
            let e = try Game(self.id);
            return e;
        } catch SCMError.httpRequestError {
            throw SCMError.httpRequestError
        } catch SCMError.objectNotFoundError {
            throw SCMError.objectNotFoundError
        } catch SCMError.otherApiError {
            throw SCMError.otherApiError
        }
    }
}