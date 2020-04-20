import Foundation
import FoundationNetworking
import SwiftyJSON

func performGetRequest(url: String) -> (URLResponse, Data)? {
    let url: URL = URL(string: url)!;
    var returned: (URLResponse, Data)?;
    let task = URLSession.shared.dataTask(with: url){ data, response, err in
        if (err != nil) {
            returned = nil;
        } else {
            returned = (response!, data!);
        }
    }
    task.resume();
    while (task.state != .completed){
        Thread.sleep(forTimeInterval: 0.001);
    }
    return returned;
}

//This struct is reserved for future use
public struct SCMRestrictedAPIClient {
    private var apiKey: String;
    public init (apiKey: String){
        self.apiKey = apiKey;
    }
}

//Represents a game object on SCM, typically received from the game endpoint
public struct Game {
    public var id: String, title: String, songs: [PartialSongField];
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
        guard let songs = json["songs"].array else {return}
        for song in songs{
            let songo = PartialSongField(id: String(song["song_id"].int!), 
                    title: song["song_name"].string!, 
                    secLength:  UInt(song["song_length"].string!)!, 
                    uploader: song["song_uploader"].string!, 
                    canDownload: song["song_available"].int! == 1, 
                    downloadCount: UInt(song["song_downloads"].string!)!);
            self.songs.append(songo);
        }
    }
}

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
    public var id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt;
    public func resolveSong() throws -> Song{ //Get full Song object for this PartialSong
        do {
            let e = try Song(self.id);
            return e;
        } catch {
            throw SCMError.nestedError
        }
    }
}

//The struct for game information received from the song endpoint
public struct PartialGameField{
    public var id: String, title: String;
    public func resolveGame() throws -> Game{ //Get full Game object for this PartialGame
        do{
            let e = try Game(self.id);
            return e;
        } catch {
            throw SCMError.nestedError;
        };
    }
}

public enum SCMError: Error{
    case jsonParseError, httpRequestError, objectNotFoundError, otherApiError, nestedError
}

//Represents a song object on SCM, typically received from the song endpoint
public struct Song {
    public var id: String, title: String, uploader: String, secLength: UInt, sampleRate: UInt, loop: SongLoopInformation, canDownload: Bool, downloadCount: UInt, game: PartialGameField;
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
        self.loop = SongLoopInformation(doesLoop: json["loop_type"].string! == "None", loopStart:  UInt(json["start_loop_point"].string!)!, loopTypeDesc:  json["loop_type"].string!);
        self.secLength = UInt(json["length"].string!)!;
        self.downloadCount = UInt(json["downloads"].string!)!;
    }
//    public func download(inFormat: SongFileType) -> Data?{ //Download the file in specified file type
//
//    }
}