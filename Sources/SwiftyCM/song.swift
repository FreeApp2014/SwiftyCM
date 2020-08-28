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

//Represents a song object on SCM, typically received from the song endpoint
public class Song {
    public let id: String, title: String, uploader: String, secLength: UInt, canDownload: Bool, downloadCount: UInt;
    private var iloop: SongLoopInformation? = nil, isampleRate: UInt? = nil, igame: Game? = nil, igameId: String? = nil;
    public var loop: SongLoopInformation {
        get {
            if (self.resolved) {
                return self.iloop!;
            } else {
                try! resolve(self.id);
                return self.iloop!;
            }
        }
    }
    public var sampleRate: UInt {
        get {
            if (self.resolved) {
                return self.isampleRate!;
            } else {
                try! resolve(self.id);
                return self.isampleRate!;
            }
        }
    }
    public var gameId: Int {
     get {
         if (self.igameId == nil) {
             try! resolve(self.id);
         }   else {
               return self.igameId;   
         }
     }
    }
    public var game: Game {
        get {
            if let theGame = self.igame {
                return theGame;
            } else {
                if (self.igameId == nil) {
                    try! resolve(self.id);
                }
                self.igame = (try! Game(self.igameId!));
                return self.igame!;
            }
        }
    }
    private var resolved = false;
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
        self.uploader = json["uploader"].string ?? "Unknown";
        self.canDownload = json["available"].int! == 1;
        self.isampleRate = UInt(json["sample_rate"].string!)!;
        self.igameId = String(json["game_id"].int!);
        self.iloop = SongLoopInformation(doesLoop: json["loop_type"].string! != "None", loopStart:  UInt(json["start_loop_point"].string!)!, loopTypeDesc:  json["loop_type"].string!);
        self.secLength = UInt(json["length"].string!)!;
        self.downloadCount = UInt(json["downloads"].string!)!;
        self.resolved = true;
    }
    public init (id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt){
        self.title = title;
        self.id = id;
        self.secLength = secLength;
        self.uploader = uploader;
        self.canDownload = canDownload;
        self.downloadCount = downloadCount;
    }
    private func resolve (_ id: String) throws {
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

        self.isampleRate = UInt(json["sample_rate"].string!)!;
        self.igameId = String(json["game_id"].int!);
        self.iloop = SongLoopInformation(doesLoop: json["loop_type"].string! != "None", loopStart:  UInt(json["start_loop_point"].string!)!, loopTypeDesc:  json["loop_type"].string!);
        self.resolved = true;
    }
    public init (id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt, gameId: String){
        self.title = title;
        self.id = id;
        self.secLength = secLength;
        self.uploader = uploader;
        self.canDownload = canDownload;
        self.downloadCount = downloadCount;
        self.igameId = gameId;
    }
    public func download(inFormat format: SongFileType) -> Data?{ //Download the file in specified file type
        guard let data = performGetRequest(url: "https://smashcustommusic.net/\(format)/\(self.id)&noIncrement=1") else {
            return nil
        }
        if (data.0.statusCode) != 200 {
            return nil;
        }
        return data.1;
    }
}
