//
// Created by freeapp on 20.04.2020.
//
import Foundation
import SwiftyJSON

/// Information about song looping for supplying with the Song object
public struct SongLoopInformation{
    /// Indication whether BRSTM file loops
    public var doesLoop: Bool;
    /// Loop start sample number
    public var loopStart: UInt;
    /// The string containing the description of looping, as listed on SCM song page
    public var loopTypeDesc: String;
}

/// Enum containing file types that can be downloaded from the API
public enum SongFileType: String {
    case brstm = "brstm", wav = "wav", bwav = "bwav";
}

/// Represents a song object on SCM, typically received from the song endpoint
public class Song {
    /// Song ID in SCM
    public let id: String,
            /// Song title
            title: String,
            /// Uploader username
            uploader: String,
            // Length in seconds
            secLength: UInt,
            /// Availability to download
            canDownload: Bool,
            /// Downloads count
            downloadCount: UInt;
    private var iloop: SongLoopInformation? = nil, isampleRate: UInt? = nil, igame: Game? = nil, igameId: String? = nil;
    /// Looping information about song
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
    /// Song audio sample rate in Hz
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
    /// The ID of the game the song originates from
    public var gameId: String {
        get {
            if (self.igameId == nil) {
                try! resolve(self.id);
            }
            return self.igameId!;
        }
    }
    /// Game the song belongs to
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

    /// Initialize a song object
    ///
    /// - Parameter id: ID of the requested song on SCM
    /// - Throws: SCMError.httpRequestError in case of request failure
    /// - Throws: SCMError.otherApiError in case the client did not understand the response
    /// - Throws: SCMError.objectNotFoundError in case the requested song does not exist
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
        self.isampleRate = UInt(json["sample_rate"].string ?? "0")!;
        self.igameId = String(json["game_id"].int!);
        self.iloop = SongLoopInformation(doesLoop: json["loop_type"].string! != "None", loopStart:  UInt(json["start_loop_point"].string!)!, loopTypeDesc:  json["loop_type"].string!);
        self.secLength = UInt(json["length"].string ?? "0")!;
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
    /// Download song in needed format
    ///
    /// - Parameter format: The format needed to download
    /// - Returns: Result which is Data of the requested song file on success, `SCMError` on failure
    public func download(inFormat format: SongFileType) -> Result<Data, SCMError> {

        guard let data = performGetRequest(url: "https://smashcustommusic.net/\(format)/\(self.id)&noIncrement=1") else {
            return .failure(.httpRequestError)
        }

        if (data.0.statusCode) != 200 {
            if (data.0.statusCode == 404) {
                return .failure(.objectNotFoundError)
            } else {
                return .failure(.otherApiError)
            }
        }

        return .success(data.1);
    }
}
