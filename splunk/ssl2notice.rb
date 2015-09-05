#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require "csv"
require "zlib"

require "eapier"


SWITCH_ADDR = '10.60.0.254'
MIRROR_INTF = "Ethernet51"

# SPLUNK_HOME = "/opt/splunk"
LOG_PATH = "/var/tmp/%s.log" % __FILE__

EAPI_USER = 'eapi'
EAPI_PASSWORD = 'password'

IS_SSL = false
EAPI_PORT = 80


def _create_df (recdicts, wfd)

  # def post_api(runcmds, filename_targets, user, passwd, is_https, port_dst,
  #              is_text, is_enable, is_conf, as_lib, *arglist)

  resp_eapi = Eapi::post_api(["show directflow detail"], nil, EAPI_USER, EAPI_PASSWORD, IS_SSL, EAPI_PORT,
                             nil, true, nil, true, SWITCH_ADDR)["result"]
  names_flow = resp_eapi[1]["flows"].map do |flow| flow["name"].split("-")[0].gsub(/_/, ".") end

  recdicts.each do |record|

    begin
      res = "[-] Error : Aborted."

      is_exist = names_flow.map do |name|
        record["id_orig_h"] == name
      end
      is_exist = is_exist.any?

      if is_exist
        res = "[-] Warning : Monitoring flows for %s already exist. Abort new creations." % record["id_orig_h"]

      else
        directions = ["in", "out"]
        for direction in directions
          flow_entry = "flow %s-%s-%s" % [record['id_orig_h'].gsub('.', '_'), record['uid'], direction]
          cmds = []
          precmds = ["directflow", flow_entry]

          if direction == "in"
            flowmtch = [
                "match source ip %s" % record['id_orig_h'] #,
            # "timeout hard %s" % FLOW_DURATION
            ]
          else
            flowmtch = [
                "match destination ip %s" % record['id_orig_h'] #,
            # "timeout hard %s" % FLOW_DURATION
            ]
          end
          flowact = ["action egress mirror %s" % MIRROR_INTF]
          cmds.push(*precmds, *flowmtch, *flowact)

          res = Eapi::post_api(cmds, nil, EAPI_USER, EAPI_PASSWORD, IS_SSL, EAPI_PORT,
                               nil, nil, true, true, SWITCH_ADDR)

        end
      end

    rescue
      wfd.puts res
    end

  end
end


if __FILE__ == $0

  File::open(LOG_PATH, "a") do |log_fd|
    log_fd.puts "[+] %s starts at %s" % [__FILE__, Time.now.to_s]

    tab_result = nil

    csv_result = ARGV[-1]
    Zlib::GzipReader.open(csv_result) do |gz|
      csv = CSV.new(gz.read, :headers=>true)
      tab_result = csv.read
    end

    if tab_result.nil?
      log_fd.puts "[-] Failed to read the result. Program exits."
      exit(1)
    end

    tab_result = tab_result.each.map do |rec|
      rec.to_hash
    end
    _create_df(tab_result, log_fd)

  end
end
