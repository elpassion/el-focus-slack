# TODO

- Send message about finished session.
- Prevent jobs from duplication. Check how many jobs are running for single user after following scenarios:
  - Start - Pause - Start
  - Start - Stop - Start
  - Start - Start
- Check Slack API limits
- Rounding time values
- Extract Session abstraction layer.

# Development

rackup
bundle exec sidekiq -r ./dnd_worker.rb
