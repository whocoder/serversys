# Server-Sys
**In development, install and use at your own risk. There is no guarantee that all features will work. However, feel free to test the plugins.**

[![Build Status](https://travis-ci.org/whocodes/serversys.svg?branch=master)](https://travis-ci.org/whocodes/serversys)

## Description
SourceMod Server-Sys is a simple, yet advanced server configuration system. For those core functionality features that you're inevitable to add anyways, this covers those in an optimized neat fashion, with advanced configuration ability.

| Highly Configurable [![Thumbnail](http://whocodes.pw/ss/2015-07-02_23-33-40-thumbnail.jpg)](http://whocodes.pw/ss/2015-07-02_23-33-40.png) | Module Support [![Thumbnail](http://whocodes.pw/ss/2015-07-02_23-55-43.png)](http://whocodes.pw/ss/2015-07-02_23-52-14.png) |
|:------------------------------------------------------------------------------------------------------------------------------------------:|:---------------------------------------------------------------------------------------------------------------------------:|

## Compatibility
* Counter-Strike: Source
* Counter-Strike: Global Offensive
* Team Fortress 2
* Any other SourceMod compatible game (certain features may be unavailable, like respawning)

## Supported Modules
* [Ads](#) - Advertisements from SQL, featuring ability for users to toggle their display (!ads or /ads)
* [Reports](https://github.com/whocodes/serversys-reports) - Auto-demo recording, all demos saved to SQL and uploaded to FTP. Support for player vs player reports (!report or /report) which are linked to the recording.

We expect this library of modules to expand soon.

## Requirements
* [SourceMod](https://github.com/alliedmodders/sourcemod) 1.7+ by @alliedmodders (visit [alliedmods.net](http://alliedmods.net))
* [SMLib](http://github.com/bcserv/smlib/) by @bcserv
* An SQL server (we do not intend to support SQLite)

## Installation
Visit the [Getting Started](https://github.com/whocodes/serversys/wiki/Getting-Started) page in the Wiki for a tutorial on installation.

## Features
* [x] Map-specific configuration integration
* [x] Multiple settings required for many custom modes
* [x] Server ID, Player ID and Map ID registration to centralize data
* [x] Tracks players and maps play-time for individual servers and overall
* [x] Custom chat trigger support with simple alias support
* [x] 100% translation based in-game messages
* [ ] Web configuration/management module/application (PHP based option + possible node/io.js based option)
* [ ] Game-mode modules (possible modes include timer-based modes, jailbreak, TTT and others)
* [ ] Bans + Admins modules to replace SourceBans


## Contributing
If you have any ideas for new features, leaving a suggestion somewhere is always an option. However, if you're serious about contributing code or knowledge, have a look at [`CONTRIBUTING.md`](https://github.com/whocodes/serversys/blob/master/CONTRIBUTING.md).
