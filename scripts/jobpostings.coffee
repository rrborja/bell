# Disclose if recruiter. Respond in thread. Repost 1/mo.
#
# Company | Location | Pay range | Job Title | Tweet size description | Link

module.exports = (robot) ->
  robot.hear /.*/i, (res) ->
    jobDescriptionFormat = /Company(: )?(.*)\nLocation(: )?(.*)\n(Pay range(: )?([\d\-]*|TBD(\d)*)\n)?Job Title(: )?(.*)\nDescription(: )?(.*)\n(Link(: )?)?(.*)/i
    if not res.message.match jobDescriptionFormat
      robot.http("https://slack.com/api/chat.postEphemeral")
        .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
        .header('Content-Type', 'application/json')
        .query({
          token: process.env.HUBOT_SLACK_TOKEN
          channel: process.env.JOB_POSTING_CHANNEL
          user: res.envelope.user.id
          text: "Hi! The job description you have just posted did not follow the formatting guideline so we deleted it."
        })
        .post() (err, res, body) ->
      robot.http("https://slack.com/api/chat.delete")
        .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
        .header('Content-Type', 'application/json')
        .query({
          token: process.env.JANITOR_USER_TOKEN
          channel: process.env.JOB_POSTING_CHANNEL
          ts: res.message.id
          as_user: true
        })
        .post() (err, res, body) ->
    else
      robot.emit 'slack.reaction',
        message: res.message
        name: 'white_check_mark'
