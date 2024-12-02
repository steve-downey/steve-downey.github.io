<html><body><p>My primary computer is my IBM T20 thinkpad, running <a href="http://www.debian.org/">Debian</a> unstable. It's hooked up to the rest of my home network through a wireless connection. Last week, every thing went south.
<br><br>First, because my wife has been having a lot of trouble getting a good connection to the wireless network from her computer, I upgraded the access port (after futzing around with antennas for a day or so). I put in a new <a href="http://www.linksys.com/products/product.asp?grid=33&amp;scid=35&amp;prid=608">Linksys WAP</a>. One of the cool ones, with <a href="http://www.linksys.com/support/gpl.asp">Linux inside</a>.<span title="Link" onmousedown="CheckFormatting(event);FormatbarButton('richeditorframe', this, 8);ButtonMouseDown(this);"></span>
<br><br>And, I took the opportunity to get a 802.11g PCMCIA card for my laptop.
<br><br>First mistake.
<br><br>No Drivers.
<br><br>I ended up building <a href="http://ndiswrapper.sourceforge.net/">ndiswrapper</a> against <a href="http://packages.debian.org/unstable/base/kernel-image-2.6.8-1-686">2.6.8.1</a>, and using the Windows driver. I'm not thrilled about that, but I do like the increased bandwidth to the real computers upstairs.
<br><br>Then, I did a apt-get dist-upgrade. And got upgraded to kernel 2.6.8.1-3.
<br><br>Which won't suspend properly.
<br><br>The magick keys don't even register, much less do anything. Turns out I'm not the first person to have this <a href="http://bugs.debian.org/cgi-bin/pkgreport.cgi?pkg=kernel-image-2.6.8-1-686">problem,</a> so, I have some hope it will get fixed.
<br><br>I took a stab at upgrading my BIOS to the most recent cut, hoping ACPI would work. It did a little bit, as long as I disabled X DPMS, and was willing to suspend only once before rebooting.
<br><br>I usually leave the laptop running for weeks.
<br><br>So I down graded back to 2.6.7.
<br><br>And realized that I don't have support for the new network card there.
<br><br><sigh><br><br>Windows 2000, on an identical laptop, had been up for 253 days, before I rebooted it to pull the floppy drive to do the BIOS upgrade on this machine.
<br><br>I suppose that's what I get for running unstable.
<br><br>What's worse? It's been <span>_fun_</span>.
<br><br><br><br></sigh></p></body></html>