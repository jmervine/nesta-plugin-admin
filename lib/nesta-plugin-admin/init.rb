module Nesta
  module Plugin
    module Admin
      module Helpers
        # If your plugin needs any helper methods, add them here...
      end
    end
  end

  class App
    helpers Nesta::Plugin::Admin::Helpers
  end
end
