require 'fileutils'
module Nesta
  module Plugin
    module Admin
      module Helpers
        ########################################################################
        # Simple Authentication Helpers
        ########################################################################
        
        # throw [:halt] on failure
        def protected!
          unless authorized? 
            response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
            throw(:halt, [401, "Not authorized\n"])
          end
        end
       
        # Check [Rack::Auth::Basic::Requst] for valid username
        # and password against [Nesta::Config.username] and
        # [Nesta::Config.password] set in config/config.yml
        #
        # @return [Boolean] 
        def authorized?
          @auth ||= Rack::Auth::Basic::Request.new(request.env)
          @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == [Nesta::Config.username, Nesta::Config.password]
        end

        ########################################################################
        # View Helpers
        ########################################################################

        # Taken from Nesta helpers, as they weren't available in the 
        # Admin because it's a middleware.
        #
        # @return [String] clean path for linking
        def path_to(page_path, absolute = false) 
          host = ''
          if absolute
            host << "http#{'s' if request.ssl?}://"
            if (request.env.include?("HTTP_X_FORWARDED_HOST") or 
                request.port != (request.ssl? ? 443 : 80))
              host << request.host_with_port
            else
              host << request.host          
            end
          end
          uri_parts = [host]
          uri_parts << request.script_name.to_s if request.script_name
          uri_parts << page_path
          File.join(uri_parts)
        end

        # Taken from Nesta helpers, as they weren't available in the 
        # Admin because it's a middleware.
        #
        # @return [String] clean path for stylesheets
        def local_stylesheet_link_tag(name)
          pattern = File.expand_path("views/#{name}.s{a,c}ss", Nesta::App.root)
          if Dir.glob(pattern).size > 0
            haml_tag :link, :href => path_to("/css/#{name}.css"), :rel => "stylesheet"
          end
        end

        # Override standard haml call to include special view location for 
        # admin templates. I know, I know, this will break templating for admin
        # views, but it's a small price to pay.
        #
        # TODO: figure out a way to somehow inject these in to standard view path
        #
        # @return [String] rendered html from haml
        def admin_haml template, options={}
          haml template, { views: File.expand_path('../../views', File.dirname(__FILE__)), layout: :layout }.merge(options)
        end
      end

      ########################################################################
      # Core Modules
      ########################################################################

      # Write updates to disk:
      # - strip begining slash
      # - clean dirty chars
      # - create directory if missing
      #
      # @param path [String] path to file being written
      # @param params [String] params recieved by Sinatra from HTTP GET
      def self.write path, params
        path.gsub!(/^\//, '')
        path.gsub!(/[\`\!\$\%\^\&\*\(\)\+\=\[\]\{\}\|\:\;\'\"\?\,\<\>\\]/, "-")
        path = File.expand_path("#{path}.#{params["format"]}", File.join( Nesta::Env.root, Nesta::Config.page_path ))
        FileUtils.mkdir_p(File.dirname(path)) unless File.directory?(File.dirname(path)) 
        File.open(path, 'w') { |file| file.puts params["contents"] }
      end

      # Delete file from disk.
      #
      # @param path [String] path to file being deleted
      def self.delete path
        File.delete self.full_path(path).first
      end

      # Load file in raw form, existing Nesta load methods strip out metadata.
      #
      # @param path [String] path to file being loaded
      def self.load_raw path
        path, format = self.full_path(path)
        [File.open(path, 'r').read, format]
      end

      # Load menu.txt file.
      def self.load_menu
        File.open(self.menu_path, 'r').read
      end

      # Write menu.txt file.
      #
      # @param params [String] params recieved by Sinatra from HTTP GET
      def self.write_menu params
        File.open(self.menu_path, 'w') { |file| file.puts params["contents"] }
      end

      # Build menu.txt path.
      #
      # @param path [String] path to menu.txt
      def self.menu_path
        File.expand_path("menu.txt", File.join( Nesta::Env.root, Nesta::Config.content_path ))
      end

      # Full path to page, technically a helper but here for plugins that use
      # this plugin -- of which I may write.
      #
      # @param path [String] path to menu.txt
      def self.full_path path
        path.gsub!(/^\//, '')
        Nesta::FileModel::FORMATS.each do |format|
          [path, File.join(path, 'index')].each do |basename|
            filename = File.expand_path("#{basename}.#{format}", File.join( Nesta::Env.root, Nesta::Config.page_path ))
            if File.exist?(filename) 
              return [filename, format]
            end
          end
        end
        raise Sinatra::NotFound
      end

      # Expire all caches (both local and Sinatra::Cache).
      def self.expire_caches
        Nesta::Page.purge_cache
        if Nesta::Config.cache
          Nesta::Page.find_all.each do |page|
            Sinatra::Cache.cache_expire(page.abspath)
          end
        end
      end
    end
  end

  # Adding username and password to settings list.
  class Config
    @settings += %w[ username password ]
  end

  class AdminScreens < Sinatra::Base
    register Sinatra::Cache
    set :cache_enabled, false

    helpers Nesta::Plugin::Admin::Helpers

    before '/admin*' do
      protected!
      headers['Cache-Control'] = 'no-cache'
    end

    after '/admin*', :method => :post do
      Nesta::Plugin::Admin.expire_caches
    end

    after '/admin/*/delete' do
      Nesta::Plugin::Admin.expire_caches
    end

    get '/admin/new' do
      @action = "New Page"
      @path, @content = nil
      admin_haml :edit
    end

    post '/admin/new' do
      response['Cache-Control'] = 'no-cache'
      Nesta::Plugin::Admin.write(params["path"], params)
      redirect "/"+params["path"]
    end

    get '/admin/*/delete' do
      Nesta::Plugin::Admin.delete(File.join(params[:splat]))
      redirect '/admin'
    end

    get '/admin' do
      @action = "Pages"
      @pages = Nesta::Page.find_all.sort { |a,b| a.title_for_admin <=> b.title_for_admin }
      admin_haml :admin
    end

    get '/admin/menu' do
      @action   = "Edit Menu"
      @path      = "menu"
      @format   = nil
      @content  = Nesta::Plugin::Admin.load_menu
      admin_haml :edit
    end

    post '/admin/menu' do
      Nesta::Plugin::Admin.write_menu params
      redirect "/"
    end

    post '/admin/*' do
      path = File.join(params[:splat])
      Nesta::Plugin::Admin.write(path, params)
      redirect "/"+path
    end

    get '/admin/*' do
      @action  = "Edit Template"
      @path    = File.join(params[:splat])
      @content, @format = Nesta::Plugin::Admin.load_raw @path
      admin_haml :edit
    end

  end

  # Adding special handlers for admin page. These may be better
  # as helpers, but seemed to fix here within the context of 
  # the Page module.
  class Page
    attr_reader :format
    def title_for_admin
      t = self.title.gsub(" - #{Nesta::Config.title}","")
      return (t.empty? ? 'Home' : t)
    end
    def path_for_admin
      return (self.path.empty? ? 'index' : self.path)
    end
  end

  # Include helpers and use AdminScreens.
  class App
    helpers Nesta::Plugin::Admin::Helpers
    use AdminScreens
  end
end

