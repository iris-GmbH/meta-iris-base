require ("swupdate")

function os.capture(cmd)
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        return s
end

function read_bootloader_version(part_no_z)
        local f = io.input("/dev/mmcblk2boot" .. part_no_z)
        local s = f:read(0x1000000)
        f:close()
        return string.match(s, "U-Boot SPL %d+%.%d+%-(iris%-boot_%d+%.%d+%.%d+)%+%w+")
end

bootloader_handler = function(image)
	-- get current boot partition number from emmc register
	-- 1=boot0, 2=boot1
	local extcsd = os.capture('/usr/bin/mmc extcsd read /dev/mmcblk2')
	local current_part_no = string.match(extcsd, 'Boot Partition (%d)')
	if(current_part_no ~= "1" and current_part_no ~= "2") then
		swupdate.error("Invalid boot partition not 1 nor 2!")
		return 1
	end
	local current_part_no_z = tostring(math.floor(current_part_no-1)) -- zero based
	local part_no = current_part_no == "1" and "2" or "1"
	local part_no_z = tostring(math.floor(part_no-1)) -- zero based
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Start bootloader update")
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Current boot partition: /dev/mmcblk2boot" .. current_part_no_z)
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "New boot partition:     /dev/mmcblk2boot" .. part_no_z)

	if(image.install_if_higher) then
		local cur_version = read_bootloader_version(current_part_no_z)
		if(cur_version == nil or cur_version == '') then
			swupdate.error("Reading bootloader version failed")
			return 1
		end

		swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Current version: " .. cur_version)
		swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "New version:     " .. image.version)

		if(image.version <= cur_version) then
			swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Skip bootloader update " ..
				image.version  .. ", because " .. cur_version .. " is already installed")
			return 0
		end
	end

	-- create symlink
	os.capture("/bin/ln -sf /dev/mmcblk2boot" .. part_no_z .." /dev/swu_bootloader")

	-- image update
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Install bootloader: " ..
		image.version  .. " on /dev/mmcblk2boot" .. part_no_z)
	local err, msg = swupdate.call_handler("raw", image)

	-- remove symlink
	os.capture("/bin/rm /dev/swu_bootloader")

	if err ~= 0 then
		swupdate.error(string.format("Error chaining handlers: %s", msg))
		return 1
	end

	-- toggle /dev/mmcblk2bootX
	os.capture("/usr/bin/mmc bootpart enable " .. part_no  .. " 0 /dev/mmcblk2")

	-- also update current bootloader
	os.capture("/bin/echo 0 > /sys/block/mmcblk2boot" .. current_part_no_z .. "/force_ro")
	os.capture("/bin/dd if=/dev/mmcblk2boot" .. part_no_z .. " of=/dev/mmcblk2boot" .. current_part_no_z .. " &>/dev/null")
	os.capture("/bin/echo 1 > /sys/block/mmcblk2boot" .. current_part_no_z .. "/force_ro")

	swupdate.notify(swupdate.RECOVERY_STATUS.SUCCESS, 0, "Bootloader update successful")
	return 0
end

swupdate.register_handler("bootloader_update", bootloader_handler, swupdate.HANDLER_MASK.IMAGE_HANDLER)
