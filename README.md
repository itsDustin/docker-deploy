# Docker Deployment Helper

Helper gem to create docker containers on a CI server.

## Setup
Add the following line to the development group in your Gemfile:
```ruby
gem 'docker-deploy', github: 'ad2games/docker-deploy'
```

## What It Does
- Runs [bundler-audit](https://github.com/rubysec/bundler-audit)
- Creates a Dockerfile using our [Docker Baseimage](https://github.com/ad2games/docker-app)
- Installs gems
- Precompiles Rails assets
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
Our CI builds and pushes containers on every push to the master and staging branches.

Make sure to set `DOCKER_PASSWORD` in the CI ENV.

To run it manually (please don't!), use `bundle exec rake docker:deploy`.

## License

MIT, see LICENSE.txt

## Contributing

Feel free to fork and submit pull requests!
