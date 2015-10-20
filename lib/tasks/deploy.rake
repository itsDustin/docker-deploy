GITHUB_ORG = 'ad2games'
BASE_IMAGE = 'docker-rails:latest'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_EMAIL = 'developers@ad2games.com'

namespace :deploy do
  def bundler_audit!
    require 'bundler/audit/cli'

    Bundler::Audit::CLI.start(['update'])
    Bundler::Audit::CLI.start(['check'])
  end

  desc 'builds and pushes a docker container'
  task docker: [:environment] do
    application = ENV['CIRCLE_PROJECT_REPONAME']
    build = ENV['CIRCLE_BUILD_NUM']
    prev_build = ENV['CIRCLE_PREVIOUS_BUILD_NUM']
    branch = ENV['CIRCLE_BRANCH']

    base_tag = "#{GITHUB_ORG}/#{BASE_IMAGE}"
    tag = "#{GITHUB_ORG}/#{application}:#{build}"
    prev_tag = "#{GITHUB_ORG}/#{application}:#{prev_build}"
    template_dir = File.expand_path('../../../config/', __FILE__)
    scripts_dir = File.expand_path('../../../scripts/', __FILE__)

    unless %w(staging master).include?(branch)
      puts 'Not on staging/master branch, not building docker container.'
      next
    end

    bundler_audit!

    Dir.chdir(Rails.root)
    check_gem! 'puma'
    check_gem! 'rails_12factor'
    check_gem! 'rails_migrate_mutex'
    check_gem! 'rack-timeout'

    sh "cp -r #{template_dir}/.??* ."
    sh "cp -r #{template_dir}/* ."
    sh "#{scripts_dir}/update_geoip.sh"
    sh "find . -print0 |xargs -0 touch -t 1111111111"
    sh "docker login -e #{DEPLOY_EMAIL} -u #{DEPLOY_USER} -p $DOCKER_PASSWORD"

    sh "docker pull #{prev_tag} || true"
    sh "docker pull #{base_tag}"
    sh "docker build -t #{tag} ."
    sh "docker push #{tag}"

    trigger_deployment(application, build, branch) if branch == 'staging'
  end

  def trigger_deployment(application, build, branch)
    url = "https://circleci.com/api/v1/project/ad2games/deployment/tree/master?circle-token=#{ENV['CIRCLE_TOKEN']}"
    build_params = {
      AUTO_DEPLOYMENT: '1',
      DEPLOYMENT_APP: application,
      DEPLOYMENT_BUILD: build,
      DEPLOYMENT_ENV: branch == 'master' ? 'production' : branch
    }
    response = HTTParty.post url,
      body: { build_parameters: build_params }.to_json,
      headers: { 'Content-Type' => 'application/json', 'Accept' => 'application/json' }
    puts "Deployment build triggered with build params: #{response['build_parameters']}"
    puts "Build URL: #{response['build_url']}"
  end

  def check_gem!(name)
    return if system("grep '^gem .#{name}' Gemfile")
    fail("Please add the '#{name}' gem to your Gemfile!")
  end
end
