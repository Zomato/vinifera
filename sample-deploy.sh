echo "Installing new gems ... "
bundle install --quiet

echo "Updating cron schedules"

bundle exec whenever --update-crontab

echo "Running Migrations ..."

RAILS_ENV=production bundle exec rails db:migrate

echo "Restarting Sidekiq ... "

sudo systemctl restart vinifera-sidekiq.service

echo "Deployment Done ... :) "
