import os, random, sys
from PIL import Image, ImageDraw
random.seed(7)
T=sys.argv[1]; THEME=sys.argv[2]
logos={os.path.splitext(f)[0] for f in os.listdir(os.path.join(THEME,'assets/images/logospng'))}
systems=[("snes","Super Nintendo"),("nes","Nintendo Entertainment System"),("genesis","Sega Genesis"),("psx","PlayStation"),("ps2","PlayStation 2"),("n64","Nintendo 64"),("gba","Game Boy Advance"),("gb","Game Boy"),("gbc","Game Boy Color"),("nds","Nintendo DS"),("psp","PlayStation Portable"),("gc","GameCube"),("wii","Wii"),("dreamcast","Dreamcast"),("saturn","Sega Saturn"),("arcade","Arcade"),("mastersystem","Master System"),("gamegear","Game Gear"),("pcengine","PC Engine"),("neogeo","Neo Geo"),("atari2600","Atari 2600"),("3ds","Nintendo 3DS"),("switch","Nintendo Switch"),("xbox","Xbox")]
systems=[s for s in systems if s[0] in logos]
words="Super Mega Dragon Star Battle Racing Quest Legend Shadow Night Blade Storm Fighter Ninja Space Hyper Turbo Galaxy Dungeon Kingdom Robo Mystic Thunder Crystal Final Iron Neon Pixel Retro Turbo Hero Rogue Castle Rally Soccer Golf Tennis Puzzle Island Jungle Ocean Sky Fire Ice".split()
total=int(sys.argv[3]); per=total//len(systems)
def img(path,size,seed,label):
    r=random.Random(seed); im=Image.new('RGB',size,(r.randrange(30,200),r.randrange(30,200),r.randrange(30,200)))
    d=ImageDraw.Draw(im)
    for _ in range(6):
        x0,y0=r.randrange(size[0]),r.randrange(size[1]); d.ellipse([x0,y0,x0+r.randrange(40,200),y0+r.randrange(40,200)],fill=(r.randrange(256),r.randrange(256),r.randrange(256)))
    d.rectangle([0,size[1]-40,size[0],size[1]],fill=(0,0,0)); d.text((8,size[1]-30),label,fill=(255,255,255))
    im.save(path,quality=80)
n=0
for sn,name in systems:
    sd=os.path.join(T,'lib',sn); os.makedirs(os.path.join(sd,'media'),exist_ok=True)
    lines=[f"collection: {name}",f"shortname: {sn}","extension: rom",""]
    for i in range(per):
        t=f"{random.choice(words)} {random.choice(words)} {random.randrange(1,100)}"
        base=f"g{n:05d}"; open(os.path.join(sd,base+".rom"),'w').close()
        img(os.path.join(sd,'media',base+'_box.jpg'),(360,480),n*3,t)
        img(os.path.join(sd,'media',base+'_ss.jpg'),(480,270),n*3+1,t)
        lines+= [f"game: {t}",f"file: {base}.rom",f"assets.boxfront: media/{base}_box.jpg",f"assets.screenshot: media/{base}_ss.jpg",f"assets.background: media/{base}_ss.jpg"]
        if n%3==0: lines.append(f"assets.video: {T}/media/preview.mp4")
        lines+= [f"genre: {random.choice(['Action','RPG','Sports','Puzzle','Racing','Platformer'])}",f"rating: {random.randrange(40,100)}%",f"release: {random.randrange(1985,2020)}",""]
        n+=1
    open(os.path.join(sd,'metadata.pegasus.txt'),'w').write("\n".join(lines))
print("systems",len(systems),"games",n)
