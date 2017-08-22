GITHUB_ORG = 'ad2games'
BASE_IMAGE = 'docker-rails:latest'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_ENVS = {} # No deployments triggered by default (override DEPLOY_ENVS)

namespace :deploy do
  def bundler_audit!
    require 'bundler/audit/cli'

    Bundler::Audit::CLI.start(['update'])
    Bundler::Audit::CLI.start(['check'])
  end

  desc 'builds and pushes a docker container'
  task docker: [:environment] do
    application = ENV.fetch('CIRCLE_PROJECT_REPONAME')
    build       = ENV.fetch('CIRCLE_BUILD_NUM')
    prev_build  = ENV.fetch('CIRCLE_PREVIOUS_BUILD_NUM', false)
    branch      = ENV.fetch('CIRCLE_BRANCH')

    base_tag = "#{GITHUB_ORG}/#{BASE_IMAGE}"
    tag = "#{GITHUB_ORG}/#{application}:#{build}"
    prev_tag = "#{GITHUB_ORG}/#{application}:#{prev_build}"
    template_dir = File.expand_path('../../../config/', __FILE__)
    scripts_dir = File.expand_path('../../../scripts/', __FILE__)

    unless %w(staging master).include?(branch) || ENV['FORCE_DOCKER_DEPLOY']
      puts 'Not on staging/master branch, not building docker container.'
      next
    end

    bundler_audit!

    Dir.chdir(Rails.root)
    check_gem! 'puma'
    check_gem! 'rails_migrate_mutex' unless ENV['NO_DB']
    check_gem! 'rack-timeout'

    sh "cp -r #{template_dir}/.??* ."
    sh "cp -r #{template_dir}/* ."
    sh "#{scripts_dir}/update_geoip.sh"
    sh "find . -print0 |xargs -0 touch -t 1111111111"
    sh "docker login -u #{DEPLOY_USER} -p $DOCKER_PASSWORD"

    sh "docker pull #{prev_tag} || true" if prev_build
    sh "docker pull #{base_tag}"
    sh "docker build -t #{tag} ."
    sh "docker push #{tag}"
  end

  desc 'triggers deployment builds on CircleCI'
  task trigger: [:environment] do
    require 'json'

    branch = ENV.fetch('CIRCLE_BRANCH')
    build  = ENV.fetch('CIRCLE_BUILD_NUM')

    deploy_apps.uniq.each do |app|
      deploy_envs.fetch(branch, []).each { |env| trigger_deployment(app, build, env) }
    end
  end

  def trigger_deployment(application, build, env)
    uri = URI::HTTPS.build(
      host: 'circleci.com',
      path: '/api/v1/project/ad2games/deployment/tree/master',
      query: URI.encode_www_form('circle-token' => ENV['CIRCLE_TOKEN']))
    build_params = {
      AUTO_DEPLOYMENT: '1',
      DEPLOYMENT_APP: application,
      DEPLOYMENT_BUILD: build,
      DEPLOYMENT_ENV: env
    }
    response = http_post(uri,
      { build_parameters: build_params }.to_json,
      { 'Content-Type' => 'application/json', 'Accept' => 'application/json' })
    puts "Deployment build triggered with build params: #{response['build_parameters']}"
    puts "Build URL: #{response['build_url']}"
  end

  def deploy_envs
    return DEPLOY_ENVS unless ENV.key?('DEPLOY_ENVS')
    # e.g., DEPLOY_ENVS=master:production,staging:staging,staging:preview
    ENV.fetch('DEPLOY_ENVS').split(',').each_with_object({}) do |pair, obj|
      branch, env = pair.split(':')
      obj[branch] = obj.fetch(branch, []).push(env)
    end
  end

  def deploy_apps
    return [ENV.fetch('CIRCLE_PROJECT_REPONAME')] unless ENV.key?('DEPLOY_APPS')
    # e.g., DEPLOY_APPS=app1,app2
    ENV.fetch('DEPLOY_APPS').split(',')
  end

  def check_gem!(name)
    return if system("grep '^gem .#{name}' Gemfile")
    fail("Please add the '#{name}' gem to your Gemfile!")
  end

  def http_post(uri, body, headers)
    response = Net::HTTP.start(uri.host, use_ssl: uri.scheme == 'https') do |http|
      http.request_post(uri.request_uri, body, headers)
    end

    JSON.parse(response.body)
  end
end
