module("luci.controller.scutclient", package.seeall)

local uci  = require "luci.model.uci".cursor()
local http = require "luci.http"
local fs = require "nixio.fs"
local sys  = require "luci.sys"

local log_file = "/tmp/scutclient.log"
local log_file_backup = "/tmp/scutclient.log.backup.log"


function index()
	if not nixio.fs.access("/etc/config/scutclient") then
		return
	end
		entry({"admin", "network", "scutclient"},
			alias("admin", "network", "scutclient", "settings"),
			translate("华南理工大学客户端"),
			99
		)

		entry({"admin", "network", "scutclient", "settings"},
			cbi("scutclient/scutclient"),
			translate("设置"),
			10
		).leaf = true

		entry({"admin", "network", "scutclient", "status"},
			call("action_status"),
			translate("状态"),
			20
		).leaf = true

		entry({"admin", "network", "scutclient", "logs"},
			call("action_logs"),
			translate("日志"),
			30
		).leaf = true

		entry({"admin", "network", "scutclient", "about"},
			call("action_about"),
			translate("关于"),
			40
		).leaf = true

		-- 实时刷日志
		entry({"admin", "network", "scutclient", "get_log"},
			call("get_log")
		)
end


function get_log()
	local send_log_lines = 60
	local client_log = {}
	if fs.access(log_file) then
		client_log.log = sys.exec("tail -n "..send_log_lines.." " .. log_file)
	else
		client_log.log = "+1s"
	end

	http.prepare_content("application/json")
	http.write_json(client_log)
end


function action_about()
	luci.template.render("scutclient/about")
end


function action_status()
	luci.template.render("scutclient/status")
	if luci.http.formvalue("logoff") == "1" then
		luci.sys.call("/etc/init.d/scutclient stop > /dev/null")
	end
	if luci.http.formvalue("redial") == "1" then
		luci.sys.call("/etc/init.d/scutclient stop > /dev/null")
		luci.sys.call("/etc/init.d/scutclient start > /dev/null")
	end
	if luci.http.formvalue("move_tag") == "1" then
		luci.sys.call("sed -i 's/10 *--tagforsed/90    -- change it to 10 to move it back/' /usr/lib/lua/luci/controller/scutclient.lua")
		luci.sys.call("rm -rf /tmp/luci-*")
	end
end


function action_logs()
	luci.sys.call("touch " .. log_file)
	luci.sys.call("touch " .. log_file_backup)
	local logfile = string.sub(luci.sys.exec("ls " .. log_file),1, -2) or ""
	local backuplogfile = string.sub(luci.sys.exec("ls " .. log_file_backup),1, -2) or ""
	local logs = nixio.fs.readfile(logfile) or ""
	local backuplogs = nixio.fs.readfile(backuplogfile) or ""
	local dirname = "/tmp/scutclient-log-"..os.date("%Y%m%d-%H%M%S")
	luci.template.render("scutclient/logs", {
		logs=logs,
		backuplogs=backuplogs,
		dirname=dirname,
		logfile=logfile
	})

	local tar_files = {
		"/etc/config/wireless",
		"/etc/config/network",
		"/etc/config/system",
		"/etc/config/scutclient",
		"/etc/openwrt_release",
		"/etc/crontabs/root",
		"/etc/config/dhcp",
		"/tmp/dhcp.leases",
		"/etc/rc.local",
		logfile,
		backuplogfile
	}

	luci.sys.call("rm /tmp/scutclient-log-*.tar")
	luci.sys.call("rm -rf /tmp/scutclient-log-*")
	luci.sys.call("rm /www/scutclient-log-*")

	local tar_dir = dirname
	nixio.fs.mkdirr(tar_dir)
	table.foreach(tar_files, function(i, v)
			luci.sys.call("cp "..v.." "..tar_dir)
	end)


	local short_dir = "./"..nixio.fs.basename(tar_dir)
	luci.sys.call("cd /tmp && tar -cvf "..short_dir..".tar "..short_dir.." > /dev/null")
	luci.sys.call("ln -sf "..tar_dir..".tar /www/"..nixio.fs.basename(tar_dir)..".tar")
end
