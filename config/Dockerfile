FROM ad2games/app-base:latest

CMD ["/sbin/my_init"]
EXPOSE 80
WORKDIR /home/app/webapp

ADD Gemfile Gemfile.lock /home/app/webapp/
RUN chown app:app Gemfile Gemfile.lock && \
  chpst -u app bundle install --deployment --jobs 4 --without development test && \
  find vendor/bundle -name *.gem -delete

ADD . /home/app/webapp/
RUN mkdir -p public/assets log tmp && chown -R app:app public log tmp

RUN [ -e ./.skip_assets_precompile ] || \
  chpst -u app bundle exec rake assets:precompile \
  SECRET_KEY_BASE=noop RAILS_ENV=production DATABASE_URL=postgres://noop
