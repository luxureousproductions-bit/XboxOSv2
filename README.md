# XboxOSv2 (a fork of a fork of gameOS)

![gameOS Pegasus theme 1](https://i.imgur.com/Cb31gtf.png)
![gameOS Pegasus theme 2](https://i.imgur.com/19DZEJ1.jpg)
![gameOS Pegasus theme 3](https://i.imgur.com/x5ATDSx.png)
![gameOS Pegasus theme 4](https://i.imgur.com/KLz2mUE.png)
![gameOS Pegasus theme 5](https://i.imgur.com/pRa3o3I.png)
![gameOS Pegasus theme 6](https://news.xbox.com/en-us/wp-content/uploads/sites/2/2020/08/Xbox-Visual-Refesh-Style-Guide.jpg?w=1200)

## XboxOsv2 theme for Pegasus Frontend

IMPORTANT: This is a fork of [gameOS](https://github.com/PlayingKarrde/gameOS/releases/latest) by the original and true UI God: Seth Powell. This theme further continues work from the XboxOS fork and now modernizes and refines the experience even more. The goal is to create a modern game launcher UI with quality-of-life improvements and additional media support.

## Installation

[Download the latest version](https://github.com/alfredolvera/XboxOS/releases/latest) and extract it in your [Pegasus theme directory](http://pegasus-frontend.org/docs/user-guide/installing-themes/).

Windows users may need to install the [K-lite Codec Pack](https://www.codecguide.com/download_kl.htm) to get video playback working.

IMPORTANT: You need to have the latest version of Pegasus installed (not the current Stable release) otherwise you will get an error regarding Qt.Modules.

## Metadata

It is recommended to use [Skraper.net](http://www.skraper.net/) to acquire media assets for this theme. These are the minimum requirements for media scraping, although adding more could be useful for greater visual variety:

- video
- screenshot
- fanart
- box2d (front cover)
- box2dback (back cover)
- box3d (3D cover)
- wheel
- miximage
- cartridge
- titlescreen (title screen image)

Skraper will place these in your roms folder under a subfolder called media.

If no media files are showing up, make sure that Skraper Assets is checked in the Additional Data Sources section of Pegasus settings. It may also be preferable to convert the created gamelist.xml to Pegasus format for full compatibility.


## Version history

### v1.0 (2026-04-10) – Initial release of XboxOSv2

XboxOsv2 begins with major improvements over prior forks, including:

- Verified and improved art asset priority logic in the showcase view
- Preserves original genre casing and displays a genre
- added a top by developer list and genre2 list
- Adds support for box art (front/back/3D/mixed), cartridge, and new titlescreen media to game details and showcase views
- Improves asset fallback chains (for box art, wheel, 2D assets) for robust display
- Adds a sixth configurable showcase collection to the home screen
- Fixes media asset key mismatch issues (e.g., screenshottitle → titlescreen, support → cartridge)
- Numerous crash fixes, label and art improvements, and better media carousel support
- See individual PRs for historical technical changes:
  [#1](https://github.com/luxureousproductions-bit/XboxOSv2/pull/1), [#2](https://github.com/luxureousproductions-bit/XboxOSv2/pull/2), [#3](https://github.com/luxureousproductions-bit/XboxOSv2/pull/3), [#4](https://github.com/luxureousproductions-bit/XboxOSv2/pull/4), [#5](https://github.com/luxureousproductions-bit/XboxOSv2/pull/5), [#6](https://github.com/luxureousproductions-bit/XboxOSv2/pull/6), [#7](https://github.com/luxureousproductions-bit/XboxOSv2/pull/7), [#8](https://github.com/luxureousproductions-bit/XboxOSv2/pull/8), [#9](https://github.com/luxureousproductions-bit/XboxOSv2/pull/9), [#10](https://github.com/luxureousproductions-bit/XboxOSv2/pull/10), [#11](https://github.com/luxureousproductions-bit/XboxOSv2/pull/11), [#12](https://github.com/luxureousproductions-bit/XboxOSv2/pull/12), [#13](https://github.com/luxureousproductions-bit/XboxOSv2/pull/13), [#14](https://github.com/luxureousproductions-bit/XboxOSv2/pull/14), [#15](https://github.com/luxureousproductions-bit/XboxOSv2/pull/15).
