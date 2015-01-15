require 'aws-sdk-core'

namespace :deploy do
  desc 'creates a deployable archive'
  task archive: :environment do
    application = ENV['CIRCLE_PROJECT_REPONAME']
    build = ENV['CIRCLE_BUILD_NUM']
    branch = ENV['CIRCLE_BRANCH']
    template_dir = File.expand_path('../../../config/', __FILE__)

    %x{
      cd #{Rails.root} &&
      git archive --format zip --output /tmp/release.zip #{branch} &&
      zip -ur /tmp/release.zip vendor/cache &&
      cd #{template_dir} &&
      zip -ur /tmp/release.zip * .??*
    }

    Aws::S3::Client.new.put_object(
      bucket: "#{application.gsub('_', '-')}.packages",
      key: "#{build}.zip",
      body: File.new('/tmp/release.zip')
    )
  end
end
