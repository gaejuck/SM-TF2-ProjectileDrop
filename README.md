# SM-TF2-ProjectileDrop
## What is it?
This plugin adds two attributes using NoSoop's [TF2 Custom Attribute Framework](https://github.com/nosoop/SM-TFCustAttr).

## Attributes
Specifically, it adds the `rocket launch` and `rocket drop` attributes, both of these can be applied to any weapon that fires standard Rocket Launcher-type rockets, Cow Mangler rockets or Righteous Bison projectiles.

`rocket launch` applies the rockets launched from any weapon with the attribute an increase to how quickly it moves up, measured at a rate of hammer units per second.
The default Rocket Launcher moves at a rate of 1,100 hammer units a second, so setting this value to 1,100 will make the rockets go at a nice 45 degree angle relative to where ever the player is facing.

`rocket drop` applies a downward force every server tick (so 66.7 times a second), measured at a rate of hammer units a second, multiplied by 0.1.

For testing, I'd recommend trying a `rocket launch` value of 250 and a `rocket drop` value of 100, that should give you a good feel for how these numbers make a difference.

## How do I install it?
This plugin has no additional requirements beyond NoSoop's [TF2 Custom Attribute Framework](https://github.com/nosoop/SM-TFCustAttr) (and everything that requires of course).
If you want to test the attributes without using a custom weapons plugin, try using the `sm_custattr_add` command in your client console, like this:
`sm_custattr_add "rocket launch" "250" ; sm_custattr_add "rocket drop" "100"`

## Finishing off
This is actually my second plugin ever written, I'm actually amazed that *somehow* this thing is functional, I'd welcome any suggestions for how I can improve it.

If you'd like to see this plugin in action, well, I don't have anything to share, but you can see the [video which was my inspiration](https://youtu.be/7RtjkCMmZxY).
