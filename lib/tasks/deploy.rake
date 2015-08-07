GITHUB_ORG = 'ad2games'
BASE_IMAGE = 'app-base:latest'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_EMAIL = 'developers@ad2games.com'

def bundler_audit!
  require 'bundler/audit/cli'

  Bundler::Audit::CLI.start(['update'])
  Bundler::Audit::CLI.start(['check'])
end

namespace :deploy do
  desc 'run bundler-audit'
  task :bundler_audit do
    bundler_audit!
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
      application: application,
      build: build,
      environment: branch == 'master' ? 'production' : branch
    }
    HTTParty.post url, body: build_params.to_json, headers: { 'Content-Type' => 'application/json' }
  end
end
