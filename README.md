# RayyanFormats

Rayyan core plugin for import/export of reference file formats. It comes with wrapped text and CSV plugins. Similarly, more formats can be supported and enabled via the client program. Usually, reference files contain articles with common attributes like `title`, `journal`, `publication date`, `authors`, ... etc. However, these attributes are represented in different ways within different formats. The main goal of this core plugin is to abstract the syntactical and semantic extraction of these attributes. 

## Installation

Add this line to your application's Gemfile:

    gem 'rayyan-formats-core'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rayyan-formats-core

## Usage

Without any additional plugins, this core plugin adds support for CSV format with `.csv` extension or CSV format wrapped in a text file with `.txt` extension.

To configure the plugin with additional formats, check the documentation for the [rayyan-formats-plugins](https://github.com/rayyanqcri/rayyan-formats-plugins) gem. Typically, in Rails, all configuration should go into a separate initializer (e.g. `config/initializers/rayyan-formats.rb`.

By default, the plugin will only process files no bigger than 10 megabytes. To override this limit, use the following configuration parameter:

    # support files up to 100 megabytes of size
    RayyanFormats::Base.max_file_size = 104_857_600

To do the actual importing of reference files:

    source = RayyanFormats::Source.new("example.csv")
    RayyanFormats::Base.import(source) { |target, total, is_new|
      # post processing for target
      puts "Found target: #{target}. Total: #{total}. is_new: #{is_new}"
    }

Note that `RayyanFormats::Source` is a proxy class. You can supply any class instance that responds to the following:
`:name` and `:attachment`. `:name` should return the file name string ending with a proper supported extension.
`:attachment` should return any Ruby IO object that responds to `:size` (returning file size in bytes),
`:read` (returning the entire file contents in UTF-8 encoding) and `:close` (closes the file). An example attachment
instance is `File.open(name)`.

## Testing

Currently, there is no test suite for this gem. However, test calls can be found in `test.rb`. Just clone this repo then run it to get example usage and test all the parts manually.

    ./test.rb

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
