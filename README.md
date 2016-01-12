# Server-Sys
**In development, (although functional) install and use at your own risk. There is no guarantee that all features will work.**

Server-Sys is built with large communities and multiple server management in mind.

[![Build Status](https://travis-ci.org/whocodes/serversys.svg?branch=master)](https://travis-ci.org/whocodes/serversys)

## Description
SourceMod Server-Sys is a simple, yet advanced server configuration system. For those core functionality features that you're inevitable to add anyways, this covers those in an optimized neat fashion, with advanced configuration ability.

## Compatibility
* Counter-Strike: Global Offensive
* Counter-Strike: Source
* Team Fortress 2
* Any SourceMod game*

** Denotes that some features may not be available. There should be notes regarding the availability in the configuration files.

## Supported Modules
* [Ads](https://github.com/whocodes/serversys-ads) - Advertisements from SQL, featuring ability for users to toggle their display (!ads or /ads) - Currently you have to insert rows into table manually.
* [Demos & Reports](https://github.com/whocodes/serversys-demos) - Auto-demo recording, all demos saved to SQL and uploaded to FTP. Support for player vs player reports (!report or /report) which are linked to the recording for later review.
* [UMsgHack](https://github.com/whocodes/serversys-umsghack) - Filter certain chat usermessages from being sent to clients (chat clean-up).
* [Chat Colors](https://github.com/whocodes/serversys-chatcolors) - Let players with a certain flag assign themselves custom name/message colors, plus format a totally custom tag with unlimited colors!

Expect this library of modules to expand soon (especially after the release of Server-Sys Web).

## Requirements
* [SourceMod](https://github.com/alliedmodders/sourcemod) 1.7+ by @alliedmodders (visit [alliedmods.net](http://alliedmods.net))
* [SMLib](http://github.com/bcserv/smlib/) by @bcserv
* An SQL server (we do not intend to support SQLite)

## Installation
Visit the [Getting Started](https://github.com/whocodes/serversys/wiki/Getting-Started) page in the Wiki for a tutorial on installation.

## Builds
To view the latest successful build outputs, check out [whocodes.pw/projects](https://whocodes.pw/projects). This is where all automatic builds are uploaded to. The zipped archives should contain everything required to run a plugin.

## Features
* Wraps SQL_Query, SQL_TQuery, SQL_EscapeString and SQL_ExecuteTransaction without requirement for database handle.
* Tons of natives and forwards for complete integration to create an altogether experience between plugins.
* Exposes Server ID, Player ID, and Map ID registration with forwards and natives for retrieval.
* Multiple settings that are often required for many types of game-play (in one central folder).
* Made with reliability, multi-server support, and performance in mind.
* All database operations used in default modules are threaded.
* 100% translation-based in-game text display.
* (WIP) Web Module with Admin CP & player statistical information.
* (WIP) Bans + Admins modules to replace SourceBans.
* (WIP) Analytics module to track in depth information about players.


## Contributing
If you have any ideas for new features, leaving a suggestion somewhere is always an option. However, if you're serious about contributing code or knowledge, have a look at [`CONTRIBUTING.md`](https://github.com/whocodes/serversys/blob/master/CONTRIBUTING.md).
