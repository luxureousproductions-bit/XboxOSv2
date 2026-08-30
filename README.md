# XboxOSv2 (a fork of a fork of gameOS)



 - A complete overhaul to the showcase
   
<img width="1920" height="1080" alt="1000769042" src="https://github.com/user-attachments/assets/69d9e558-15bd-46af-bf64-8975ef7a8608" />
<img width="1920" height="1080" alt="1000769043" src="https://github.com/user-attachments/assets/b0f621c9-63c9-43e3-b05b-a7f514c1e593" />
<img width="1920" height="1080" alt="IMG_0693" src="https://github.com/user-attachments/assets/f661e9ad-abad-4708-8369-76f6ed3bd4a0" />
• Have all you system apps imported by enabling Pegasus data source

• For manual Apps it’s recommended to us shortname : Android collection name : Android to see you apps in the app drawer

• For Android games it’s recommended to use shortname : androidgames if you don’t want your manual imports in the app drawer
<img width="1920" height="1080" alt="1000769048" src="https://github.com/user-attachments/assets/9969e245-9211-47fb-9569-0219d07547e2" />
<img width="1920" height="1080" alt="1000769049" src="https://github.com/user-attachments/assets/d90b8805-cd6a-4995-b659-a34b083c0d2b" />


- Crossfade background art, or use your own custom background:
    - Place Background.png to assests/images/backgrounds
  
<img width="1920" height="1080" alt="1000769052" src="https://github.com/user-attachments/assets/670b3345-50e9-4312-93a3-7cbeca3d304a" />

<img width="1920" height="1080" alt="1000769053" src="https://github.com/user-attachments/assets/a8dab62b-bc7b-41a0-acb2-f708d1bfdd75" />

- New Full Library section with advance filters
  <img width="1920" height="1080" alt="1000769054" src="https://github.com/user-attachments/assets/e841d5e2-1afe-4f1d-9637-8496333637d7" />

<img width="1920" height="1080" alt="1000769056" src="https://github.com/user-attachments/assets/b8054f54-f3d6-47a1-9e18-4df74ec67e89" />
<img width="1920" height="1080" alt="1000769055" src="https://github.com/user-attachments/assets/1f43b6fc-37b3-470b-9d2c-cd0729f55628" />
<img width="1920" height="1080" alt="1000769058" src="https://github.com/user-attachments/assets/7dcf2d6d-ce19-4a8b-ac76-6516966e9d8a" />


- Updated RA page
  <img width="1920" height="1080" alt="1000769057" src="https://github.com/user-attachments/assets/3cccd40c-4d91-436d-b760-85654e27b336" />

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
