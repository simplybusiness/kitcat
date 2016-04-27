Gem::Specification.new do |spec|
  spec.name        = 'kitcat'
  spec.version     = '0.0.0'
  spec.summary     = 'a framework to support data processing'
  spec.description = 'initially created for data migrations. Provides logging, progess bar and graceful handling'
  spec.authors     = ['Simply Business']
  spec.email       = ['tech@simplybusiness.co.uk']
  spec.homepage    = 'https://github.com/simplybusiness/kitcat'
  spec.license     = 'MIT'
  spec.files       = Dir['lib/   *.rb']
  require_paths    = ["lib"]

  spec.add_runtime_dependency 'ruby-progressbar'
  spec.add_runtime_dependency 'activemodel'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'timecop'
end
