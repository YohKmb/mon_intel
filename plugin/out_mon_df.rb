module Fluent

  class SomeOutput < Output
    Fluent::Plugin.register_output("mon_df", self)

    config_param :host, :string, :default => nil
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
      unless @user
        raise ConfigError, "'user' parameter is required on file output"
      end
      unless @password
        raise ConfigError, "'password' parameter is required on file output"
      end

      # scheme = @ssl == true ? "https" : "http"
      # @base_uri = "#{scheme}://#{@host}:#{@port}/"

      @host = conf["host"]
      @port = conf["port"]
      @user = conf["user"]
      @password = conf["password"]

    end

    def start
      super
    end

    def shutdown
      super
    end

    def emit(tag, es, chain)
      es.each do |time,record|
        
        res = Eapi::post_api(["show directflow detail"], nil, @user, @password, nil,
                            nil, nil, true, nil, true, @host)["result"]
        names_flow = res[1]["flows"].map do |flow| flow["name"] end
        is_exist = names_flow.map do |name|
          record["id.orig_h"] == name.split("-")[0].gsub(/_/, ".")
        end
        is_exist = is_exist.any?

        Engine.emit("bro.intel.processed", time, res)
      end

      chain.next
    end

  end
end

