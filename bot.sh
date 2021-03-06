#!/bin/bash
# This section is mostly the same as the Newbrict version, except for bits that I found to be annoying... especially the syntax for bot commands.

. bot.properties
input=".bot.cfg"
# remove the space between "Starting session: $(date "+[%y:%m:%d %T]")" and # >$log to enable logging startups
echo "Starting session: $(date "+[%y:%m:%d %T]")"
# >$log 
echo "NICK $nick" > $input 
echo "USER $user" >> $input
echo "JOIN #$channel" >> $input
 
tail -f $input | telnet $server 6667 | while read res
do
  # log the session (uncomment to enable logging)
  ### echo "$(date "+[%y:%m:%d %T]")$res" >> $log
  # do things when you see output
  case "$res" in
    # respond to ping requests from the server
    PING*)
      echo "$res" | sed "s/I/O/" >> $input 
    ;;
    # for pings on nick/user
    *"You have not"*)
      echo "JOIN #$channel" >> $input
    ;;
    # run when someone joins
    *JOIN*) who=$(echo "$res" | perl -pe "s/:(.*)\!.*@.*/\1/")
      if [ "$who" = "$nick" ]
      then
       continue 
      fi
    ;;
    # run when a message is seen
    *PRIVMSG*)
      echo "$res"
      who=$(echo "$res" | perl -pe "s/:(.*)\!.*@.*/\1/")
      from=$(echo "$res" | perl -pe "s/.*PRIVMSG (.*[#]?([a-zA-Z]|\-)*) :.*/\1/")
      # "#" would mean it's a channel
      if [ "$(echo "$from" | grep '#')" ]
      then
        test "$(echo "$res" | grep "PRIVMSG #$channel :~")" || continue
        will=$(echo "$res" | perl -pe "s/.*$channel :~(.*)/\1/")
      else
        will=$(echo "$res" | perl -pe "s/.*$nick :~(.*)/\1/")
        from=$who
      fi
      will=$(echo "$will" | perl -pe "s/^ //")
      com=$(echo "$will" | cut -d " " -f1)
      if [ -z "$(ls modules/ | grep -i -- "$com")" ]
      then
        ./modules/help/help.sh $who $from >> $input
        continue
      fi
      ./modules/$com/$com.sh $who $from $(echo "$will" | cut -d " " -f2-99) >> $input
    ;;
    *)
      echo "$res"
    ;;
  esac 
done
