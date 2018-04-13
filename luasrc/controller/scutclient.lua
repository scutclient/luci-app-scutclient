module("luci.controller.scutclient", package.seeall)

uci  = require "luci.model.uci".cursor()
http = require "luci.http"
fs = require "nixio.fs"
sys  = require "luci.sys"

log_file = "/tmp/scutclient.log"
log_file_backup = "/tmp/scutclient.log.backup.log"


function index()
	if not fs.access("/etc/config/scutclient") then
		return
	end
		entry({"admin", "scutclient"},
			alias("admin", "scutclient", "settings"),
			translate("华南理工大学客户端"),
			10  --tagforsed
		)

		entry({"admin", "scutclient", "settings"},
			cbi("scutclient/scutclient"),
			translate("设置"),
			10
		).leaf = true

		entry({"admin", "scutclient", "status"},
			call("action_status"),
			translate("状态"),
			20
		).leaf = true

		entry({"admin", "scutclient", "logs"},
			template("scutclient/logs"),
			translate("日志"),
			30
		).leaf = true

		entry({"admin", "scutclient", "about"},
			call("action_about"),
			translate("关于"),
			40
		).leaf = true

		-- 实时刷日志
		entry({"admin", "scutclient", "get_log"},
			call("get_log")
		)

		entry({"admin", "scutclient", "scutclient-log.tar"},
			call("get_dbgtar")
		)
end


function get_log()
	local send_log_lines = 75
	if fs.access(log_file) then
		client_log = sys.exec("tail -n "..send_log_lines.." " .. log_file)
	else
		client_log = "Unable to access the log file!"
	end

	http.prepare_content("text/plain; charset=gbk")
	http.write(client_log)
	http.close()
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


function get_dbgtar()

	local tar_dir = "/tmp/scutclient-log"
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
	}

	fs.mkdirr(tar_dir)
	table.foreach(tar_files, function(i, v)
			luci.sys.call("cp " .. v .. " " .. tar_dir)
	end)

	if fs.access(log_file_backup) then
		luci.sys.call("cat " .. log_file_backup .. " >> " .. tar_dir .. "/scutclient.log")
	end
	if fs.access(log_file) then
		luci.sys.call("cat " .. log_file .. " >> " .. tar_dir .. "/scutclient.log")
	end
	http.prepare_content("application/octet-stream")
	http.write(sys.exec("tar -C " .. tar_dir .. " -cf - ."))
	luci.sys.call("rm -rf " .. tar_dir)
	http.close()
end
