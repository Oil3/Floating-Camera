* September 2024  
could be named floating "ML" camera  
many changes/additions:  
SwiftUI rework  
Now available throught the right-click context menu :  
togglable floating mode  
can rotate the video feed  
selectable resolution  
selectable fps  
continuous recording:  records continuously, saving at 10 minutes, keeps two recordings, overwriting the oldest  
persistent recording: overwriting is disabled, all recordings are kept  
saved in ~/Library/Containers/com.oil3.Floating-Camera/Data/tmp  
CoreML detection ready  


# Floating-Camera
Floating Camera: always-on-top/picture-in-picture MacOS webcam/iSight/security camera live feed viewer.  
Notarized/hardened/sandboxed

Feb19 new version. Double clicking in the view triggers autofocus and autoexpose at that point.

Cmd+H to hide when selected is functional.


**What is this:** this is is a MacOS app that uses available camera/webcam/iSight/FacetimeHD in order to display the video feed live, full 16/9 view (non-cropped), resizable, always-on-top (picture in picture).  
Native, notarized, sandboxed, hardened, and coded using no dependeny, no external libraries and only the required code.
And no mirror mode.

**How to install?** Move the extracted app in /Applications, or anywhere you choose.

**How to use?** Run the app, its window floats on top of all other windows. Resize by the edges/corners. Field-of-view is non-mirrored, and completly visible, giving 10% more on both sides compared to PhotoBooth.

**How to uninstall?** Delete the app. 

**Download** from Releases.

![image](https://github.com/Oil3/Floating-Camera/assets/22565084/53e444c3-9de2-447f-8d9f-07333c861854)

Our values aim to limit quantity/lines of code to the minimum required amount, with no external library and with minimal (here: none) dependencies: actual executable is 211KB, and 80% of app weight is from its icons.


**Any comment/issue, features, requests are welcome** This is the first release. 
To do:
exposure/contrast/saturation sliders
movement detection
...

Floating Camera was inspired from Chi Won's [FloatingMirror](https://github.com/iamchiwon/FloatingMirror/)

Floating Camera was initially tought to check on _those weird noises_ that I heard downstairs most nights.

Downstairs I have a powerhouse but broken screen macbookpro used via SSH/ARD for  machine learning work. 

FYI Amazingly the noises were from _two cats_ that sneaked in through a window I leave ajar. 
