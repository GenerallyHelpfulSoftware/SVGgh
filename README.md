**SVGgh** *an SVG Rendering Library for iOS*
-
Author [Glenn R. Howes](mailto:grhowes@mac.com), *owner [Generally Helpful Software](http://genhelp.com)*

### Introduction
In my own apps, I've often wished to avoid using bitmapped images for my interface elements. Often, I'll need to add PNG files for Retina, and non-retina, iPhone and iPad, and find myself confined to what I can do with an interface in terms of stretching elements. And all this artwork made my app bulky. So, I decided to implement an SVG renderer which could use standard **Scalable Vector Graphics** documents to draw button icons, background art or whatever my art needs were. I have Apps in the App Store like [SVG Paths](http://AppStore.com/SVGPaths) whose only PNG files are the required icons. 

### Features
Handles shapes quite well such as paths, ellipses, circles, rectangles, polygons, polylines, and arcs with all the standard style attributes. Implements basic text and font handling, including rough text along a path. Implements both linear and radial gradients, including applying gradients to strokes and text. Implements scale invariant line widths. Provides both a static UIView subclass and a UIControl subclass button. Both are configurable from either nib or storyboards. Supports embedded bitmap images in standard formats. 

### Limitations
The entire [SVG specification](http://www.w3.org/TR/SVG11/) is not implemented. Right now, it only implements the portions of the specification I needed or thought I might need. In particular, it doesn't support SVG fonts, animation, Javascript, or effects. Also, some attributes remain unimplemented or partially implemented, for example the *width* attribute of an *svg* entity cannot be expressed as a percentage. I hope users of this library will contribute back implementations of at least some of these. 

There are undoubtably bugs but I've used this library in all 6 apps I have in the App Store without issue so it is reasonably stable. Also, I would not label this a high performance renderer although I've never had cause to complain about it in the way I use it. 

The included library assumes ARC style memory management. It's also been arbitrarily set to support iOS 6 and up. The code would likely run on iOS 5 and up, but I'm not supporting that going forward. 

Because I'm intending on allowing this to be used as a static library, I'm avoiding the use of **categories** in my Objective-C code in order to avoid the use of the **-ObjC** other linker flag. For example, I'd normally have declared a SVGRender+Printing category when I implemented printing.

### As a Black Box Library
If you just want to use the code in your app and are uninterested in the underlying engine, the included Xcode project generates a static library (**SVGgh**) with the following public headers. By the way, the reason that classes tend to have a GH (Generally Helpful, or Glenn Howes) prefix is not narcissism, but an attempt of getting around the lack of a namespace in plain Objective-C.
* SVGDocumentView.h *A simple UIView capable of displaying a SVG document*
* GHButton.h *A flexible UIControl capable of having an embedded SVG document as an icon*
* SVGParser.h *A class to load .svg files*
* SVGRenderer.h *A class to render SVG documents into a CGContextRef*
* GHControlFactory.h *A singleton class devoted to be a central location for widget theme look*
* GHImageCache.h *A singleton class devoted to caching and loading bitmap images*
* SVGToPDFConverter.h A class to convert the renderer's contents to a PDF.
* SVGPrinter.h A class to send a renderer's contents to a printer.

To compile the static library. 
* Load the included **SVGgh.xcodeproj** project in Xcode 5 or above 
* **Build** the **Framework** target.
* **Right Click** on the **libSVGgh.a** item in the **Products** folder
* Select **Show in Finder**
* Locate the **SVGgh.framework** framework
* Drag the framework into your own Xcode project

To use, you'll want to follow the following steps:
* Add the **SVGgh** library to your Xcode project.
* \#include &lt;SVGgh/SVGgh.h&gt;
* early in the launch of your app call 
    **[ControlFactory kColorSchemeClear];**
* early in the launch of your app call
**MakeSureSVGghLinks();** in order to link classes only referenced in storyboards or nibs. As in:

````
#import <SVGgh/SVGgh.h>

@implementation YourAppDelegate

+(void) initialize
{
    [super initialize];
    MakeSureSVGghLinks(); // classes only used in Storyboards might not link otherwise
    [GHControlFactory setDefaultScheme:kColorSchemeClear];
}
...
````

To add a button to a .xib file or storyboard:
* Drag a UIView into your view
* In the **Identity Inspector** give it a **Custom Class** name of **GHButton**
* Also in the **Identity Inspector** give it **User Defined Attributes**

| Key Path | Type | Value |
| -------- | ---- | ----- |
| artworkPath | String | Artwork/MenuButton (assumes you have such an asset) |
| schemeNumber | Number | 3 |


* Note that the **.svg** extension is assumed
* or if you are making a text button:

| Key Path | Type | Value |
| -------- | ---- | ----- |
| title | Localized String | My Label |
| schemeNumber | Number | 3 |

To add a static view to a .xib file or storyboard:
* Drag a UIView into your view
* In the **Identity Inspector** give it a **Custom Class** name of **SVGDocumentView**
* Also in the **Identity Inspector** give it **User Defined Attributes**

| Key Path | Type | Value |
| -------- | ---- | ----- |
| artworkPath | String | Artwork/MyBackground |

* Note that the **.svg** extension is assumed
* You should likely open the **Attributes Inspector** tab and set the **Mode** to **Aspect Fit** or possibly **Aspect Fill**.
	
#### Hints
* I like adding an Artwork folder to my target added as a 'Folder Reference' so that I can just drop things in from the Finder and they'll be added. Folder references show up in Xcode as blue folders.
* SVG has the ability to localize content as in the following fragment which localizes to Chinese:

```
<switch>
	<g systemLanguage ="zh">
		<text x="24" y="20" font-family="Helvetica" font-size="22"  fill="grey">绝对直线</text>
		<text x="218" y="95" font-family="Helvetica" font-style="italic" font-size="20" text-anchor="end" fill="blue">终点 x, y</text>
	</g>
	<g>
		<text x="24" y="20" font-family="Helvetica" font-size="22"  fill="grey">line to</text>
		<text x="218" y="95" font-family="Helvetica" font-style="italic" font-size="20" text-anchor="end" fill="blue">end x, y</text>
	</g>
</switch>
```	
* I've provided an Example.xcodeproj which displays an SVG in a view and displays a sharing button. 

### Under the Hood
If you are inclined to fix bugs or add features, and please do, then you'll be interested in the general mechanism by which an SVG document is converted to an onscreen image.     

The starting point is the **SVGRenderer**, which as a subclass of **SVGParser** is capable of loading in the XML of an SVG document and being used to render into a Core Graphics context (a CGContextRef).  The parser takes the XML and converts it to a tree composed of NSDictionaries and NSArrays of NSDictionaries. The NSDictionary at the root of this tree is used to create an **GHShapeGroup** which starts the process of building up a tree of **SVGAttributedObject**s, each of which knows how to render themselves. In general, when sending a message to an SVGAttributedObject, an object which implements the **SVGContext** protocol is provided so that certain state information is available to the SVGAttributedObject such as the currentColor or a method to look up the document tree for either a named object or an attribute defined by a parent. 

I've gone through and added Doxygen style comments to all the header files, so there is some hope of finding your way. 

### Attribution
While the vast majority of the code in this first release was written by me. There are a couple of classes or categories that were found online but have a flexible enough license for me to include here.
* Jonathan Wight wrote a Base64 Transcoder which I found quite useful for handling embedded images.
* Ian Baird wrote a category for NSData for Base64 which I also found very easy to use. 
* [Jeff Verkoeyen] (https://github.com/jverkoey/iOS-Framework) provided the instructions for building a static library. Be sure to set **Build Active Architecture Only** to **NO**
