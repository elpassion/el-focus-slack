# TODO

- Send message about finished session.
- Prevent jobs from duplication. Check how many jobs are running for single user after following scenarios:
  - Start - Pause - Start.
   
  Should 2nd _Start_ be equal to _Unpause_ or should start totally new session?
  
  - Start - Stop (very quick) - Start. 
  
  2nd _Start_ should not start 2nd SendBusyMessagesWorker.
  
  - Start - Start
  
- User has unread messages. Then user starts session. Should it send busy messages to interlocutors?
- Check Slack API limits
- Rounding time values
- Extract Session abstraction layer.

# Development

rackup
bundle exec sidekiq -r ./dnd_worker.rb
