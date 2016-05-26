Gem::Specification.new do |gem|
  gem.name          = 'kitcat'
  gem.version       = '1.0.1'
  gem.summary       = 'a framework to support data processing'
  gem.description   = 'initially created for data migrations. Provides logging, progess bar and graceful handling'
  gem.licenses      = ['MIT']
  gem.authors       = ['Simply Business']
  gem.email         = ['tech@simplybusiness.co.uk']
  gem.homepage      = 'https://github.com/simplybusiness/kitcat'
  gem.files         = Dir['Rakefile', '{lib, spec}/**/*.rb', 'LICENSE', '*.md']
  gem.require_path  = 'lib'

  gem.add_runtime_dependency 'ruby-progressbar'
  gem.add_runtime_dependency 'activemodel'

  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'coveralls'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'bundler-audit'
end
