--------------------------------------------------------------------------------
-- License
--------------------------------------------------------------------------------

-- Copyright (c) 2025 Klaleus
--
-- This software is provided "as-is", without any express or implied warranty.
-- In no event will the authors be held liable for any damages arising from the use of this software.
--
-- Permission is granted to anyone to use this software for any purpose, including commercial applications,
-- and to alter it and redistribute it freely, subject to the following restrictions:
--
--     1. The origin of this software must not be misrepresented; you must not claim that you wrote the original software.
--        If you use this software in a product, an acknowledgment in the product documentation would be appreciated but is not required.
--
--     2. Altered source versions must be plainly marked as such, and must not be misrepresented as being the original software.
--
--     3. This notice may not be removed or altered from any source distribution.

--------------------------------------------------------------------------------

-- GitHub: https://github.com/klaleus/defold-checkpoint

--------------------------------------------------------------------------------

local _checkpoint_module = {}

_checkpoint_module.project_title = sys.get_config_string("project.title")
local _project_title = _checkpoint_module.project_title

-- Example: /home/klaleus/.local/share/defold-checkpoint/
_checkpoint_module.project_save_path = sys.get_save_file(_project_title, "")
local _project_save_path = _checkpoint_module.project_save_path

function _checkpoint_module.read(path)
	local absolute_path = sys.get_save_file(_project_title, path)

	-- Handle JSON files.
	if string.match(path, "%.json$") then
		local file, err = io.open(absolute_path, "r")
		if not file then
			return false, err
		end

		local text = file.read(file, "*a")
		file.close(file)
		if not text then
			-- Unfortunately `file.read()` doesn't return an error string.
			return false, absolute_path .. ": Failed to read file"
		end

		local success, data = pcall(json.decode, text)
		if not success then
			return false, data
		end

		return data

	-- Handle binary files, which is the default case.
	else
		-- Check if the file exists manually.
		-- Otherwise, `sys.load()` returns an empty table instead of an error string.
		if not _checkpoint_module.exists(path) then
			return false, absolute_path .. ": No such file or directory"
		end

		local success, data = pcall(sys.load, absolute_path)
		if not success then
			return false, data
		end

		return data
	end
end

-- Example: /home/klaleus/.local/share/defold-checkpoint/dir_1/dir_2/file.txt
--          Create directories: dir_1, dir_2
local function create_directories(path)
	-- Split the path into its components to determine which directories need to be created.
	local path_builder = _project_save_path

	local component_start_index = 1
	local component_end_index = string.find(path, "/")

	-- If an upcoming separator exists, then the current component is a directory.
	-- Otherwise, the it's just the file name, which we don't need.
	while component_end_index do
		local directory_name = string.sub(path, component_start_index, component_end_index - 1)
		path_builder = path_builder .. directory_name .. "/"

		-- Create the directory if it doesn't exist.
		local attributes = lfs.attributes(path_builder)
		if not attributes then
			local success, err = lfs.mkdir(path_builder)
			if not success then
				return false, err
			end
		end

		component_start_index = component_end_index + 1
		component_end_index = string.find(path, "/", component_start_index)
	end

	return true
end

function _checkpoint_module.write(path, data)
	local success, err = create_directories(path)
	if not success then
		return false, err
	end

	-- At this point, the directory hierarchy should exist.
	-- If the file itself doesn't exist, then `io.open()` will create it.
	local absolute_path = sys.get_save_file(_project_title, path)
	local file, err = io.open(absolute_path, "w")
	if not file then
		return false, err
	end

	-- Handle JSON files.
	if string.match(path, "%.json$") then
		local success, text = pcall(json.encode, data)
		if not success then
			file.close(file)
			return false, text
		end

		local success, err = file.write(file, text)
		if not success then
			file.close(file)
			return false, err
		end

		-- Save the file immediately, otherwise reading from it might return outdated data
		-- if the OS decides to delay flushing it.
		file.flush(file)
		file.close(file)

	-- Handle binary files, which is the default case.
	else
		local success, err = pcall(sys.save, absolute_path, data)
		if not success then
			return false, err
		end
	end

	return true
end

function _checkpoint_module.exists(path)
	local absolute_path = sys.get_save_file(_project_title, path)
	return lfs.attributes(absolute_path) and true or false
end

function _checkpoint_module.list()
	-- Strategy is to perform breadth-first search starting from the root save directory.
	-- Files should added to a results table, whereas directories should be added to a search table.
	local file_paths = {}
	local directory_paths = { "" }

	-- All directories have been visited and searched once the search table is empty.
	while #directory_paths > 0 do
		local directory_path = directory_paths[1]

		-- Breadth-first search the current directory.
		for component in lfs.dir(_project_save_path .. directory_path) do
			if component ~= "." and component ~= ".." then
				local absolute_path = _project_save_path .. directory_path .. component

				local mode = lfs.attributes(absolute_path, "mode")
				if mode == "file" then
					-- Return paths relative to the root save directory because they are compatible checkpoint's public interface.
					file_paths[#file_paths + 1] = directory_path .. component
				elseif mode == "directory" then
					directory_paths[#directory_paths + 1] = directory_path .. component .. "/"
				end
			end
		end

		-- Current directory has been searched.
		table.remove(directory_paths, 1)
	end

	return file_paths
end

return _checkpoint_module