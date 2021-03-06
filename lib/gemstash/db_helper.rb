module Gemstash
  #:nodoc:
  class DBHelper
    def find_or_insert_rubygem(spec)
      row = Gemstash::Env.db[:rubygems][:name => spec.name]
      return row[:id] if row
      Gemstash::Env.db[:rubygems].insert(
        :name => spec.name,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def find_version(gem_id, spec)
      Gemstash::Env.db[:versions][
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform]
    end

    def insert_version(gem_id, spec, indexed = true)
      Gemstash::Env.db[:versions].insert(
        :rubygem_id => gem_id,
        :number => spec.version.to_s,
        :platform => spec.platform,
        :indexed => indexed,
        :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
        :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
    end

    def insert_dependencies(version_id, spec)
      spec.runtime_dependencies.each do |dep|
        requirements = dep.requirement.requirements
        requirements = requirements.map {|r| "#{r.first} #{r.last}" }
        requirements = requirements.join(", ")
        Gemstash::Env.db[:dependencies].insert(
          :version_id => version_id,
          :rubygem_name => dep.name,
          :requirements => requirements,
          :created_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP,
          :updated_at => Sequel::SQL::Constants::CURRENT_TIMESTAMP)
      end
    end

    def find_dependencies(gems)
      results = Gemstash::Env.db["
        SELECT rubygem.name,
               version.number, version.platform,
               dependency.rubygem_name, dependency.requirements
        FROM rubygems rubygem
        JOIN versions version
          ON version.rubygem_id = rubygem.id
        LEFT JOIN dependencies dependency
          ON dependency.version_id = version.id
        WHERE rubygem.name IN ?
          AND version.indexed = ?", gems.to_a, true].to_a
      results.group_by {|r| r[:name] }.each do |gem, rows|
        requirements = rows.group_by {|r| [r[:number], r[:platform]] }

        value = requirements.map do |version, r|
          deps = r.map {|x| [x[:rubygem_name], x[:requirements]] }
          deps = [] if deps.size == 1 && deps.first.first.nil?

          {
            :name => gem,
            :number => version.first,
            :platform => version.last,
            :dependencies => deps
          }
        end

        yield(gem, value)
      end
    end
  end
end
