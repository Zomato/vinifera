set -e
# https://stackoverflow.com/a/40019538

# Install Dependencies
if [[ ${RAILS_ENV} == "production" ]]; then
   bundle install --no-binstubs --jobs $(nproc) --retry 3 --without development test
else
   bundle install --no-binstubs --jobs $(nproc) --retry 3
fi

# Setup DB from scratch if not present else just run migrations
(bundle exec rails db:migrate 2>/dev/null ) || bundle exec rails db:setup

# Setup Cron Jobs
bundle exec whenever --update-crontab

# Run Sidekiq
bundle exec sidekiq