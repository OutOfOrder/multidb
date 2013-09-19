require 'rails'

module Multidb
  class Railtie < Rails::Railtie
    initializer 'multidb.active_record' do
      ActiveSupport.on_load :active_record do
        Multidb.install!
      end
    end
  end
end
