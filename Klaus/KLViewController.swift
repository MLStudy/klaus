/**********************************************************
* Klaus, A state-of-the-art Classifier on iOS
* Liu Liu, 2014-08-06
**********************************************************/

import UIKit

class KLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

  var _classifier: KLHierarchicalClassifier! = nil
  var _classificationHierarchy: KLClassificationHierarchy! = nil
  var _imageView: UIImageView! = nil
  var _moreButton: UIButton! = nil
  var _takeButton: UIButton! = nil
  var _indexer: KLAssetsLibraryIndexer! = nil
  var _textView: UITextView! = nil
  var _busy = false
    
  let imagePicker = UIImagePickerController()
    var imageView: UIImageView! = nil

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = UIColor.whiteColor()
    _imageView = UIImageView(frame: CGRectMake(0, 22, CGRectGetWidth(self.view.bounds), CGRectGetWidth(self.view.bounds)*0.8))
    _imageView.backgroundColor = UIColor.lightGrayColor()
    
    _moreButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    _moreButton.frame = CGRectMake((CGRectGetWidth(self.view.bounds) - 260) / 2, CGRectGetMaxY(_imageView.frame) + 20, 120, 32)
    _moreButton.setTitle("Select Photo", forState: UIControlState.Normal)
    _moreButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    _moreButton.backgroundColor = UIColor(red: 42.0/255, green: 161.0/255, blue: 152.0/255, alpha: 1)
    _moreButton.addTarget(self, action: "didTapMore:", forControlEvents: UIControlEvents.TouchUpInside)
    
    _takeButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    let s = CGRectGetWidth(self.view.bounds) - ((CGRectGetWidth(self.view.bounds) - 260) / 2) - 120
    _takeButton.frame = CGRectMake(s, CGRectGetMaxY(_imageView.frame) + 20, 120, 32)
    _takeButton.setTitle("Take Photo", forState: UIControlState.Normal)
    _takeButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    _takeButton.backgroundColor = UIColor(red: 42.0/255, green: 161.0/255, blue: 152.0/255, alpha: 1)
    _takeButton.addTarget(self, action: "takePhoto:", forControlEvents: UIControlEvents.TouchUpInside)
    
    _textView = UITextView(frame: CGRectMake(5, CGRectGetMaxY(_moreButton.frame) + 10, CGRectGetWidth(self.view.bounds) - 10, CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(_moreButton.frame) - 10))
    _textView.font = UIFont.systemFontOfSize(14)
    _textView.textColor = UIColor(red: 0, green: 43.0/255, blue: 54.0/255, alpha: 1)
    _textView.text = "waiting"
//    _textView.textAlignment = NSTextAlignment.Center
    _textView.textAlignment = NSTextAlignment.Natural
    
    self.view.addSubview(_imageView)
    self.view.addSubview(_moreButton)
    self.view.addSubview(_takeButton)
    self.view.addSubview(_textView)
    
//    picker.delegate = self

    // start classifier
    _classifier = KLHierarchicalClassifier()
    let wnid = NSBundle.mainBundle().URLForResource("image-net-2012", withExtension: "wnid", subdirectory: "ccvResources")
    let synsets = NSBundle.mainBundle().URLForResource("image-net-2012", withExtension: "xml", subdirectory: "ccvResources")
    _classificationHierarchy = KLClassificationHierarchy(WNID: wnid, synsets: synsets)
    _indexer = KLAssetsLibraryIndexer()
    _indexer.startWithCompletionHandler({
      dispatch_async(dispatch_get_main_queue(), {
//        self._textView.text = "analyzing of \(self._indexer.cursor + 1)"
        self._textView.text = "analyzing..."
        println(self._indexer.nextAvailableAssetsURL())
//        self.runClassificationWithURL(self._indexer.nextAvailableAssetsURL())
      })
    })
  }
  
    func runClassificationWithImage(fullScreenImage: CGImage!){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            let width = CGImageGetWidth(fullScreenImage)
            let height = CGImageGetHeight(fullScreenImage)
            let minDim = min(width, height)
            let center = CGImageCreateWithImageInRect(fullScreenImage, CGRectMake(CGFloat(width - minDim) / 2, CGFloat(height - minDim) / 2, CGFloat(minDim), CGFloat(minDim)))
            // crop and then display
            let image = UIImage(CGImage: center)
            let tick = KLTickCount()
            let classificationResult = self._classifier.classify(fullScreenImage) as! [KLClassificationResult]
            let elapsedTime = UInt(tick.toc() * 1000 + 0.5)
            dispatch_async(dispatch_get_main_queue(), {
                self._imageView.image = image
                self._imageView.contentMode = .ScaleAspectFit
                var text: String = "analyzed in \(elapsedTime)ms\n"
                
                for (index, result: KLClassificationResult) in enumerate(classificationResult) {
                    var synset = self._classificationHierarchy.synset(result.id)
                    var line = "\(index+1): \(synset.words)"
                    //          synset = synset.hypernym
                    //          while synset.hypernym != nil {
                    //            line = "\(synset.words)"
                    //            synset = synset.hypernym
                    //          }
                    text += "\(line) \t:\(result.confidence*100)%\n"
                    //          text += "\(result.id): confidence:\(result.confidence)\n"
                }
                self._textView.text = text
                self._busy = false
            })
        })
    }
    
  func runClassificationWithAsset(asset: ALAsset) {
    let fullScreenImage = asset.defaultRepresentation().fullScreenImage().takeUnretainedValue()
    runClassificationWithImage(fullScreenImage)

  }

  func runClassificationWithURL(assetURL: NSURL) {
    _busy = true
    let library = ALAssetsLibrary()
    library.assetForURL(assetURL, resultBlock: {
      asset in
      self.runClassificationWithAsset(asset)
    }, failureBlock: {
      error in
    })
  }
  
 
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        
        imagePicker.dismissViewControllerAnimated(true, completion: nil)
        
        println("ssss")
        println(info)
        
        
        if imagePicker.sourceType == UIImagePickerControllerSourceType.SavedPhotosAlbum {
            let imageURL = info[UIImagePickerControllerReferenceURL] as! NSURL
            println(imageURL)
            runClassificationWithURL(imageURL)
        } else {
            var image = info[UIImagePickerControllerOriginalImage] as? UIImage
            runClassificationWithImage(image!.CGImage)
        }


    }
    
  func didTapMore(sender: UIButton!) {
    if _busy {
      return
    }
//    let assetURL = _indexer.nextAvailableAssetsURL()
   
    
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.SavedPhotosAlbum){
        println("Select Photo")
        
        
        imagePicker.delegate = self
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum;
        imagePicker.allowsEditing = false
        
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
//    picker.allowsEditing = false //2
//    picker.sourceType = .PhotoLibrary //3
//    presentViewController(picker, animated: true, completion: nil)//4
    
//    if assetURL != nil {
//      _textView.text = "analyzing of \(_indexer.cursor)"
//      runClassificationWithURL(assetURL!)
//    }
  }

    func takePhoto(sender: UIButton!) {
        if _busy {
            return
        }
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera){
            println("Take Photo")
            
            
            imagePicker.delegate = self
            imagePicker.sourceType = UIImagePickerControllerSourceType.Camera;
            imagePicker.allowsEditing = false
            
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
////        imagePicker =  UIImagePickerController()
//        imagePicker.delegate = self
//        imagePicker.sourceType = .Camera
        
        
    }
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }

}

