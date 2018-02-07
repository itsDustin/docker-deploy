$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'docker-deploy'
  s.version     = '1.1.0'
  s.date        = '2014-11-19'
  s.summary     = 'Docker deployment utilities for AWS Elastic Beanstalk'
  s.description = ''
  s.authors     = ['ad2games GmbH']
  s.email       = 'developers@ad2games.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'http://www.ad2games.com'
  s.license     = ''

  s.add_dependency 'rake'
  s.add_dependency 'bundler-audit'
end
