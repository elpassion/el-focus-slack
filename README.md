# El Pomodoro Slack

## Development

- Start server
```bash
gem install foreman
foreman start
```

Foreman will start two processes: web server and sidekiq worker.
See [`Procfile`](https://github.com/elpassion/el-pomodoro-slack/blob/master/Procfile) for more details.

- Make localhost public (for example with `ngrok`)

```
ngrok http 5000 #=> https://f9e1f7b7.ngrok.io -> localhost:5000
```

- Setup slack app to use published server

    - https://api.slack.com/apps/A4BTH6FBJ/oauth
    - https://api.slack.com/apps/A4BTH6FBJ/event-subscriptions
    
- Update `SLACK_REDIRECT_URI` in `.env`