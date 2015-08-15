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

    # This method is called when an event reaches Fluentd.
    # 'es' is a Fluent::EventStream object that includes multiple events.
    # You can use 'es.each {|time,record| ... }' to retrieve events.
    # 'chain' is an object that manages transactions. Call 'chain.next' at
    # appropriate points and rollback if it raises an exception.
    #
    # NOTE! This method is called by Fluentd's main thread so you should not write slow routine here. It causes Fluentd's performance degression.
    def emit(tag, es, chain)
      es.each do |time,record|
        res = Eapi::post_api(["show directflow detail"], nil, @user, @password, nil,
                            nil, nil, true, nil, true, @host)

        Engine.emit("bro.intel.processed", time, res)
      end

      chain.next
    end

  end
end

