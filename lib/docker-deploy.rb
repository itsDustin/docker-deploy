module DockerDeploy
  class Railtie < Rails::Railtie
    railtie_name :docker_deploy

    rake_tasks do
      load 'tasks/deploy.rake'
    end
  end
end
