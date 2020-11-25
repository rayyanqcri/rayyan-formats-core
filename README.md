[![Build Status](https://travis-ci.org/rayyanqcri/rayyan-formats-core.svg?branch=master)](https://travis-ci.org/rayyanqcri/rayyan-formats-core)
[![Coverage Status](https://coveralls.io/repos/github/rayyanqcri/rayyan-formats-core/badge.svg?branch=master)](https://coveralls.io/github/rayyanqcri/rayyan-formats-core?branch=master)

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

### Importing

To do the actual importing of reference files:

    source = RayyanFormats::Source.new("example.csv")
    RayyanFormats::Base.import(source) { |target, total|
      # post processing for target
      puts "Found target: #{target}. Total: #{total}."
    }

If you want to convert the input before importing it, for example to convert
non-UTF8 encoded files to UTF8 encoded files, add a converter lambda as follows:

    RayyanFormats::Base.import(source, ->(body, ext){ #my_converter_logic_here })

### Exporting

To do the actual exporting of reference files, assuming articles are stored
in an array of targets:

    plugin = RayyanFormats::Base.get_export_plugin('csv')
    targets.each do |target|
        puts plugin.export(target)
    end

### Data Types

#### RayyanFormats::Source

In the previous 2 examples, note that `RayyanFormats::Source` is a proxy class. You can supply any class instance that responds to the following:
`:name` and `:attachment`. `:name` should return the file name string ending with a proper supported extension.
`:attachment` should return any Ruby IO object that responds to `:size` (returning file size in bytes),
`:read` (returning the entire file contents in UTF-8 encoding) and `:close` (closes the file). An example attachment
instance is `File.open(name)`.

#### RayyanFormats::Target

Note also that `RayyanFormats::Target` is a forgiving object
that accepts any setter method, stores it and returns it when accessed again
with the corresponding getter method. For example:

    t = RayyanFormats::Target.new
    t.a = 1
    puts t.a # 1
    t.b = "hello"
    puts t.b # "hello"
    t.c = [1, 2, 3]
    puts t.c.inspect # [1, 2, 3]

## Development and Testing

To build for local development and testing (requires Docker):

```bash
docker build . -t rayyan-formats-core:1
```

To run the tests:

```bash
docker run -it --rm -v $PWD:/home rayyan-formats-core:1
```

This will allow you to edit files and re-run the tests without rebuilding
the image.

## Publishing the gem

```bash
docker build . -t rayyan-formats-core:1
docker run -it --rm rayyan-formats-core:1 /home/publish.sh
```

Enter your email and password when prompted. If you want to skip interactive
login, supply `RUBYGEMS_API_KEY` as an additional argument:

```bash
docker run -it --rm -e RUBYGEMS_API_KEY=YOUR_RUBYGEMS_API_KEY rayyan-formats-core:1 /home/publish.sh
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
