# XboxOSv2 (a fork of a fork of gameOS)
<img width="1920" height="1080" alt="Screenshot_20260412-124412" src="https://github.com/user-attachments/assets/591b52ab-6b1a-4ca4-ba8f-6a9f1ef5f051" />
<img width="1920" height="1080" alt="Screenshot_20260412-124438" src="https://github.com/user-attachments/assets/a38aa6a4-2410-4732-af4a-84df2a19502d" />
<img width="1920" height="1080" alt="Screenshot_20260412-124726" src="https://github.com/user-attachments/assets/b9b028ae-902a-4f1a-b345-f066cafd2014" />
<img width="1920" height="1080" alt="Screenshot_20260412-124755" src="https://github.com/user-attachments/assets/31a6e08c-ea96-4dce-bedd-70c5e63d9418" />


## XboxOsv2 theme for Pegasus Frontend

IMPORTANT: This is a fork of [gameOS](https://github.com/PlayingKarrde/gameOS/releases/latest) by the original and true UI God: Seth Powell. This theme further continues work from the XboxOS fork and now modernizes and refines the experience even more. The goal is to create a modern game launcher UI with quality-of-life improvements and additional media support.

## Installation

<img width="1920" height="1080" alt="Screenshot_20260412-124412" src="https://github.com/user-attachments/assets/57c1e45e-acaa-4902-ab72-10745b43fc66" />
download latest release and extract it in your [Pegasus theme directory](http://pegasus-frontend.org/docs/user-guide/installing-themes/).

Windows users may need to install the [K-lite Codec Pack](https://www.codecguide.com/download_kl.htm) to get video playback working.

IMPORTANT: You need to have the latest version of Pegasus installed (not the current Stable release) otherwise you will get an error regarding Qt.Modules.

## Metadata

It is recommended to use [Skraper.net](http://www.skraper.net/) to acquire media assets for this theme. These are the minimum requirements for media scraping, although adding more could be useful for greater visual variety:

- videos
- screenshot
- fanart
- box2dfront (front cover)
- box2dback (back cover)
- wheel (logo)
- support (cartridge)
- screenshottitle (title screen image)

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
  
