FROM ad2games/docker-app

ADD Gemfile /home/app/webapp/Gemfile
ADD Gemfile.lock /home/app/webapp/Gemfile.lock
ADD vendor/cache /home/app/webapp/vendor/cache
RUN chown app:app -R /home/app
RUN sudo -u app bundle install --deployment --local --jobs=4 --without development test

ADD . /home/app/webapp
RUN chown app:app -R /home/app

RUN [ -e /home/app/webapp/.skip_assets_precompile ] || \
  sudo -E -u app bundle exec rake assets:precompile

EXPOSE 80
