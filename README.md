# SwiftyCM

A Swift library for interacting with [Smash Custom Music Archive](https://smashcustommusic.net/) API.
Compatible with Linux and macOS.

## Usage
This library can be imported into your project using SPM:
```swift
    .package(url:"https://github.com/FreeApp2014/SwiftyCM")
```
to your package.dependencies and `dependencies: ["SwiftyCM"]` in your main target.

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

The documentation for this project can be built using [jazzy](https://github.com/realm/jazzy). 
The pre-built documentation can be found in `docs/` or on the [Github Pages](https://freeapp2014.github.io/SwiftyCM)