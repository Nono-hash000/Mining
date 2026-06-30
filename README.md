# Mining Game

A 2D retro mining game built with **Godot Engine 4**. Explore deep maps, mine various rock formations using weighted generation pools, collect dynamic ore resources, and manage items inside a clean, modular script-driven inventory UI system optimized for pixel-perfect display scales.

##Features

* **Dynamic Weighted Rock Generation**: Generates mineral veins across maps dynamically based on configurable structural rarity and target depth metrics.
* **Custom Resource System**: Rocks and Ores are completely managed via decoupled `.tres` data containers for rapid expansion and content addition.
* **Retro Canvas Scaling**: Configured for crisp, pixel-perfect **320×180 Viewport** rendering scaled cleanly up to a default 1280×720 display canvas.
* **Dynamic Grid Inventory**: Script-generated UI component handling automated layouts, stacking constraints up to 64 items, layout recalculations, and absolute pause-state priority execution.

##Controls

| Key Bind | Action | Description |
| --- | --- | --- |
| `W`, `A`, `S`, `D` / Arrows | **Movement** | Move the miner around the map. |
| `Space` / Left Click | **Mine** | Swing your pickaxe to deal damage to adjacent stones. |
| `I` | **Inventory** | Toggle the centered inventory grid visualization overlay. |

---

##Script Breakdown

### 1. Weighted Level Spawner (`level.gd`)

Uses a mathematical pool algorithm evaluating the depth constraints and rarity indices defined in resource models. It parses custom metadata tags matching `can_spawn_rocks` embedded within `TileMapLayer` canvas textures to populate minerals efficiently.

### 2. Layout Tracker (`inventory_ui.gd`)

Saves computing resources by decoupling node instances from editor asset setups. The entire viewport layout tree is dynamically instantiated through script calls, forcing layout bounds calculation parameters symmetrically outward from the exact viewport midpoint.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](https://www.google.com/search?q=LICENSE) file for complete asset and platform distribution rights details.
