//
// Created by freeapp on 20.04.2020.
//

import Foundation
import SwiftyJSON

/// Represents a game object on SCM, typically received from the game endpoint
public struct Game {
    /// The game ID
    public let id: String,
            /// Game title
            title: String,
            /// Game song count
            songCount: UInt;
    /// Array of `Song` in the game
    public var songs: [Song];

    /// Initialize a new game object
    ///
    /// - Parameter id: The ID of the game on SCM
    /// - Throws: `SCMError`
    public init(_ id: String) throws {
        guard let intVal = Int(id) else {
            throw SCMError.otherApiError;
        }
        self.id = String(intVal);
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
            let songo = Song(id: String(song["song_id"].int!),
                    title: song["song_name"].string!,
                    secLength:  UInt(song["song_length"].string ?? "0")!,
                    uploader: song["song_uploader"].string ?? "unknown",
                    canDownload: song["song_available"].int! == 1,
                    downloadCount: UInt(song["song_downloads"].string ?? "0")!);
            self.songs.append(songo);
        }
    }
}
/// The struct for game information from gamelist
@available(*, deprecated)
public struct GameListGameField {
    /// Game ID
    public let id: String,
            /// Game title
            title: String,
            /// Game song count
            songCount: UInt;
    /// Resolve the partial game to full game
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
