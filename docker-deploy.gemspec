$LOAD_PATH.push File.expand_path('../lib', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'docker-deploy'
  s.version     = '1.1.1'
  s.date        = '2014-11-19'
  s.summary     = 'Docker deployment utilities for AWS Elastic Beanstalk'
  s.description = ''
  s.authors     = ['Combostrike GmbH']
  s.email       = 'developers@combostrike.com'
  s.files       = Dir['lib/**/*']
  s.homepage    = 'http://www.combostrike.com'
  s.license     = ''

  s.add_dependency 'rake'
  s.add_dependency 'bundler-audit', '~> 0.8.0'
end
