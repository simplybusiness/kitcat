Dir['./lib/**/*.rb'].each { |file| require file }
require 'timecop'
require 'coveralls'
Coveralls.wear!
