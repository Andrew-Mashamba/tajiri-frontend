
import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'profileImage.dart';
import 'tabshome.dart';
import 'waitDialog.dart';
import 'package:video_player/video_player.dart';

import 'HttpService.dart';
import 'DataStore.dart';


class userImagePicker extends StatelessWidget {
  const userImagePicker({super.key});

  @override
  Widget build(BuildContext context) {
    var materialKey;


    return MaterialApp(
      title: '',
      home: MyHomePage(title: 'Chagua au piga picha'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PickedFile? _imageFile;
  dynamic _pickImageError;
  bool isVideo = false;
  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  late File videofiletoUpload;
  late File imagefiletoUpload;

  final List<firebase_storage.UploadTask> _uploadTasks = [];

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();
  TextEditingController numberController = TextEditingController();




  Future<void> _playVideo(PickedFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.network(file.path);
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;
      // In web, most browsers won't honor a programmatic call to .play
      // if the video has a sound track (and is not muted).
      // Mute the video so it auto-plays in web!
      // This is not needed if the call to .play is the result of user
      // interaction (clicking on a "play" button, for example).
      final double volume = kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
    }
  }

  void _onImageButtonPressed(ImageSource source, {BuildContext? context}) async {
    if (_controller != null) {
      await _controller!.setVolume(0.0);
    }
    if (isVideo) {
      final PickedFile? file = (await _picker.getVideo(source: source, maxDuration: const Duration(seconds: 10))) as PickedFile?;
      await _playVideo(file);
      File videofiletoUpload = File(file!.path);

    } else {

      try {
        final pickedFile = await _picker.getImage(
          source: source,
          maxWidth: null,
          maxHeight: null,
          imageQuality: null,
        );

        setState(() {
          _imageFile = pickedFile as PickedFile?;
        });

        if (pickedFile != null) {
          File imagefiletoUpload = File(pickedFile.path);
        }

      } catch (e) {
        setState(() {
          _pickImageError = e;
        });
      }

    }
  }

  @override
  void deactivate() {
    if (_controller != null) {
      _controller!.setVolume(0.0);
      _controller!.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    _disposeVideoController();
    maxWidthController.dispose();
    maxHeightController.dispose();
    qualityController.dispose();
    super.dispose();
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return const Text(
        'Tafadhali, chagua au piga picha.',
        textAlign: TextAlign.center,
      );
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: AspectRatioVideo(_controller),
    );
  }

  Widget _previewImage() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_imageFile != null) {
      if (kIsWeb) {
        // Why network?
        // See https://pub.dev/packages/image_picker#getting-ready-for-the-web-platform
        return Image.network(_imageFile!.path);
      } else {
        return Semantics(
            label: 'image_picker_example_picked_image',
            child: Image.file(File(_imageFile!.path)));
      }
    } else if (_pickImageError != null) {
      return Text(
        'Pick image error: $_pickImageError',
        textAlign: TextAlign.center,
      );
    } else {
      return const Text(
        'Tafadhali, chagua au piga picha.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostData response = (await _picker.getLostData()) as LostData;
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      if (response.type == RetrieveType.video) {
        isVideo = true;
        await _playVideo(response.file);
      } else {
        isVideo = false;
        setState(() {
          _imageFile = response.file;
        });
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.5, // lower the elevation value
        title: Text(widget.title!, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.redAccent),),

        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.redAccent),
          onPressed: () {
            Navigator.of(context).pop(true);
          },
        ),

      ),

