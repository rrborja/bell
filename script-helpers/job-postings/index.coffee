jobDescriptionFormat = /[\s]*^company\s*:\s*(.{1,50})[\|\n][\s\w]*location\s*:\s*(.{1,50})[\|\n][\s\w]*pay *range\s*:\s*([\$]?[\d,]+(?: ?(?:-|to) ?\$?[\d,]+)?\/?(?:hr|wk|mo|yr|hour|week|month|year)?)[\|\n][\s\w]*job *title\s*:\s*(.{5,50})[\|\n][\s\w]*description\s*:\s*((?:.|\n){20,260})(?:.*)[\|\n][\s\w]*link\s*:\s*(.*)\s*$\w*/i

politeMessageToRecruiter = (returnedMsg) -> "The job description you have just posted " +
  "did not follow the formatting guideline so we deleted it.\n\n" +
  "Here's how it should be done:\n" +
  "Company: `The company who is hiring`\n" +
  "Location: `The location of the company`\n" +
  "Pay range: `The pay range`\n" +
  "Job title: `The job title`\n" +
  "Description: `This is your opportunity to pitch your sales talk up to 260 characters long`\n" +
  "Link: `The external link to the job posting`\n\n" +
  "Here's an example:\n" +
  "Company: *Philly Dev*\n" +
  "Location: *Philadelphia, PA*\n" +
  "Pay range: *112358-132134*\n" +
  "Job title: *Slack Bot Developer*\n" +
  "Description: *Our community in Philly is in need of talented bot developers to develop an intelligent system in order to launch skynet before judgment day.*\n" +
  "Link: http://phillydev.org\n\n"  +
  "We will return back the job posting you have just sent in hopes that you will correct it:\n" +
  "```#{returnedMsg}```\n\n" +
  "Thank you!"

welcomeMessage = "Welcome to the <#job-postings> channel where everyone can advertise their " +
  "job postings whether you are a recruiter or not. If you are seeking new opportunities, this is the right place!\n\n" +
  "This channel employs common sense rules to make this channel friendly for *everyone*.\n" +
  "1. Simply follow this format:\n" +
  "```Company: _______________________________________\n" +
  "Location: ______________________________________\n" +
  "Pay range: _____________________________________\n" +
  "Job title: _____________________________________\n" +
  "Description: ___________________________________\n" +
  "Link: __________________________________________```\n" +
  "2. Do not combine them in a single line. Separate the fields by a new line\n" +
  "3. The description must be up to 260 characters.\n" +
  "4. All fields are not optional.\n" +
  "5. Anyone can reply to a posting by starting a separate thread but no one can broadcast their replies.\n\n" +
  "If your posting does not meet all five rules, your message may automatically be rejected and an error will be \n" +
  "shown to you in order for you to fix it.\n\n" +
  "If you have any questions, message the word `faqs` here.\n\nThank you!"

tipsTldr = "Do all fields have to be in order?\n" +
  "```Yes```\n\n" +
  "The last part of my `description` is missing after I posted. Why is that?\n" +
  "```We recommend to shorten your description that would fit no longer than 260 characters. If you go beyond the limit, " +
  "the excess of your description will be truncated.```\n" +
  "Is there a way to leave out the `pay range`?\n" +
  "```As of now, all fields are required to be filled up. You may type in 0 but we hold no responsibility for the " +
  "accuracy of your posting.```\n\n" +
  "How do I enter a new line?\n" +
  "```Usually, control+enter```\n\n" +
  "I am frustrated by the use of new lines. Is there another way?\n" +
  "```You may separate the fields with a pipe | symbol. It's usually above the enter/return button of your keyboard.```\n\n" +
  "I love how automated this channel is! How did you do able to make that?\n" +
  "```The bots did these but we program the bots. You may check our works at https://github.com/phillydev```\n\n" +
  "Can I contribute to its development?\n" +
  "```Sure! Pitch your ideas, translate them into 0's and 1's and just submit a pull request.```\n\n" +
  "Is there a way to revisit back where the formatting guidelines are displayed?\n" +
  "```Message [intro] excluding the enclosing brackets here```\n\n" +
  "What if I have a question but it is not answered here?\n" +
  "```Let's discuss at #meta```"

