# Description:
#   Simple robot to provide communication with F5 iControl declarative interfaces via the F5 iWorkflow platform
#   Maintainer:
#   @npearce
#   http://github/com/npearce
#
# Notes:
#   Tested against iWorkflow v2.2.0 on AWS
#   Running on Docker container/alpine linux
#

module.exports = (robot) ->

  iapps = require "../iApps/iApps.json" # iApps and Service Templates available to install.
  DEBUG = false # [true|false] enable per '*.coffee' file.
  OPTIONS = rejectUnauthorized: false # ignore HTTPS reqiuest self-signed certs notices/errors


  robot.respond /(list|show) devices/i, (res) ->

    IWF_ADDR = robot.brain.get('IWF_ADDR')
    IWF_USERNAME = robot.brain.get('IWF_USERNAME')
    IWF_TOKEN = robot.brain.get('IWF_TOKEN')
    IWF_ROLE = robot.brain.get('IWF_ROLE')

    if IWF_ROLE is "Administrator"

      robot.http("https://#{IWF_ADDR}/mgmt/shared/resolver/device-groups/cm-cloud-managed-devices/devices/", OPTIONS)
        .headers('X-F5-Auth-Token': IWF_TOKEN, 'Accept': "application/json")
        .get() (err, resp, body) ->

          # Handle error
          if err
            res.reply "Encountered an error :( #{err}"
            return

          if resp.statusCode isnt 200
            if DEBUG
              console.log "resp.statusCode: #{resp.statusCode} - #{resp.statusMessage}"
              console.log "body.code: #{body.code} body.message: #{body.message} "
            jp_body = JSON.parse body
            res.reply "Something went wrong :( #{jp_body.code} - #{jp_body.message}"
            return

          try
            if DEBUG then console.log "body: #{body}"
            jp_body = JSON.parse body

            if jp_body.items.length < 1
              res.reply "Sorry, no devices...!"
              return

            else
              # Iterate through the devices.
              for i of jp_body.items
                DEVICE_HOSTNAME = jp_body.items[i].hostname
                DEVICE_UUID = jp_body.items[i].uuid
                DEVICE_VERSION = jp_body.items[i].version
                res.reply "Device #{i}: #{DEVICE_HOSTNAME} - #{DEVICE_VERSION} - #{DEVICE_UUID}"

          catch error
           res.send "Ran into an error parsing JSON :("
           return
