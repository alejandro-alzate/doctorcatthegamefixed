-- Sound system created by Ensayia and expanded by Taehl
TEsound = {}				-- Namespace
TEsound.channels = {}		-- This holds the currently playing sound channels
TEsound.volumeLevels = {}	-- Volume levels that multiply the volumes of sounds with those tags
TEsound.pitchLevels = {}	-- Pitch levels that multiply the pitches of sounds with those tags


-- Functions for playing sounds

-- Play a (potentially random) sound (with optional tag(s), volume, pitch, and on-finished function)
function TEsound.play(sound, tags, volume, pitch, func)
	if not sound or (type(sound) ~= "string" and type(sound) ~= "table") then return nil, "You must use a valid sound source (a string that's a filepath to a sound, or a list of them)."
	elseif type(sound) == "table" and #sound < 1 then return nil, "The list of sounds must have at least one filepath."
	end
	if type(sound) == "table" then sound = sound[math.random(#sound)] end

	--Fix: love.audio.newSource now requires to specify if the sound has to be cached
	--or streamed from storage, picked "static" since the sounds are quite small.
	table.insert(TEsound.channels, { love.audio.newSource(sound, "static"), func, {volume or 1, pitch or 1}, tags=(type(tags) == "table" and tags or {tags}) })
	local s = TEsound.channels[#TEsound.channels]
	s[1]:play()
	s[1]:setVolume( (volume or 1) * TEsound.findVolume(tags) * (TEsound.volumeLevels.all or 1) )
	s[1]:setPitch( (pitch or 1) * TEsound.findPitch(tags) * (TEsound.pitchLevels.all or 1) )
	return #TEsound.channels
end

-- Plays a (potentially random) sound which will repeat be repeated n times (if n isn't given, you must stop it manually with TEsound.stop)
function TEsound.playLooping(sound, tags, n, volume, pitch)
	return TEsound.play( sound, tags, volume, pitch,
		(not n or n > 1) and function(d) TEsound.playLooping(sound, tags, (n and n-1), d[1], d[2]) end
	)
end


-- Functions for modifying sounds that are playing (passing these a tag instead of a string is generally preferable)

-- Sets the volume of channel/tag and its loops (if any), or resets it if volume is omitted (try going TEsound.volume("music", .5))
function TEsound.volume(channel, volume)
	if type(channel) == "number" then
		local c = TEsound.channels[channel] volume = volume or c[3][1] c[3][1] = volume
		c[1]:setVolume( volume * TEsound.findVolume(c.tags) * (TEsound.volumeLevels.all or 1) )
	elseif type(channel) == "string" then TEsound.volumeLevels[channel]=volume for k,v in pairs(TEsound.findTag(channel)) do TEsound.volume(v, volume) end
	end
end

-- Sets the pitch of channel/tag and its loops (if any), or resets it if pitch is omitted
function TEsound.pitch(channel, pitch)
	if type(channel) == "number" then
		local c = TEsound.channels[channel] pitch = pitch or c[3][2] c[3][2] = pitch
		c[1]:setPitch( pitch * TEsound.findPitch(c.tags) * (TEsound.pitchLevels.all or 1) )
	elseif type(channel) == "string" then TEsound.pitchLevels[channel]=pitch for k,v in pairs(TEsound.findTag(channel)) do TEsound.pitch(v, pitch) end
	end
end

-- Pauses a channel/tag
function TEsound.pause(channel)
	if type(channel) == "number" then TEsound.channels[channel][1]:pause()
	elseif type(channel) == "string" then for k,v in pairs(TEsound.findTag(channel)) do TEsound.pause(v) end
	end
end

-- Resumes a channel/tag
function TEsound.resume(channel)
	if type(channel) == "number" then TEsound.channels[channel][1]:resume()
	elseif type(channel) == "string" then for k,v in pairs(TEsound.findTag(channel)) do TEsound.resume(v) end
	end
end

-- Stops a sound channel/tag either immediately or when finished, and prevents it from looping
function TEsound.stop(channel, finish)
	if type(channel) == "number" then local c = TEsound.channels[channel] c[2] = nil if not finish then c[1]:stop() end
	elseif type(channel) == "string" then for k,v in pairs(TEsound.findTag(channel)) do TEsound.stop(v, finish) end
	end
end


-- Utility functions

-- Cleans up finished sounds, freeing memory. Call frequently!
function TEsound.cleanup()
	for k,v in ipairs(TEsound.channels) do
		--Fix: isPaused was removed before v11.5
		--Replaced by functionally is the same alternative
		if v[1]:isPlaying() == false then
			if v[2] then v[2](v[3]) end		-- allow sounds to use custom functions (primarily for looping, but be creative!)
			table.remove(TEsound.channels, k)
		end
	end
end

-- Add or change a default volume level for a specified tag (for example, to change music volume, use TEsound.tagVolume("music", .5))
function TEsound.tagVolume(tag, volume)
	TEsound.volumeLevels[tag] = volume
	TEsound.volume(tag)
end

-- Add or change a default pitch level for a specified tag
function TEsound.tagPitch(tag, pitch)
	TEsound.pitchLevels[tag] = pitch
	TEsound.pitch(tag)
end


-- Internal functions

-- Returns a list of all sound channels with a given tag
function TEsound.findTag(tag)
	local t = {}
	for channel,sound in ipairs(TEsound.channels) do
		if sound.tags then for k,v in ipairs(sound.tags) do
			if tag == "all" or v == tag then table.insert(t, channel) end
		end end
	end
	return t
end

-- Returns a volume level for a given tag or tags
function TEsound.findVolume(tag)
	if type(tag) == "string" then return TEsound.volumeLevels[tag] or 1
	elseif type(tag) == "table" then for k,v in ipairs(tag) do if TEsound.volumeLevels[v] then return TEsound.volumeLevels[v] end end
	end
	return 1	-- if nothing is found, default to 1
end

-- Returns a pitch level for a given tag or tags
function TEsound.findPitch(tag)
	if type(tag) == "string" then return TEsound.pitchLevels[tag] or 1
	elseif type(tag) == "table" then for k,v in ipairs(tag) do if TEsound.pitchLevels[v] then return TEsound.pitchLevels[v] end end
	end
	return 1	-- if nothing is found, default to 1
end