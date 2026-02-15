# Checkpoint

Checkpoint is a library for reading from and writing to files in a Defold game engine project.

## Introduction

There are many libraries available that more or less perform these ubiquitous file-related operations. Checkpoint differentiates itself by focusing on an extremely simple API, and perhaps more importantly, its ability to work with directory hierarchies rather than bloating one directory with multiple unrelated files.

In order to work with the user's file system, Checkpoint depends on the [Lua File System](https://github.com/britzl/defold-lfs) library.

Each operating system has its own preferences for where applications should store data. Checkpoint prepends the following root save directories to any paths specified by the user:

| OS      | Path                                                     |
| ------- | -------------------------------------------------------- |
| Windows | C:\\Users\\\<user>\\AppData\\Roaming\\\<project_title>\\ |
| Linux   | /home/\<user>/.local/share/\<project_title>/             |

Checkpoint was only tested on the above platforms. Testing and contributions for other platforms are welcome and appreciated.

By default, data read from and written to files is interpretted in binary mode. Some file extensions are recognized as non-binary data, and will be interpretted accordingly:

| File Extension | Interpretation |
| -------------- | -------------- |
| .json          | JSON           |
| .*             | Binary         |

Note that some data formats only support a subset of structures. For example, writing Defold's `vmath.vector3()` to a binary file is valid, however writing it to a JSON file is not. When in doubt, break down structures into Lua primitives before writing to a file.

## Installation

Add Checkpoint as a dependency in your *game.project* file:  
https://github.com/klaleus/defold-checkpoint/archive/main.zip

Add Lua File System as a dependency in your *game.project* file:  
https://github.com/britzl/defold-lfs/archive/master.zip

Require *checkpoint.lua* in any script or module:  
`local checkpoint = require("checkpoint.checkpoint")`

## Minimal API Reference

```lua
-- Contains the project title from your game.project file.
checkpoint.project_title

-- Contains the path to your root save directory.
checkpoint.project_save_path

-- Reads data from a file.
local data, err = checkpoint.read(path)

-- Writes data to a file.
local success, err = checkpoint.write(path, data)

-- Checks if a file or directory exists.
local exists = checkpoint.exists(path)

-- Lists all files under the root save directory.
local paths = checkpoint.list()
```

## Comprehensive API Reference

### checkpoint.read(path)

Reads data from a file.

**Parameters**

* `path: string` Relative path from the root save directory.

**Returns**

* `boolean` Success or failure.
* `string` Error string.

**Example**

```lua
local path = "settings.json"
local data, err = checkpoint.read(path)
```

---

### checkpoint.write(path, data)

Writes data to a file.

If the file does not exist, then it will be created, along with its entire directory hierarchy.

**Parameters**

* `path: string` Relative path from the root save directory.
* `data: table`

**Returns**

* `boolean` Success or failure.
* `string` Error string.

**Example**

```lua
-- Writing a `vmath.vector3()` to a .bin file is valid,
-- since that file extension defaults to binary data.

local path = "profiles/klaleus/data.bin"
local data = { coordinates = vmath.vector3(7, 4, 7) }

local success, err = checkpoint.write(path, data)
```

```lua
-- Writing a `vmath.vector3()` to a .json file is invalid,
-- so we need to break it down into Lua primitives.

local path = "profiles/klaleus/data.json"
local data = { x = 7, y = 4, z = 7 }

local success, err = checkpoint.write(path, data)
```

---

### checkpoint.exists(path)

Checks if a file or directory exists.

**Parameters**

* `path: string` Relative path from the root save directory.

**Returns**

* `boolean`

**Example**

```lua
-- In this example, we want to read settings data from a JSON file on launch.
-- If the file exists, then the player has played the game before, and we should use whatever settings are in that file.
-- If the file does not exist, then the player has not played the game before, and we should use default settings instead.

local path = "settings.json"
local default_data = { fullscreen = true }

if checkpoint.exists(path) then
    local data, err = checkpoint.read(path)
    -- Configure game using `data` table.
else
    local success, err = checkpoint.write(path, default_data)
    -- Configure game using `default_data` table.
end
```

---

### checkpoint.list()

Lists all files under the root save directory.

**Returns**

* `table` Array of relative paths from the root save directory.

**Example**

```lua
-- In this example, the root save directory is populated as follows:
--
-- root_save_dir/
--     settings.json
--     profiles/
--         klaleus.json
--     levels/
--         level_1.bin
--
-- Calling `checkpoint.list()` returns the following table:
--
-- {
--     "settings.json",
--     "profiles/klaleus.json",
--     "levels/level_1.bin"
-- }

local paths = checkpoint.list()

for i = 1, #paths do
    local path = paths[i]
    local data, err = checkpoint.read(path)

    -- Do something with loaded data.
    -- For example, regex `path` based on file extension to load only level data.
end
```
