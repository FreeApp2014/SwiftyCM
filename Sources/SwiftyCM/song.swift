//
// Created by freeapp on 20.04.2020.
//
import Foundation
import SwiftyJSON

//Used for supplying Song object with information
public struct SongLoopInformation{
    public var doesLoop: Bool, loopStart: UInt, loopTypeDesc: String;
}

//Enum containing file types that can be downloaded from the API
public enum SongFileType:String {
    case brstm = "brstm", wav = "wav", bwav = "bwav";
}

//The struct for song information received from the game endpoint
public struct PartialSongField{
    public let id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt;
    public func resolveSong() throws -> Song{ //Get full Song object for this PartialSong
        do {
            let e = try Song(self.id);
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
//The struct for song information received from the game endpoint
public struct SearchSongField{
    public let id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt, gameId: String;
    public func resolveSong() throws -> Song{ //Get full Song object for this PartialSong
        do {
            let e = try Song(self.id);
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

//Represents a song object on SCM, typically received from the song endpoint
public struct Song {
    public let id: String, title: String, uploader: String, secLength: UInt, sampleRate: UInt, loop: SongLoopInformation, canDownload: Bool, downloadCount: UInt, game: PartialGameField;
    public init (_ id: String) throws {
        self.id = id;
        guard let e = performGetRequest(url: "https://smashcustommusic.net/json/song/\(self.id)") else {
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
        self.title = json["name"].string!;
        self.uploader = json["uploader"].string!;
        self.canDownload = json["available"].int! == 1;
        self.sampleRate = UInt(json["sample_rate"].string!)!;
        self.game = PartialGameField(id: String(json["game_id"].int!), title: json["game_name"].string!);
        self.loop = SongLoopInformation(doesLoop: json["loop_type"].string! != "None", loopStart:  UInt(json["start_loop_point"].string!)!, loopTypeDesc:  json["loop_type"].string!);
        self.secLength = UInt(json["length"].string!)!;
        self.downloadCount = UInt(json["downloads"].string!)!;
    }
    public func download(inFormat format: SongFileType) -> Data?{ //Download the file in specified file type
        guard let data = performGetRequest(url: "https://smashcustommusic.net/\(format)/\(self.id)") else {
            return nil
        }
        if (data.0.statusCode) != 200 {
            return nil;
        }
        return data.1;
    }
}