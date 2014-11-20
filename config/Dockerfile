FROM quay.io/ad2games/app:master

ADD Gemfile /home/app/webapp/Gemfile
ADD Gemfile.lock /home/app/webapp/Gemfile.lock
RUN sudo -u app bundle install --deployment --jobs=4 --without development test

ADD . /home/app/webapp
RUN chown app:app -R /home/app

RUN sudo -E -u app bundle exec rake assets:precompile

EXPOSE 80
