# Nesta::Plugin::Admin

### [Documentation](http://jmervine.github.com/nesta-plugin-admin/doc/)

An Admin interface for Nesta allowing currently allowing the following:

1. Create new pages.
2. Edit existing pages.
3. Delete pages.
4. Edit menu.txt.

TODO:
- Add config editor.
- Add plugin viewer.
- Add theme viewer and installer.
- Add server restart? Maybe? Probably not, but maybe?


## Installation

Add this line to your application's Gemfile:

    gem 'nesta-plugin-admin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install nesta-plugin-admin

## Usage

1. Add a username and password to your config/config.yml

        # file: config/config.yml
        username: foo
        password: bar

> WARNING: I wouldn't commit these to git!

2. Restart your application.

3. Visit: http://<yoursite>/admin

4. Login

5. Happy Admining.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
