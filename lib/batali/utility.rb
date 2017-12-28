require 'batali'

module Batali
  class Utility < Grimoire::Utility

    # Helper module for enabling chef server support
    module Chef

      # Provide common required attribute
      def self.included(klass)
        klass.class_eval do
          attribute :client_name, String
          attribute :client_key, String
          attribute :endpoint, String
          attr_accessor :c_name
          attr_accessor :c_key
        end
      end

      # Load and configure chef
      def init_chef!
        debug 'Loading chef into the runtime'
        begin
          require 'chef'
          begin
            require 'chef/rest'
            @_api_klass = ::Chef::REST
          rescue LoadError
            # Newer versions of chef do not include REST
            require 'chef/server_api'
            @_api_klass = ::Chef::ServerAPI
          end
          debug 'Successfully loaded chef into the runtime'
        rescue LoadError => e
          debug "Failed to load the chef gem: #{e.class}: #{e}"
          raise 'The `chef` gem was not found. Please `gem install chef` or add `chef` to your bundle.'
        end
        Smash.new(
          :endpoint => :chef_server_url,
          :c_name => :node_name,
          :c_key => :client_key,
        ).each do |local_attr, config_key|
          unless self.send(local_attr)
            memoize(:knife_configure, :global) do
              require 'chef/knife'
              ::Chef::Knife.new.configure_chef
            end
            debug "Settting #{config_key} from knife configuration file for #{self.class} <#{endpoint}>"
            self.send("#{local_attr}=", ::Chef::Config[config_key])
          end
        end
        c_name ||= client_name
        c_key ||= client_key
      end

      # Make request to api service
      #
      # @yieldparam service [Chef::Rest]
      # @return [Object] result
      def api_service
        memoize(:api_service) do
          @_api_klass.new(
            endpoint,
            c_name,
            c_key
          )
        end
      end
    end
  end
end
