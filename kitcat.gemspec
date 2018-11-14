lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitcat/version'

gem_version = if ENV['GEM_PRE_RELEASE'].nil? || ENV['GEM_PRE_RELEASE'].empty?
                Kitcat::VERSION
              else
                "#{Kitcat::VERSION}.#{ENV['GEM_PRE_RELEASE']}"
              end

Gem::Specification.new do |gem|
  gem.name          = 'kitcat'
  gem.version       = gem_version
  gem.summary       = 'a framework to support data processing'
  gem.description   = 'initially created for data migrations. Provides logging, progess bar and graceful handling'
  gem.licenses      = ['MIT']
  gem.authors       = ['Simply Business']
  gem.email         = ['tech@simplybusiness.co.uk']
  gem.homepage      = 'https://github.com/simplybusiness/kitcat'
  gem.files         = Dir['Rakefile', '{lib, spec}/**/*.rb', 'LICENSE', '*.md']
  gem.require_path  = 'lib'

  gem.add_runtime_dependency 'activemodel', ['>= 4.2', '< 6']
  gem.add_runtime_dependency 'ruby-progressbar', '~> 1.8'

  gem.add_development_dependency 'bundler-audit', '~> 0.5'
  gem.add_development_dependency 'coveralls', '~> 0.8'
  gem.add_development_dependency 'rake', '~> 11.1'
  gem.add_development_dependency 'rspec', '~> 3.4'
  gem.add_development_dependency 'rubocop', '~> 0.40'
  gem.add_development_dependency 'timecop', '~> 0.8'
end
