# Disclose if recruiter. Respond in thread. Repost 1/mo.
#
# Company | Location | Pay range | Job Title | Tweet size description | Link

{
  jobDescriptionFormat
  dmUserSilently, deletePrevMessage, dmUserDirectly
  processChannelCommands, privileged, reformatJobPosting
  welcomeMessage,
} = require "../script-helpers/job-postings"

module.exports = (robot) ->

  # Let's welcome the newly joined user in #job-postings! Give them the welcome message
  # which includes the guidelines on how to better enhance their user experience when
  # posting or applying for job opportunities.
  #
  # Note that this is an ephemeral message to the user in the channel, not a direct
  # message
  robot.adapter.client.on "raw_message", (message) ->
    if message.subtype is "channel_join" and message.channel is process.env.JOB_POSTING_CHANNEL
      dmUserSilently(message.user, welcomeMessage)

  processChannelCommands robot

  robot.hear /.*/i, (res) ->

    # If this message is not in #job-postings channel, we should not process this message
    # and allow it to proceed to where it's being sent unless that channel has been
    # programmed with similar rules like this
    if res.message.rawMessage.channel is not process.env.JOB_POSTING_CHANNEL
      return

    msgId = res.message.id
    userId = res.message.user.id

    # Allow thread replies to the posting
    if res.message.rawMessage.reply_broadcast? and not privileged res.message.user.slack
      deletePrevMessage msgId
      dmUserSilently(userId, "Currently, we do not allow broadcasting replies in this channel.")
      return

    # We shall allow thread replies
    if res.message.rawMessage.thread_ts?
      return

    # Allow users to explore the bot's functionality
    if res.message.match /(faqs|intro|commands|test)/i
      deletePrevMessage res.message.id
      return

    # Theoretically, one word is a valid job posting format because one word message
    # is processed as a command. However, commands are never posted in the public
    # chat and they are announced as an ephemeral message which means a message that
    # is only visible to you in slack.
    if res.message.match /^ *([a-zA-Z0-9_]+)\b *$/i
      deletePrevMessage msgId
      dmUserSilently(userId, "Unknown command: #{res.message.text}\n Message 'commands' for usage.", false)
      return

    # The heart of the #job-postings. This is how the bot should police in the channel.
    # Have you ever heard the term in lean manufacturing "poke-yoke"? It is simply a
    # terminology in lean that basically means "fool-proof". And this bot is designed
    # to keep the idiots from doing wrong without shaming them by the majority of
    # philly dev. Peace be with all of us"
    if not res.message.match jobDescriptionFormat

      # We'll provide a way to have the admins post without restriction.
      #
      # However, one word commands (even though if they contain whitespaces beside of it)
      # are processed and are not announced. To prevent that, the admin should
      # add at least one word after the first word. For example, test hello world.
      if privileged res.message.user.slack
        return

      # We are proud to live in the city of brotherly love so don't publicly shame them.
      # Instead, send a direct message to the poster that the job posting did not meet
      # the correct formatting to post in the channel. Let them feel that they are still
      # welcome to post and give them instructions on how to fix it.
      deletePrevMessage msgId
      dmUserSilently(res.message.user.id, "Unfortunately, your job posting has been " +
          "rejected here. I have sent you a direct message to explain the reasons " +
          "and how you should fix it. We apologize for this.")
      dmUserDirectly(userId, politeMessageToRecruiter(res.message.text))

    else

      # This is the code block where the job posting passed the bot's vetting mechanism.
      # In short, the job posting is a valid job posting in the #job-postings channel.
      # Let's attempt to finalize everything before we thank the poster for abiding the
      # rules.

      extracts = res.message.match jobDescriptionFormat

      company = extracts[1]
      location = extracts[2]
      payrange = extracts[3]
      title = extracts[4]
      description = extracts[5]
      link = extracts[6]

      # Assuming that the poster supplied an actual company name with no typos,
      # we'll heuristically guess the link to the company website using Google
      # search's "I'm feeling lucky"
      approxCompanyLink = "https://www.google.com/search?q=#{company}+careers&btnI"

      # You are very welcome. Or maybe not?
      #
      # To help the community attract those postings that came with a lot of effort from
      # recruiters who formatted their postings to the right way, we'll add a little bit
      # of extra formatting so that it will be easy to read and to better enhance the
      # experience of job seekers.
      #
      # This last step is the icing of the cake
      reformatJobPosting(msgId, title, description, company, approxCompanyLink, location, payrange, link)

      # And with a cherry on top. Show a sign of gratitude to the poster who abide
      # the rules.
      #
      # We just simply react with a check mark in a green box to the poster
      robot.emit 'slack.reaction',
        message: res.message
        name: 'white_check_mark'
