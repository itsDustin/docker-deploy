GITHUB_ORG = 'ad2games'
BASE_IMAGE = 'app-base:latest'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_EMAIL = 'developers@ad2games.com'

namespace :deploy do
  desc 'builds and pushes a docker container'
  task docker: :environment do
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
  end
end
