module Fluent

  class MonDfEapi < Output
    Fluent::Plugin.register_output("mon_df", self)

    config_param :host, :string, :default => nil
    config_param :if_mirror, :string, :default => nil
    config_param :port, :integer, :default => 80
    config_param :base_uri, :string, :default => nil
    config_param :ssl, :bool, :default => nil
    config_param :user, :string, :default => nil
    config_param :password, :string, :default => nil

    def initialize
      require "eapier"
    end

    def configure(conf)
      super

      unless @host
        raise ConfigError, "'host' parameter is required on file output"
      end
      unless @if_mirror
        raise ConfigError, "'if_mirror' parameter is required on file output"
      end
      unless @user
        raise ConfigError, "'user' parameter is required on file output"
      end
      unless @password
        raise ConfigError, "'password' parameter is required on file output"
      end

      # scheme = @ssl == true ? "https" : "http"
      # @base_uri = "#{scheme}://#{@host}:#{@port}/"

      # @host = conf["host"]
      # @port = conf["port"]
      # @user = conf["user"]
      # @password = conf["password"]

    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)

      resp_eapi = Eapi::post_api(["show directflow detail"], nil, @user, @password, nil, nil,
                                 nil, true, nil, true, @host)["result"]
      # def post_api(runcmds, filename_targets, user, passwd, is_https, port_dst,
      #              is_text, is_enable, is_conf, as_lib, *arglist)
      names_flow = resp_eapi[1]["flows"].map do |flow| flow["name"].split("-")[0].gsub(/_/, ".") end

      es.each do |time,record|
        is_exist = names_flow.map do |name|
          record["id.orig_h"] == name
        end
        is_exist = is_exist.any?

        if is_exist
          res = {"error" => "Monitoring flows for %s already exist. Abort new creations." % record["id.orig_h"]}

        else
          res = {"status_exec" => []}

          directions = ["in", "out"]
          for direction in directions
            flow_entry = "flow %s-%s-%s" % [record['id.orig_h'].gsub('.', '_'), record['uid'], direction]
            cmds = []
            precmds = ["directflow", flow_entry]

            if direction == "in"
              flowmtch = [
                  "match source ip %s" % record['id.orig_h']
              # "timeout hard %s" % FLOW_DURATION
              # "no persistent"
              ]
            else
              flowmtch = [
                  "match destination ip %s" % record['id.orig_h']
              # "timeout hard %s" % FLOW_DURATION
              # "no persistent"
              ]
            end
            flowact = ["action egress mirror %s" % @if_mirror]
            cmds.push(*precmds, *flowmtch, *flowact)

            res["status_exec"].push(
                resp_eapi = Eapi::post_api(cmds, nil, @user, @password, nil, nil,
                                       nil, nil, true, true, @host)
            )
          end
        end

        Engine.emit("bro.intel.processed", time, res)
      end

      chain.next
    end

  end
end

