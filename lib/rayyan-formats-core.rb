# encoding: utf-8
# we set encoding here so that the BOM regex is compiled into utf-8
# so that comparison with utf-8 strings won't raise exception

require "rayyan-formats-core/version"
require "rayyan-formats-core/plugins/base"
require "rayyan-formats-core/plugins/plain_text"
require "rayyan-formats-core/plugins/csv"

module RayyanFormats
end
