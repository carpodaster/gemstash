require "pathname"
require "fileutils"

module Gemstash
  # Caching layer for gem files
  #
  # given a folder, this class will provide a get method to return a CachedGemFile
  # which may exist or not
  class GemStorage
    def initialize(folder = nil)
      if folder && !File.writable?(folder)
        raise "Folder #{folder} does not exist or is not writable"
      end

      folder ||= Gemstash::Env.base_file("gem_cache")
      @folder = Pathname.new(folder)
    end

    def get(name)
      CachedGemFile.new(@folder, name)
    end
  end

  # A Gem File that may exist or not
  #
  # Provides both a way or reading the file (if it exists)
  # and a way of saving it along with the GET headers
  class CachedGemFile
    def initialize(folder, name)
      @folder = folder.join(File.basename(name, ".gem"))
      @name = name
    end

    def save(headers, content)
      FileUtils.mkpath(@folder) unless Dir.exist?(@folder)
      File.open(headers_path, "w") {|f| f.write(headers.to_yaml) }
      File.open(content_path, "w") {|f| f.write(content) }
      @headers = headers
      @content = content
      self
    end

    def exist?
      content_path.exist? && headers_path.exist?
    end

    def content
      load
      @content
    end

    def headers
      load
      @headers
    end

  private

    def load
      return unless @content.nil? && @headers.nil?
      raise "#{@name} does not exiat" unless exist?
      @headers = File.open(headers_path) {|f| YAML.load(f.read) }
      @content = File.open(content_path, &:read)
    end

    def content_path
      @folder.join(@name)
    end

    def headers_path
      @folder.join("headers.yaml")
    end
  end
end
