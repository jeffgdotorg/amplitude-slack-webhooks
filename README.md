# Amplitude webhooks for Slack

## Purpose
This repo might be useful if:
- Your organization's Slack workspace has not approved the Amplitude app for Slack, and
- You would like to receive Slack messages (in a channel, or as DMs) when a user submits an Amplitude survey

This repo is focused on Net Promoter Score (NPS) surveys, which are easy to work with because they involve a single question whose answer is a single numeric value.
It should be easily adapted to other kinds of Amplitude surveys, and even to almost any kind of Amplitude event besides survey submissions.

## The challenges
### Slack
Slack puts many limitations on the incoming JSON document that gets posted to its webhook endpoints, including:
- May contain at most 20 keys
- May not contain nested hashes like `{ “foo”: { “bar”: “baz” } }`

There’s also no way from the Slack side to see what went wrong when Slack rejects a webhook payload.

### Amplitude
Amplitude’s generic webhook builder is okay, but the learning curve can be steep, and the “Delivery” and “Debugger” tabs in the Amplitude web’s webhook setup section don’t seem that reliable or accurate.
To see what the final webhook payload for a given event looks like, there are a couple of options:
- *Easier*: Configure a destination in the _Data_ section of your Amplitude project, click _Skip & Save_, and use the _Live Log_ tab to inspect the upstream event payload JSON and the downstream webhook payload JSON.
There’s often some pretty helpful information available there.
- *Harder*: Set up a receiver on a public URL that dumps its output (see “A simple Flask app” below)

The default Amplitude event payload is unsuitable for use with a Slack webhook because of the Slack peculiarities outlined above.
To work around that problem, we must configure a custom payload for the Amplitude webhook destination.

Amplitude’s [webhook docs](https://amplitude.com/docs/data/destination-catalog/webhooks#freemarker-templating-language) are helpful, but the big takeaway is that custom payloads require the use of [Apache Freemarker Template Language (FTL)](https://freemarker.apache.org/docs/ref.html).
FTL is full-featured, and the payload editor in the Amplitude web provides some lightweight IDE-like features that can be helpful.

## Use case
### Slack channel pings for Amplitude survey submissions
#### Relevant keys for Guides & Surveys
In my main Amplitude project, the following keys in the webhook JSON payload are relevant:
- `amplitude_id`: The Amplitude ID of the user
- `country`: The user’s (presumably IP-geoed) country
- `event_time`: When the event happened, according to Amplitude
- `event_type`: The name of the event type in Amplitude (e.g. “[Guides-Surveys] Survey Submitted”)

The following sub-keys within the top-level `event_properties` key are very relevant:
- `[Guides-Surveys] Survey Response`: The submitted value (e.g. “10” for a NPS survey)
- `[Guides-Surveys] Title`: Title of the survey, as it appears in the Amplitude web UI
- `[Guides-Surveys] Key`: A slug version of the survey title; utility unclear
- `[Guides-Surveys] Step Title`: Title of the survey step at which the user made the submission
- `[Guides-Surveys] Is Last Step`: Whether the submission happened in the survey’s final step (will be false even if the final step is just an “all done!” confirmation)
- `[Guides-Surveys] Type`: `survey` if it’s a survey; presumably `guide` if it’s a guide
- `[Guides-Surveys] Question UUID`: No idea, but might be useful sometime
- `[Guides-Surveys] App Type`: “web” if submitted from a browser
- `[Guides-Surveys] Page.path`: The path portion of the URL that the user was viewing when they submitted the survey
- `[Guides-Surveys] Page.domain`: The hostname portion of the URL the user was viewing
- `[Guides-Surveys] Page.title`: The <title> of the page the user was viewing

Working with these keys is tricky due to the presence of whitespace and square-bracket characters. 

Interesting sub-keys within the top-level `user_properties` key:
- `internal`: Boolean indicating whether the user is identified as a company internal user
- `isBeta`: Boolean indicating whether the _preview mode_ feature flag is enabled in the user’s session
- `isOrgAdmin`: Boolean indicating whether the user is an organization administrator
- `org_id`: The user’s numeric `org_id`
- `email_domain`: The domain of the email address associated with the user’s platform account

Other interesting properties:
- `group_properties.org_id.{orgIdNumber}.organization_name`: Name of the user’s platform account org

### Example event JSON
- [nps-only-survey-response.json](./examples/amplitude-events/nps-only-survey-response.json) is an actual event payload (what goes into the FTL hopper) from submitting an NPS-only survey in staging. This is useful for feeding to the webhook configurator.

### A simple Flask app to dump webhook payloads
Before I got acclimated to the rhythm required to get value out of Amplitude's _Live Log_ for webhooks, I wrote [a dead simple Python Flask app](./examples/hookdump/) that catches webhook posts and dumps them on stdout.

Host it at a publicly-reachable URL `base_url`, watch its stdout, and configure your Amplitude webhook destination URL as `https://{base_url}/dump`.

The app is **not suitable for production use**.

### Example FTL templates
#### Dump all event and user properties
[dump-all-event-user-props.ftl](./examples/ftl/dump-all-event-user-props.ftl) dumps all event and user properties (with a bonus “assign” example) pulls up every sub-key of `event_properties` and `user_properties` and dumps them into a flat JSON document.  It also illustrates how to use the `<#assign>` directive in FTL to assign a string literal to a variable.

It almost certainly won't work with Slack because the document will have more than the 20 keys permitted by Slack's webhook receiver.

#### Slack-compatible example for NPS survey submissions
[slack-nps-quantitative-only.ftl](./examples/ftl/slack-nps-quantitative-only.ftl) gets the job done for sending survey submissions from an NPS-only survey to a Slack webhook.

The resulting JSON payload that arrives at the Slack webhook endpoint looks something like:
```json
{
  "app": "402983",
  "amplitude_id": "1409826057078",
  "country": "United States",
  "step_title": "How likely are you to recommend us to a friend or co-worker?",
  "survey_response": "10",
  "page_title": "Bonfire | Internal",
  "page_domain": "console.stage.redhat.com",
  "page_path": "/internal/bonfire",
  "email_domain": "redhat.com",
  "org_id": "20008526",
  "organization_name": "Shakespeare Birthplace Trust",
  "isBeta_styled": ":telescope: Preview mode on\n",
  "isOrgAdmin_styled": ":crown: Org. Administrator\n"
}
```

Note: I built the `isBeta_styled` and `isOrgAdmin_styled` properties inside the FTL because Slack didn't want to render boolean values, even if I applied FTL's `toJsonString` builtin. At least this way they have a little bit of character?

### Lingering problems to solve someday™️

Because Amplitude emits a separate event for each question in a multiple-question survey, even if those questions exist within a single step, I haven't found a way to make a single webhook payload that carries both the NPS score and the user's comment (if provided).

I'm handling this inconvenience for now by:
- Filtering the events that get fed to the webhook to ones with a `[Guides-Surveys] Survey Response` property whose value is a member of the set `{ 0 .. 10 }`; this seems to avoid spurious Slack messages containing only the comment value.
- Adding a link to the Slack workflow's message template directing readers to the user's survey submissions in the Amplitude web, where they can find the comment