      bottomNavigationBar: BottomAppBar(

          child: Material(
            //elevation: 4.0,
            //borderRadius: BorderRadius.all(Radius.circular(6.0)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [



                  Expanded(
                      flex: 1,
                      child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: SizedBox(
                              height: 38.0,
                              width: 38.0,
                              child: IconButton(
                                padding: EdgeInsets.all(0.0),
                                color: Colors.redAccent,
                                icon: Icon(Icons.upload_sharp, size: 38.0),
                                onPressed:  addData,
                              ),

                          )
                      )
                  ),
                ],
              )






          )
        //color: Colors.transparent,










        //elevation: 0,
      ),




      body: Center(
        child: !kIsWeb && defaultTargetPlatform == TargetPlatform.android
            ? FutureBuilder<void>(
          future: retrieveLostData(),
          builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return const Text(
                  'Tafadhali, chagua au piga picha.',
                  textAlign: TextAlign.center,
                );
              case ConnectionState.done:
                return isVideo ? _previewVideo() : _previewImage();
              default:
                if (snapshot.hasError) {
                  return Text(
                    'Pick image/video error: ${snapshot.error}}',
                    textAlign: TextAlign.center,
                  );
                } else {
                  return const Text(
                    'Tafadhali, chagua au piga picha.',
                    textAlign: TextAlign.center,
                  );
                }
            }
          },
        )
            : (isVideo ? _previewVideo() : _previewImage()),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Semantics(
            label: 'image_picker_example_from_gallery',
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
              heroTag: 'image0',
              tooltip: 'Tafadhali, chagua au piga picha.',
              child: const Icon(Icons.photo_library),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.camera, context: context);
              },
              heroTag: 'image1',
              tooltip: 'Tafadhali, chagua au piga picha.',
              child: const Icon(Icons.camera_alt),
            ),
          ),

        ],
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final Text result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }




  Future<void> addData() async {


      DataStore.waitDescription = "Picha inatumwa ...";
      showDialog(context: context,
          builder: (BuildContext context){
            return waitDialog(
              title: "Tafadhali Subiri",
              descriptions: "Picha inatumwa ...",
              text: "",
            );
          }
      );



      var uuid = Uuid();
      var postID = uuid.v4();

      print("imefika hapa");

      late FirebaseDatabase databasext;

      databasext = FirebaseDatabase.instance;
      databasext.setPersistenceEnabled(true);
      databasext.setPersistenceCacheSizeBytes(100000000); // 100MB cache

      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('files')
          .child('users')
          .child("${DataStore.currentUserId}.png");


      if (_imageFile == null) {
        Navigator.of(context, rootNavigator: true).pop('dialog');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tafadhali, chagua picha.'),
        ));
        //return null;
      }
      final metadata = firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': _imageFile!.path});

      String imageUrl;

      if (kIsWeb) {
        //print(ref.putData(await _imageFile!.readAsBytes(), metadata));
        UploadTask uploadTask = ref.putData(await _imageFile!.readAsBytes(), metadata);
        uploadTask.whenComplete(() async{

          try{
            imageUrl = await ref.getDownloadURL();

          print(imageUrl);

          HttpService.updateAvatar(_imageFile!.path,imageUrl.toString()).then((String result){
            setState(() {
              DataStore.currentUserLocalpostImage = _imageFile!.path;
              DataStore.currentUserIdRemotepostImage = imageUrl.toString();
            });

            goToMessages(result);
          });
          }catch(onError){
            print("Error");
          }



        });

      } else {
        //print(ref.putFile(io.File(_imageFile!.path), metadata));

        UploadTask uploadTask = ref.putFile(io.File(_imageFile!.path), metadata);

        uploadTask.whenComplete(() async{

          try{
            imageUrl = await ref.getDownloadURL();

          print(imageUrl);

          HttpService.updateAvatar(_imageFile!.path,imageUrl.toString()).then((String result){
            setState(() {
              DataStore.currentUserLocalpostImage = _imageFile!.path;
              DataStore.currentUserIdRemotepostImage = imageUrl.toString();
            });

            goToMessages(result);
          });
          }catch(onError){
            print("Error");
          }


        });

      }


  }






  void goToMessages(String data){
    Navigator.of(context, rootNavigator: true).pop('dialog');
    print("DATA SAVED");

    print(data);
    DataStore.defaultTab = 1;
    //Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => tabshome()));
    Navigator.of(context).pushReplacement(_routeTotabshome());
  }

  Route _routeTotabshome() {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => tabshome(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = Offset(-1.0, 0.0);
        var end = Offset.zero;
        var curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }



}







typedef OnPickImageCallback = void Function(double? maxWidth, double? maxHeight, int? quality);

class AspectRatioVideo extends StatefulWidget {
  const AspectRatioVideo(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  AspectRatioVideoState createState() => AspectRatioVideoState();
}

class AspectRatioVideoState extends State<AspectRatioVideo> {
  VideoPlayerController? get controller => widget.controller;
  bool initialized = false;

  void _onVideoControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (initialized != controller!.value.isInitialized) {
      initialized = controller!.value.isInitialized;
      setState(() {});
    }
  }









  @override
  void initState() {
    super.initState();
    controller!.addListener(_onVideoControllerUpdate);
  }

  @override
  void dispose() {
    controller!.removeListener(_onVideoControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (initialized) {
      return Center(
        child: AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        ),
      );
    } else {
      return Container();
    }
  }
}