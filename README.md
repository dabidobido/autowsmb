#Auto WS and MB
1.4.0:
- Added maxtp command. 

1.3.6:
- Update readme and help text to reflect that need to specify a ws for amlvl command
- Update ws delay for puppet's ws

1.3.5:
- Fix fastcast not saving to config file
- Fix nil value when using ws with no skillchain property

1.3.4:
- Add fastcast to config file.
- Don't open ws until mb window is closed if mb has been started.

1.3.3:
- Fix amlvl command not accepting multi-word ws names

1.3.2:
- Add mbstep setting to status printout

1.3.1:
- Added skillchain level 4 to setsclvl

1.3.0:
- Added function to MB only when the skillchain is at a certain step or above.

1.2.2:
- fixed using the wrong weapon skill when the first element of the weapon skill creates a skillchain of lower level than desired. (E.g Sniper Shot -> King's Justice trying for distortion when it would actually make scission)

1.2.1:
- amlvl to support relic aftermath. Set lvl to 1 to maintain relic aftermath.

1.2.0:
- Changed am3 command to amlvl.
- Removed buffer time for AM3 maintenance.

1.1.0:
- Add support for SMN bloodpacts and BST ready moves for skillchains. For BST, assumes max ready recast reduction.

1.0.1:
- Add support for job ability magic burst. Mostly used for SMN blood pacts and BST ready moves.

1.0.0:
- Add aeonic support. Only works for player, doesn't work for others.

0.0.15:
- Fix compile error

0.0.14:
- Removed mb delay, added fastcast value to replace. Calculate delay from fastcast value. Use //awsmb fastcast (0-80) to set.
- Leave buffer time to get tp without ws when maintaining AM3. Currently this is 10 secs.
- Added status command to print current configuration to chat.
- Removed startmb amd stopmb commands.
- Changed start command to start both ws and mb. Use //awsmb start (mb/ws) to start only mb or ws.

0.0.13:
- Add functionality not to do anything for 20 secs after getting double up buff so that other addons like roller can do their thing

0.0.12:
- Changed spell priority to include hp% threshold.
- Changed magic burst behaviour to check if the second cast would burst instead of trying to cast it anyway
- Added seperate AM3 ws
- Added some self target ws and non skillchain ws

0.0.11:
- Fixed issue some skillchains being mistaken for double light/dark
- Fixed issue with skillchains not being target specific
- Fixed issue with magic bursting not working if it was enabled when skillchains were not started
- Fixed some debug issues

0.0.10:
- Fix bug with not recognizing double light/dark if it was only 2 step SC
- Added AM3 maintenance function
- Added spam mode for zerg situations like Mireu
- Only stop autowsmb on first zoning, not every zoning

0.0.9:
- Add a WS Spam mode where it doesn't care about SC
- Fix bug with needing at least 2 spells to parse

0.0.8:
- Fix issue with using ws immediately and not waiting for skillchain window 

0.0.7:
- Really fix the logic issue with not opening with ws immediately if cannot continue skillchain

0.0.6:
- Fix logic issue with not opening with ws immediately if cannot continue skillchain

0.0.5:
- Fix logic issue with opening with ws when not being able to continue skillchain even though don't open was set

0.0.4:
- Fix logic issue with not wsing even though not being able to continue skillchain

0.0.3: 
- Changed settings file structure to be able to save settings by job. ***Please delete the previous settings file.***
- Added mb functionality.
- Added function to only try to skill chain without using open ws.

0.0.2: 
- Added skillchain timing and don't try and continue double dark/light skillchains

0.0.1: 
- Auto ws and try to skillchain

# How it works

Use //autowsmb or //awsmb

## //awsmb start (ws/mb)

Starts auto ws/mb. Both if argument is omitted.

## //awsmb stop (ws/mb)

Stops auto ws/mb. Both if argument is omitted.

## //awsmb dontopen

Don't use open ws, only try to skill chain.

## //awsmb open: 

Use open ws.
		
## //awsmb setopenws (name,tp)

Set the name of ws to open with and the minimum tp to use the ws.

## //awsmb setwspriority ((name,tp,name,tp,...)

Set the name of ws and tp of ws to try to skillchain with. will try to make skillchains in the order of input.

## //awsmb setsclevel (1-4)

Will only try to skillchain and make skillchains of the level set here or above.

## //awsmb setspellpriority (spell_name,hpp,spell_name,hpp,...)

Sets priority for spells to burst with. Will go in order of input and check elements. Hpp is amount of Hpp (HP percent) mob must have in order for spell to be used. Set to 0 for always use.

## //awsmb spam (on/off) 

Starts/Stops spamming opener ws

## //awsmb amlvl (0-3, ws_name)

Holds TP to trigger aftermath. Set to 0 to disable. 1-3 will trigger AM level 1-3. Use 1 for relic aftermath.

## //awsmb fastcast (0-80) 

Sets fastcast value for mb recast calculation. Default 80.

## //awsmb mbstep (number 1+)

MB only after skillchain has reached a specific step. Default 1.

## //awsmb maxtp (on/off)

Toggles Max TP Mode. In Max TP Mode, will hold tp until the value specified in setwspriority or setopenws commands, or hold until there is less than 2 second sleft in the skillchain window.

E.g Setting Rudra's Storm,3000 will only use Rudra's Storm when you have 3000 TP or when there are less than 2 seconds left in the skillchain window.

## //awsmb status:

Prints current configuration to chatlog.

## SC Example

1. //awsmb setopenws Primal Rend,1750
2. //awsmb setwspriority Decimation,1000,Cloudsplitter,1750
3. //awsmb setsclevel 2

Now, in this example, this will start with Primal Rend at 1750TP, then go to Cloudsplitter at 1750TP since there is no level 2 SC with Decimation from Primal Rend. After Cloudsplitter, this will then do Decimation at 1000TP to do a 3-step Light SC.

But if Noillurie is in the party, if she does Tachi: Kaiten, this will wait for the skillchain window and do Decimation to 2-step Light. Or if this does Primal Rend and Noillurie does Tachi: Kaiten for a Fragmentation skillchain, this will then do Decimation for a 3-step Light.

## MB Example

1. //awsmb setspellpriority fire vi,50,thunder vi,50,water vi,50,fire v,40,blizzard iii,30

When there is a liquefaction skillchain, will try to burst Fire VI and Fire V after casting Fire VI + 3 seconds. Use //awsmb fastcast (value) to set your fastcast value so that the casting time can be calculated correctly.