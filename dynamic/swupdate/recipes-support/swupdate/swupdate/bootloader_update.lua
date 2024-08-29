require ("swupdate")

function os.capture(cmd)
        local f = assert(io.popen(cmd, 'r'))
        local s = assert(f:read('*a'))
        f:close()
        return s
end

function read_bootloader_version(boot_dev)
        local f = io.input(boot_dev)
        local s = f:read(0x1000000)
        f:close()
        return string.match(s, "U-Boot SPL %d+%.%d+%-(iris%-boot_%d+%.%d+%.%d+)%+%w+")
end

bootloader_handler = function(image)
	-- get emmc device number: mmcblkX
	local emmc_dev_no = os.capture("/usr/bin/lsblk -dno NAME | /bin/grep -m1 'boot0' | /bin/sed 's/boot0//' | /usr/bin/tr -d '\n'")
	if(emmc_dev_no ~= "mmcblk0" and emmc_dev_no ~= "mmcblk1" and emmc_dev_no ~= "mmcblk2") then
		swupdate.error("Can not read emmc dev number")
		return 1
	end
	local emmc_dev = "/dev/" .. emmc_dev_no -- /dev/mmcblkX

	-- get current boot partition number from emmc register
	-- 1=boot0, 2=boot1
	local extcsd = os.capture("/usr/bin/mmc extcsd read " .. emmc_dev)
	local current_part_no = string.match(extcsd, "Boot Partition (%d)")
	if(current_part_no ~= "1" and current_part_no ~= "2") then
		swupdate.error("Invalid boot partition not 1 nor 2!")
		return 1
	end
	local current_part_no_z = tostring(math.floor(current_part_no-1)) -- zero based
	local part_no = current_part_no == "1" and "2" or "1"
	local part_no_z = tostring(math.floor(part_no-1)) -- zero based
	local old_boot_dev = emmc_dev .. "boot" .. current_part_no_z -- /dev/mmcblkXbootY
	local new_boot_dev = emmc_dev .. "boot" .. part_no_z         -- /dev/mmcblkXbootY
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Start bootloader update")
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Current boot partition: " .. old_boot_dev)
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "New boot partition:     " .. new_boot_dev)

	if(image.install_if_higher) then
		local cur_version = read_bootloader_version(old_boot_dev)
		if(cur_version == nil or cur_version == '') then
			swupdate.error("Reading bootloader version failed")
			return 1
		end

		swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Current version: " .. cur_version)
		swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "New version:     " .. image.version)

		if(image.version <= cur_version) then
			swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Skip bootloader update, because " ..
				cur_version .. " is already installed")
			return 0
		end
	end

	-- create symlink
	os.capture("/bin/ln -sf " .. new_boot_dev .." /dev/swu_bootloader")

	-- image update
	swupdate.notify(swupdate.RECOVERY_STATUS.RUN, 0, "Install bootloader: " ..
		image.version  .. " on " .. new_boot_dev)
	local err, msg = swupdate.call_handler("raw", image)

	-- remove symlink
	os.capture("/bin/rm /dev/swu_bootloader")

	if err ~= 0 then
		swupdate.error(string.format("Error chaining handlers: %s", msg))
		return 1
	end

	-- toggle /dev/mmcblkXbootY
	os.capture("/usr/bin/mmc bootpart enable " .. part_no  .. " 0 " .. emmc_dev)

	-- also update current bootloader
	os.capture("/bin/echo 0 > /sys/block/" .. emmc_dev_no .. "boot" .. current_part_no_z .. "/force_ro")
	os.capture("/bin/dd if=" .. new_boot_dev .. " of=" .. old_boot_dev .. " &>/dev/null")
	os.capture("/bin/echo 1 > /sys/block/" .. emmc_dev_no .. "boot" .. current_part_no_z .. "/force_ro")

	swupdate.notify(swupdate.RECOVERY_STATUS.SUCCESS, 0, "Bootloader update successful")
	return 0
end

swupdate.register_handler("bootloader_update", bootloader_handler, swupdate.HANDLER_MASK.IMAGE_HANDLER)
