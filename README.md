# SwiftyCM

A Swift library for interacting with [Smash Custom Music Archive](https://smashcustommusic.net/) API.
Compatible with Linux and macOS.

## Usage
This library can be imported into your project using SPM:
```swift
    .package(url:"https://github.com/FreeApp2014/SwiftyCM")
```
to your dependencies<br>
and `dependencies: ["SwiftyCM"]` in your main target.

## Example usage

The following code prints all songs from a game that match the criteria
```swift
import Foundation
import SwiftyCM
do {
    let game = try Game("4771");
    var neededSongs: [Song] = [];
    for song in game.songs {
        if(song.secLength < 40 && song.secLength > 10){
            neededSongs.append(try song.resolveSong());
        }
    }
    for song in neededSongs {
        print(song.id, song.title);
    }

} catch {
    fatalError("API error");
}
```
## Documentation

Structs: `Game`, `Song`<br>

### Game

The object that represents a game in SCM database<br>
**Initializer:** `Game(_ id: String)`;<br>
Properties: 
* id: String - the game id,
* title: String - the game name,
* songs: [PartialSongField] - the songs in the game.

#### PartialSongField

The limited subset of song information provided by the Game object<br>
**Methods:** `resolveSong()` - get the full Song object<br>
**Properties:** id: String, title: String, secLength: UInt, uploader: String, canDownload: Bool, downloadCount: UInt<br>
See *Song* for more information

### Song

The object that represents a song in SCM database<br>
**Initializer:** `Song(_ id: String)`;<br>
**Properties:** 
* id: String - song id,
* title: String - song title,
* uploader: String - the username of song uploader, 
* secLength: UInt- the audio length in seconds, 
* sampleRate: UInt - the sample rate of the audio, 
* loop: SongLoopInformation - information about looping, 
* canDownload: Bool - availability of the file on server, 
* downloadCount: UInt - download count, 
* game: PartialGameField - the game which the song belongs to

#### PartialGameField
A limited subset of game information containing the id and title. See *Game* for more information

#### SongLoopInformation
A struct containing information about looping:
* doesLoop: Bool - whether or not the file is loopable
* loopStart: UInt - looping start point
* loopTypeDesc: String - the loop type string 

## Thrown errors
jsonParseError, httpRequestError, objectNotFoundError, otherApiError, nestedError