commandList = "`intro` - Sends you a direct message for the introductory guide for this channel.\n\n" +
  "`faqs` - Sends you a direct message for a list of frequently asked questions related to this channel."

privileged = (slack) -> slack.is_admin or slack.is_owner or slack.is_primary_owner

processChannelCommands = (robot) ->
  robot.hear /intro/i, (res) ->
    if res.message.rawMessage.thread_ts?
      return
    switch res.message.rawMessage.channel
      when process.env.JOB_POSTING_CHANNEL
        dmUserSilently(res.message.user.id, "I have sent you a direct message.")
        dmUserDirectly(res.message.user.id, welcomeMessage)

  robot.hear /faqs/i, (res) ->
    if res.message.rawMessage.thread_ts?
      return
    switch res.message.rawMessage.channel
      when process.env.JOB_POSTING_CHANNEL
        dmUserSilently(res.message.user.id, "I have sent you a direct message.")
        dmUserDirectly(res.message.user.id, tipsTldr)

  robot.hear /commands/i, (res) ->
    if res.message.rawMessage.thread_ts?
      return
    switch res.message.rawMessage.channel
      when process.env.JOB_POSTING_CHANNEL
        dmUserSilently(res.message.user.id, commandList, false)

  robot.hear /test/i, (res) ->
    if res.message.rawMessage.thread_ts?
      return
    switch res.message.rawMessage.channel
      when process.env.JOB_POSTING_CHANNEL
        dmUserSilently(res.message.user.id, "It works!", false)

dmUserSilently = (user, msg, greet = true) ->
  robot.http("https://slack.com/api/chat.postEphemeral")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query
      token: process.env.HUBOT_SLACK_TOKEN
      channel: process.env.JOB_POSTING_CHANNEL
      user: user
      text: "#{if greet then "Hi <@#{user}>! " else ""}#{msg}"
  .post()()

dmUserDirectly = (user, msg) ->
  robot.http("https://slack.com/api/chat.postMessage")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query
      token: process.env.HUBOT_SLACK_TOKEN
      channel: user
      as_user: false
      text: msg
  .post()()

deletePrevMessage = (ts) ->
  robot.http("https://slack.com/api/chat.delete")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query
      token: process.env.JANITOR_USER_TOKEN
      channel: process.env.JOB_POSTING_CHANNEL
      ts: ts
      as_user: true
  .post()()

reformatJobPosting = (msgId, title, description, company, approxCompanyLink, location, payrange, link) ->
  robot.http("https://slack.com/api/chat.update")
  .header('Authorization', "Bearer #{process.env.HUBOT_SLACK_TOKEN}")
  .header('Content-Type', 'application/json')
  .query
      token: process.env.JANITOR_USER_TOKEN
      channel: process.env.JOB_POSTING_CHANNEL
      ts: msgId
      text: " "
      attachments: JSON.stringify [
        color: "#36a64f"
        title: title
        text: description
        author_name: company
        author_link: approxCompanyLink
        fields: [
          {title: "Location", value: "<https://www.google.com/maps?q=#{company}+#{location}|#{location}>", short: true},
          {title: "Pay range", value: "<https://www.google.com/search?q=#{title}+average+salary&btnI|#{payrange}>", short: true}
        ]
        actions: [
          {type: "button", text: ":books: Learn more...", url: link, style: "primary", "unfurl_links": false, "unfurl_media": false}
        ]
        "unfurl_links": false
        "unfurl_media": false
      ]
  .post()()

module.exports.jobDescriptionFormat = jobDescriptionFormat
module.exports.politeMessageToRecruiter= politeMessageToRecruiter
module.exports.welcomeMessage = welcomeMessage
module.exports.tipsTldr = tipsTldr
module.exports.commandList = commandList
module.exports.privileged = privileged
module.exports.processChannelCommands = processChannelCommands
module.exports.dmUserSilently = dmUserSilently
module.exports.dmUserDirectly = dmUserDirectly
module.exports.deletePrevMessage = deletePrevMessage
module.exports.reformatJobPosting = reformatJobPosting
