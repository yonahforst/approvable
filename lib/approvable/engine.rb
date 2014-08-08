require 'approvable/acts_as_approvable'
require 'state_machine'
require 'graphviz' # Optional: only required for graphing
require 'state_machine/version'

module Approvable
  class Engine < ::Rails::Engine
    isolate_namespace Approvable

    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end
    

    initializer :state_machine do |app|
     unless StateMachine::VERSION == '1.2.0'
       # If you see this message, please test removing this file
       # If it's still required, please bump up the version above
       Rails.logger.warn "Please remove me, StateMachine version has changed"
     end

     module StateMachine::Integrations::ActiveModel
       public :around_validation
     end
   end
    
    
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
    

  end
end
