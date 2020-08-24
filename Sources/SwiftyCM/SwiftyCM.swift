import Foundation
import FoundationNetworking
import SwiftyJSON

func performGetRequest(url: String) -> (HTTPURLResponse, Data)? {
    let url: URL = URL(string: url)!;
    var returned: (HTTPURLResponse, Data)?;
    let task = URLSession.shared.dataTask(with: url){ data, response, err in
        if (err != nil) {
            returned = nil;
        } else {
            returned = (response! as! HTTPURLResponse, data!);
        }
    }
    task.resume();
    while (task.state != .completed){
        Thread.sleep(forTimeInterval: 0.001);
    }
    return returned;
}

//This struct is reserved for future use
public struct SCMClient {
    private var apiKey: String;
    public init (apiKey: String){
        self.apiKey = apiKey;
    }
    public static func gameList() throws -> [GameListGameField]{
        var returnval: [GameListGameField] = [];
        guard let http = performGetRequest(url: "https://smashcustommusic.net/json/gamelist/") else {
            throw SCMError.httpRequestError
        }
        let json = JSON(data: http.1);
        guard let gameList = json["games"].array else {
            throw SCMError.jsonParseError;
        }
        for game in gameList {
            returnval.append(GameListGameField(id: String(game["game_id"].int!), title: game["game_name"].string!, songCount: UInt(game["song_count"].int!)));
        }
        return returnval;
    }
    public static func search (_ query: String) throws -> [Song]{
        var returnval: [Song] = [];
        guard let http = performGetRequest(url: "https://smashcustommusic.net/json/search/?search=\(query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)") else {
            throw SCMError.httpRequestError
        }
        let json = JSON(data: http.1);
        guard let state = json["ok"].bool else {
            throw SCMError.jsonParseError;
        }
        if (!state){
            throw SCMError.objectNotFoundError;
        }
        guard let songs = json["songs"].array else {
            throw SCMError.otherApiError;
        }
        for song in songs {
            returnval.append(Song(
                    id: String(song["song_id"].int!), 
                    title: song["song_name"].string!, 
                    secLength: UInt(song["song_length"].string ?? "0")!, 
                    uploader: song["song_uploader"].string ?? "Unknown", 
                    canDownload: song["song_available"].int! == 1, 
                    downloadCount: UInt(song["song_downloads"].string ?? "0")!, 
                    gameId: String(song["song_game_id"].int!)));
        }
        return returnval;
    }
}


public enum SCMError: Error{
    case jsonParseError, httpRequestError, objectNotFoundError, otherApiError, serverFileError
}

