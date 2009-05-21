module Rip
  class GemPackage < Package
    handles '.gem'

    def initialize(source, version = nil)
      @source = File.expand_path(source.strip.chomp)
      @version = version
    end

    def name
      metadata[:name]
    end

    def version
      metadata[:version]
    end

    def cache_file
      "#{cache_path}.gem"
    end

    def exists?
      if `which gem`.strip.empty?
        abort "you don't have rubygems installed"
      end

      File.exists?(source)
    end

    def fetch!
      FileUtils.cp File.expand_path(source), cache_file
    end

    def unpack!
      system "gem unpack #{cache_file} --target=#{packages_path} > /dev/null"
    end

    memoize :metadata
    def metadata
      parts = source.split('/').last.chomp('.gem').split('-')
      { :name => parts[0...-1].join('-'), :version => parts[-1] }
    end
  end
end