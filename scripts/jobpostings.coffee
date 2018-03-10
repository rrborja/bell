# Disclose if recruiter. Respond in thread. Repost 1/mo.
#
# Company | Location | Pay range | Job Title | Tweet size description | Link

politeMessageToRecruiter = (user, returnedMsg) -> "Hi <@#{user}>! The job description you have just posted " +
  "did not follow the formatting guideline so we deleted it.\n\n" +
  "Here's how it should be done:\n" +
  "Company: `The company who is hiring`\n" +
  "Location: `The location of the company`\n" +
  "Pay range: `The pay range`\n" +
  "Job Title: `The job title`\n" +
  "Description: `This is your opportunity to pitch your sales talk up to 260 characters`\n" +
  "Link: `The external link to the job posting`\n\n" +
  "Here's an example:\n" +
  "Company: *Philly Dev*\n" +
  "Location: *Philadelphia, PA*\n" +
  "Pay range: *112358-132134*\n" +
  "Job Title: *Slack Bot Developer*\n" +
  "Description: *Our community in Philly is in need of talented bot developers to develop an intelligent system in order to launch skynet before judgment day.*\n" +
  "Link: http://phillydev.org\n\n"  +
  "We will return back the job posting you have just sent in hopes that you will correct it:\n" +
  "`#{returnedMsg}`\n\n" +
  "Thank you!"

dmUserSilently = (user, msg) ->
  robot.http("https://slack.com/api/chat.postEphemeral")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query({
    token: process.env.HUBOT_SLACK_TOKEN
    channel: process.env.JOB_POSTING_CHANNEL
    user: user
    text: msg
  })
  .post()()

deletePrevMessage = (ts) ->
  robot.http("https://slack.com/api/chat.delete")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query({
    token: process.env.JANITOR_USER_TOKEN
    channel: process.env.JOB_POSTING_CHANNEL
    ts: ts
    as_user: true
  })
  .post()()

reformatJobPosting = (msgId, title, description, company, approxCompanyLink, location, payrange, link) ->
  robot.http("https://slack.com/api/chat.update")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query({
    token: process.env.JANITOR_USER_TOKEN
    channel: process.env.JOB_POSTING_CHANNEL
    ts: msgId
    text: " "
    attachments: JSON.stringify [{
      color: "#36a64f"
      title: title
      text: description
      author_name: company
      author_link: approxCompanyLink
      fields: [
        {title: "Location", value: "<https://www.google.com/maps?q=#{company}+#{location}|#{location}>", short: true},
        {title: "Pay range", value: payrange, short: true}
      ]
      actions: [
        {type: "button", text: "Learn more...", url: link}
      ]
    }]
  })
  .post()()

module.exports = (robot) ->
  robot.hear /.*/i, (res) ->

    msgId = res.message.id
    userId = res.message.user.id

    if res.message.rawMessage.channel != process.env.JOB_POSTING_CHANNEL
      return

    if res.message.rawMessage.reply_broadcast?
      deletePrevMessage msgId
      dmUserSilently userId "Hi <@#{userId}>! Currently, we do not allow broadcasting replies in this channel."

    if res.message.rawMessage.thread_ts?
      return

    jobDescriptionFormat = /Company: ?(.*)\nLocation: ?(.*)\nPay range: ?([\d\-]*|TBD\d*)\nJob Title: ?(.*)\nDescription: ?(.{0,260})\nLink: ?(.*)/i
    if not res.message.match jobDescriptionFormat
      deletePrevMessage msgId
      dmUserSilently(userId, politeMessageToRecruiter(userId, res.message.text))

    else
      robot.emit 'slack.reaction',
        message: res.message
        name: 'white_check_mark'

      extracts = res.message.match jobDescriptionFormat

      company = extracts[1]
      location = extracts[2]
      payrange = extracts[3]
      title = extracts[4]
      description = extracts[5]
      link = extracts[6]

      approxCompanyLink = "https://www.google.com/search?q=#{company.split(' ').join('+')}+careers&btnI"

      reformatJobPosting(msgId, title, description, company, approxCompanyLink, location, payrange, link)


