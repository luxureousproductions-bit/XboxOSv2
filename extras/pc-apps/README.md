# PC Apps for the App Drawer (Windows / Linux)

On a PC the App Drawer lists a Pegasus collection called **PC Apps**. These
two files are ready-made versions of it: `windows/` and `linux/`.

1. Copy the folder for your system somewhere Pegasus scans for games (or add
   it in Pegasus › Settings › Game directories).
2. Open `metadata.pegasus.txt`. Tools and Power entries are on already; the
   rest are switched off with `#`. Delete the `#` in front of an entry's lines
   to switch it on, and fix the path or command if yours differs.
3. Restart Pegasus. Press Select / Tab (or click Apps) to open the drawer.

The **genre** of each entry picks its tab: `Game`, `Emulator`, `Launcher`,
`App`, `Tool`. Entries with `Power` appear behind the drawer's Power tile.
In the drawer, Start (Menu key) on an entry can move it to another tab.

Add your own the same way:

```
game: My App
file: pcapps:my-app            (a placeholder: Pegasus needs one per entry)
genre: App
launch: cmd /c start "" "C:\Path\To\MyApp.exe"     (Windows)
launch: setsid -f myapp                            (Linux)
```

Each starter entry has an icon in the folder's `icons/` (copy the whole
folder, not just the text file). Give your own entries art the same way:
`assets.boxFront: icons/myapp.png`. Without art an entry shows its first
letter.
