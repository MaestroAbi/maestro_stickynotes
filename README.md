# Maestro Sticky Notes for Fivem Qbox framework📝

A simple yet functional sticky note system for FiveM servers using the Qbox Framework. Allows players to place physical notes in the world, read them, and manage them through interactive markers and OX Target integration.

## Features ✨
- **Place Sticky Notes**
  Physically place notes on any surface with precise raycast positioning
- **Custom Headers & Content**
  Add both a header (title) and detailed content for each note
- **Persistent Storage**
  Notes save to MySQL database and persist through server restarts
- **Interactive Target System**
  Use OX Target to:
  - 📖 Read note contents with header
  - ✋ Pick up existing notes
- **Inventory Integration**
  Requires and consumes `stickynote` item from OX Inventory
- **Visual Feedback**
  Placement preview markers with adjustable size/color
- **Responsive UI**
  Clean interface using OX Lib dialogs and text UI

## Showcase
[Video](https://www.youtube.com/watch?v=u51k9p6jn9U)

## Dependencies
- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_target](https://github.com/overextended/ox_target)
- MySQL Database

### Steps
1. **Add to Resources**  
   Place `maestro_stickynotes` in your `resources` directory

2. **Database Setup**  
   Run this SQL query in your database:
   ```sql
   CREATE TABLE IF NOT EXISTS `player_stickynotes` (
     `id` VARCHAR(36) PRIMARY KEY,
     `coords` TEXT NOT NULL,
     `header` VARCHAR(50) NOT NULL,
     `text` TEXT NOT NULL
   );

3. Configure Inventory Item
   Add to `ox_inventory/data/items.lua` or replace existing `stickynote`:
   ```
   ['stickynote'] = {
        label = 'Sticky Note',
        weight = 100,
        stack = true,
        consume = 0,
        client = {
            usable = true, -- Required for any item interaction
            image = 'stickynote.png', -- Optional but recommended
            export = 'maestro_stickynotes.useItem' -- Must match client export
        }
    },
4. Start resource
   Add this to your server.cfg:
   ```
   ensure qbx_stickynotes
5. Restart Server
   Fully restart your FiveM server to initialize the system
