# roblox-service-collection
this repository is just a personal collection of some "services" for Roblox's programming language, intended to be plugged into virtually any Roblox project  

the term "service" here is kind of a loose term, as it can mean frameworks, engines, etc. here it usually just refers to a style of singleton modulescripts  
feel free to use any of the scripts here, and if you think you can contribute some improvements to any existing service, don't be afraid to put in a pull request!  

## current services/modules
| Service Name     | Description                                                                              | Associated Files |
|------------------|------------------------------------------------------------------------------------------|------------------|
| Networker        | Networking for client and server communication. Abstracts remote events into an easy API, has rate limiting, instance name obfuscation, and more. Read comment headers in files for more info | `src/ReplicatedStorage/Shared/Services/NetworkerService`, `src/ServerScriptService/Services/NetworkerService` |
| Asset Preloader  | Preloads assets from directories within the game - including subdirectories | `src/ServerScriptService/Services/AssetPreloaderServiceServer.lua` |


PS: hopefully all of these services contain a header comment in their files which explains what they do and an example use case; before using one of these, you should probably read it's header comment. additionally, if it's needed, a text file will accompany the service in either server or client folder that explains further steps for adding it to a game  
PS PS: in the repo there is also two scripts that initialize all the services - if you are adding all of these services to your game, or need to know how to initialize them, then it's worth a look
