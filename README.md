# Docker Deployment Helper

Helper gem to create docker containers on a CI server.

## Setup
Add the following line to the development group in your Gemfile:
```ruby
gem 'docker-deploy', require: false, git: 'https://github.com/ad2games/docker-deploy'
```

## What It Does
- Runs [bundler-audit](https://github.com/rubysec/bundler-audit)
- Checks that `puma`, `rails_12factor` and `rails_migrate_mutex` are installed
- Creates a Dockerfile using our [Docker-Rails Baseimage](https://github.com/ad2games/docker-rails)
- Downloads GeoIP Database (only when `GEOIP_LICENSE_KEY` ENV is set)
- Pushes container to private Docker Hub repository tagged with the CI build number

## Caching
To achieve faster builds, it pulls the previously pushed image from Docker Hub. If there was
no change in gem versions, the whole `bundle install` step can now be skipped,
resulting way faster builds.

## Dockerignore
This gems contains a [.dockerignore](config/.dockerignore) file to exclude everything not
needed for production deployment. That includes the git repo, spec files and
artifacts left over from the CI test run.

## CI Setup
Add the following line to the deployment step of the CI config:

```
bundle exec rake -r docker-deploy docker:deploy
```

Make sure to set `DOCKER_PASSWORD` in the CI ENV.

## License

MIT, see LICENSE.txt

## Contributing

Feel free to fork and submit pull requests!
