# Pinch Pad

[Pinch Pad](https://itunes.apple.com/us/app/pinch-pad-post-sketches-to/id999197469?mt=8) is an iOS app designed for making quick sketches and posting them to your social media accounts. In particular, Pinch Pad was built to make it super-simple to do **hourly comics**, where for one full day (or one full month), a person draws a comic for every hour that they are awake.

Features:
* Simple but powerful sketching tools, with intelligent line smoothing
* Seamless integration with Twitter and Tumblr, so you can post your sketches in one tap
* Animation support: draw multiple frames, then post them all as one animated GIF

I've built several different version of this app since I started doing hourly comics in 2011, but this is the first version that's entirely stand-alone, without relying on any server-side components. An official version is available for free on the [App Store](https://itunes.apple.com/us/app/pinch-pad-post-sketches-to/id999197469?mt=8), but you're also more than welcome to play with the source code! To connect to Twitter or Tumblr, you'll need to rename "Configuration.plist.example" to "Configuration.plist", and then supply your own API credentials for those two services.
