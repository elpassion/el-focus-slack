web: bundle exec puma -t 5:5 -p ${PORT:-9292} -e ${RACK_ENV:-development}
worker: bundle exec sidekiq -r ./sidekiq_server.rb -C config/sidekiq.yml
