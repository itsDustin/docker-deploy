GITHUB_ORG = 'ComboStrikeHQ'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_EMAIL = 'developers@combostrike.com'
DEPLOY_ENVS = {} # No deployments triggered by default (override DEPLOY_ENVS)

namespace :deploy do
  def bundler_audit!
    require 'bundler/audit/cli'

    Bundler::Audit::CLI.start(['update'])
    Bundler::Audit::CLI.start(['check', '--ignore CVE-2015-9284'])
  end

  def base_image
    return "docker-rails:#{ENV['DOCKER_BASE_TAG']}" if ENV['DOCKER_BASE_TAG']

    ruby_version_string = File.open('.ruby-version', &:readline).chomp
    version = Gem::Version.new(ruby_version_string).segments
    return 'docker-rails:ruby-2.5' if version.first == 2 && version[1] >= 5
    'docker-rails:ruby-2.4'
  end

  def github_org
    GITHUB_ORG.downcase
  end

  desc 'builds a docker image'
  task build_image: [:environment] do
    check_build_permission do
      build_image
    end
  end

  desc 'pushes the docker image'
  task push_image: [:environment] do
    check_build_permission do
      push_image
    end
  end

  desc 'builds and pushes a docker container'
  task docker: [:environment] do
    check_build_permission do
      build_image
      push_image
    end
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

  def build_image
    base_tag = "#{github_org}/#{base_image}"
    template_dir = File.expand_path('../../../config/', __FILE__)
    scripts_dir = File.expand_path('../../../scripts/', __FILE__)

    bundler_audit!

    Dir.chdir(Rails.root)
    check_gem! 'puma'
    check_gem! 'rails_migrate_mutex' unless ENV['NO_DB']
    check_gem! 'rack-timeout'

    Dir.foreach(template_dir) do |item|
      next if item == '.' or item == '..'

      infile = File.join(template_dir, item)

      if File.extname(item) == '.erb'
        outfile = File.join('.', File.basename(item, '.erb'))

        renderer = ERB.new(File.read(infile))

        File.write(outfile, renderer.result(binding))
      else
        FileUtils.cp(infile, '.')
      end
    end

    sh "#{scripts_dir}/update_geoip.sh"
    sh "find . -print0 |xargs -0 touch -h -t 1111111111"

    docker_login
    sh "docker pull #{base_tag}"
    sh <<-SH
      docker build \
        --build-arg BUGSNAG_API_KEY \
        --build-arg BUGSNAG_APP_VERSION \
        -t #{docker_new_image_tag} \
        .
    SH
  end

  def push_image
    docker_login
    sh "docker push #{docker_new_image_tag}"
  end

  def trigger_deployment(application, build, env)
    uri = URI::HTTPS.build(
      host: 'circleci.com',
      path: '/api/v1/project/ComboStrikeHQ/deployment/tree/master',
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

  def docker_new_image_tag
    application = ENV.fetch('CIRCLE_PROJECT_REPONAME')
    build       = ENV.fetch('CIRCLE_BUILD_NUM')

    "#{github_org}/#{application}:#{build}"
  end

  def check_build_permission
    branch = ENV.fetch('CIRCLE_BRANCH')

    unless %w(staging master).include?(branch) || ENV['FORCE_DOCKER_DEPLOY']
      puts 'Not on staging/master branch, not building docker container.'
      return
    end

    yield
  end

  def docker_login
    # check which version version of docker (and its login command) we're dealing with
    if `docker login --help`.include?('-e, --email')
      sh "docker login -e #{DEPLOY_EMAIL} -u #{DEPLOY_USER} -p $DOCKER_PASSWORD"
    else
      sh "docker login -u #{DEPLOY_USER} -p $DOCKER_PASSWORD"
    end
  end
end
