# XboxOSv2 (a fork of a fork of gameOS)
<img width="1920" height="1080" alt="Screenshot_20260607-104924" src="https://github.com/user-attachments/assets/c05192cc-8d24-41a6-b384-990ed581ad0b" />

 - A complete overhaul to the showcase

<img width="1920" height="1080" alt="Screenshot_20260607-105125" src="https://github.com/user-attachments/assets/00c91574-67bc-4945-bd20-284f68ddf507" />
<img width="1920" height="1080" alt="Screenshot_20260607-105012" src="https://github.com/user-attachments/assets/f5ba37a4-3a25-4c1e-8bd0-170d11568f3e" />

- Crossfade background art, or use your own custom background:
    - Place Background.png to assests/images/backgrounds
  
<img width="1920" height="1080" alt="Screenshot_20260607-105541" src="https://github.com/user-attachments/assets/6aaac017-1e3e-4a6a-b012-5f011e6a010e" />
<img width="1920" height="1080" alt="Screenshot_20260607-105234" src="https://github.com/user-attachments/assets/d09b55c9-39bc-43c4-a8b8-3d50c453311a" />
- New Full Library section with advance filters
<img width="1920" height="1080" alt="Screenshot_20260607-105335" src="https://github.com/user-attachments/assets/8b552c4d-df91-433a-8d7f-f281d3843eb5" />
- Updated RA page
<img width="1920" height="1080" alt="Screenshot_20260607-105247" src="https://github.com/user-attachments/assets/a515aed5-e992-4cf3-8e4a-0168b5a9e13a" />
- New settings and ui
<img width="1920" height="1080" alt="Screenshot_20260607-105428" src="https://github.com/user-attachments/assets/74a4465d-a825-4be8-959a-d2e01ac53583" />
- Discover classics and hidden gems and jump right in with the Discover page






    







## XboxOsv2 theme for Pegasus Frontend

IMPORTANT: This is a fork of [gameOS](https://github.com/PlayingKarrde/gameOS/releases/latest) by the original and true UI God: Seth Powell. This theme further continues work from the XboxOS fork and now modernizes and refines the experience even more. The goal is to create a modern game launcher UI with quality-of-life improvements and additional media support.

- Ideas and inspirations from of course the original gameOS and XboxOs by Seth Powell and Alfred Olvera respectively, Yan Miller Sleipnir theme, and MrJud AquaFlow. I am not a developer nor will ever pretend to be, this started as a tinkering project to make changes I wanted to see to a big project I thought others may also enjoy so I’m here sharing my end result here.

## Installation

download latest release and extract it in your [Pegasus theme directory](http://pegasus-frontend.org/docs/user-guide/installing-themes/).


## Metadata

It is recommended to use [Skraper.net](http://www.skraper.net/) to acquire media assets for this theme. These are the minimum requirements for media scraping, although adding more could be useful for greater visual variety: 

- Folder Names (Label)
- videos (Video)
- screenshot (Screenshot)
- fanart (Fan Art)
- box2dfront (Box Art)
- box2dback (Back Box)
- box3d (3d Box)
- wheel (Logo)
- support (Cartridge)
- screenshottitle (Title Screen)
- steamgrid (Miximage)




## Whats Changed from XboxOs V1
  

- Added Publisher/Developer/Release to game details✅

- Added additional media to carousel:

   - video✅
  
   - screenshot✅
  
   - Fanart✅
  
   - Box2dfront (Box Art)✅
  
   - Box2dback (Back Box)✅
  
   - box3d (3D Box)✅
  
   - Wheel (Logo)✅
  
   - support(cartridge)✅
  
   - screenshottitle (Title Screen)✅
  
   - steamgrid (miximage)✅
   

- Added media carousel display options ✅
 
- Added Box Art display options :

    - 2D✅
    
    - 3D✅
    
    - Miximage ✅

    

- Added Top by genre 2, and Top by Developer list generators for showcase✅

- Added 6th showcase collection✅

- Added showcase options for fanart/screenshot✅

- Implemented a refresh feature for showcase✅
 (showcase doesnt auto refresh when navigating away and coming back, only when hitting refresh)

- Updated the "More" Lists in game details to include Publisher & Developer or fallback to "More Recommended" when only one title is available for each✅

- Added Advance options to enable/disable omission of Applications and Emulators from populating on showcase list✅ (Needs to have genre: Application or genre: Emulator)

 - Added an option in gamesdetail section "more by genre display" (genre: genre / subgenre in metadata)
   - option main= displays more by main genre
   - subgenre= displays more by subgenre
   - full= shows more by full genre / subgenre
   - Works with variations:
     - "genre/subgenre"
     - "genre / subgenre"
     - "genre/ subgenre"
     - "genre /subgenre"
     - "genre,subgenre"
     - "genre , subgenre"
     - "genre, subgenre"
     - "genre ,subgenre"
