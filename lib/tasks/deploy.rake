GITHUB_ORG = 'ad2games'
DEPLOY_USER = 'ad2gamesdeploy'
DEPLOY_EMAIL = 'developers@ad2games.com'

namespace :deploy do
  desc 'builds and pushes a docker container'
  task docker: :environment do
    application = ENV['CIRCLE_PROJECT_REPONAME']
    build = ENV['CIRCLE_BUILD_NUM']
    branch = ENV['CIRCLE_BRANCH']
    tag = "#{GITHUB_ORG}/#{application}:#{build}"
    template_dir = File.expand_path('../../../config/', __FILE__)

    unless %w(staging master).include?(branch)
      puts 'Not on staging/master branch, not building docker container.'
      next
    end

    Dir.chdir(Rails.root)
    sh "cp -r #{template_dir}/* ."
    sh "docker login -e #{DEPLOY_EMAIL} -u #{DEPLOY_USER} -p $DOCKER_PASSWORD"
    sh "docker build -t #{tag} ."
    sh "docker push #{tag}"
  end
end
