FROM ad2games/docker-app

ADD . /home/app/webapp
RUN chown app:app -R /home/app
RUN sudo -u app bundle install --deployment --jobs 4 --without development test && \
  find vendor/bundle -name *.gem -delete

RUN [ -e /home/app/webapp/.skip_assets_precompile ] || \
  sudo -E -u app bundle exec rake assets:precompile RAILS_ENV=production

EXPOSE 80
