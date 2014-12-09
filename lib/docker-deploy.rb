module DockerDeploy
  if defined?(Rails)
    class Railtie < Rails::Railtie
      railtie_name :docker_deploy

      rake_tasks do
        load 'tasks/deploy.rake'
      end
    end
  end
end
