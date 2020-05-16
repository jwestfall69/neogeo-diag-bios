# Watchdog Stuck Test
---

This test will identify if the board is stuck rebooting over and over because
of the watchdog.  Details about the [watchdog](https://wiki.neogeodev.org/index.php?title=Watchdog)
can be found on the [Neo-Geo Dev Wiki](https://wiki.neogeodev.org/index.php?title=Main_Page),
but the short is that if the watchdog isn't kicked every ~128ms it will cause
the board/cpu to reset.  This is often referred to as the click of death.

This tests consists of the printing the following on the screen

```
WATCHDOG DELAY...

IF THIS TEXT REMAINS HERE...
THEN SYSTEM IS STUCK IN WATCHDOG
```

Then looping for ~128ms kicking the watchdog.  If kicking the watchdog isn't
actually kicking the watchdog it will trigger a reset.  This will repeat over
and over allowing you to see the above text.  This test happens fast enough
that if it isn't an issue you likely won't even see the above text as it gets
cleared soon as the test is done.
