module Rip
  class DependencyManager
    def initialize(env = nil)
      @env = env || Rip::Env.active
      load

      # key is the package name, value is the current
      # installed version
      @versions ||= {}

      # key is the package name, value is an array of
      # libraries it depend on
      @heritage ||= {}

      # key is the package name, value is an array of
      # libraries that depend on it
      @lineage ||= {}

      # key is the package name, value is the source
      @sources ||= {}
    end

    def packages
      @versions.keys.map { |name| package(name) }
    end

    def package(name)
      Package.for(@sources[name], @versions[name])
    end

    def packages_that_depend_on(name)
      @lineage[name] || []
    end

    def files(name)
      Array(@files[name])
    end

    def installed?(name)
      @versions.has_key? name
    end

    def package_version(name)
      @versions[name]
    end

    def add_package(package, parent = nil)
      name = package.name
      version = package.version

      if @versions.has_key?(name) && @versions[name] != version
        puts "#{name} requested at #{version} by #{parent}"
        puts "#{name} already #{@versions[name]} by #{@heritage[name][0]}"
        abort "sorry."
      end

      if parent
        @heritage[name] ||= []
        @heritage[name].push(parent.name)
        @lineage[parent.name] ||= []
        @lineage[parent.name].push(name)
      end

      # already installed?
      if @versions.has_key? name
        false
      else
        @versions[name] = version
        @sources[name] = package.source
        save
        true
      end
    end

    def add_files(name, file_list = [])
      @files[name] ||= []
      @files[name].concat file_list
      save
    end

    def remove_package(name)
      Array(@heritage[name]).each do |dep|
        @lineage[dep].delete(name) if @lineage[dep].respond_to? :delete
      end

      @heritage.delete(name)
      @lineage.delete(name)
      @versions.delete(name)
      save
    end

    def path
      File.join(Rip.dir, @env, "#{@env}.ripenv")
    end

    def save
      File.open(path, 'w') do |f|
        f.puts marshal_payload
        f.flush
      end
    end

    def load
      marshal_read File.read(path) if File.exists? path
    end

    def marshal_payload
      Marshal.dump [ @versions, @heritage, @lineage, @sources ]
    end

    def marshal_read(data)
      @versions, @heritage, @lineage, @sources = Marshal.load(data)
    end
  end
end
