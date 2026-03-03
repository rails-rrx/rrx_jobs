# frozen_string_literal: true

require_relative 'lib/rrx_jobs/version'

Gem::Specification.new do |spec|
  source_uri = 'https://github.com/rails-rrx/rrx_jobs'
  home_uri = source_uri

  spec.name = 'rrx_jobs'
  spec.version = RrxJobs::VERSION
  spec.authors = ['Dan Drew']
  spec.email = ['dan.drew@hotmail.com']

  spec.summary = 'Opinionated ActiveJob support for web services'
  spec.description = 'Opinionated ActiveJob support for web services'
  spec.homepage = home_uri
  spec.license = 'MIT'
  spec.required_ruby_version = '~> 3.4.0'

  spec.metadata['homepage_uri']    = home_uri
  spec.metadata['source_code_uri'] = source_uri

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git])
    end
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', RrxJobs::RAILS_VERSION
  spec.add_dependency 'solid_queue', '~> 1.1'
  spec.add_dependency 'rrx_config'
  spec.add_dependency 'rrx_logging'
  spec.add_development_dependency 'rrx_dev'
  spec.add_development_dependency 'rrx_api'
  spec.add_development_dependency 'sqlite3', '~> 2.0'
end
