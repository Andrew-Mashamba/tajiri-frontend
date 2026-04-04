
import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'waitDialog.dart';
import 'package:video_player/video_player.dart';

import 'HttpService.dart';
import 'DataStore.dart';
// import 'loginExt.dart'; // removed — auth handled by TAJIRI bridge


class profileImage extends StatelessWidget {
  const profileImage({super.key});

  @override
  Widget build(BuildContext context) {
    var materialKey;


    return MaterialApp(
      title: '',
      home: MyHomePage(title: 'Chagua picha'),
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
        'Tafadhali, chagua picha yako',
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

        DataStore.profileImage = _imageFile!.path;
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
        'Tafadhali, chagua picha yako.',
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
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(widget.title!),
      ),

      bottomNavigationBar: BottomAppBar(

          child: Material(
            //elevation: 4.0,
            //borderRadius: BorderRadius.all(Radius.circular(6.0)),
              child: Container(
                height: size.height * 0.08,
                width: size.width * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  color: Colors.redAccent,
                ),
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.redAccent[300],
                    backgroundColor: Colors.white,
                    shadowColor: Colors.redAccent[100],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0)),
                    minimumSize: Size(100, 40), //////// HERE
                  ),
                  onPressed: () {
                    print("this is clicked");
                    addData();
                  },
                  child: Text(
                    "Upload Picha",
                    style: TextStyle(fontSize: 18, color: Colors.white, height: 1.0).copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),






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
                  'Tafadhali, chagua picha yako.',
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
                    'Tafadhali, chagua picha yako.',
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
            label: '',
            child: FloatingActionButton(
              backgroundColor: Colors.redAccent,
              onPressed: () {
                isVideo = false;
                _onImageButtonPressed(ImageSource.gallery, context: context);
              },
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



      var postComment = numberController.text.trim();
      print("THE TEXT $postComment");
      //var uuid = Uuid();
      var uuid = Uuid();
      var postID = uuid.v4();

      print("imefika hapa");

      late FirebaseDatabase databasext;

      databasext = FirebaseDatabase.instance;
      databasext.setPersistenceEnabled(true);
      databasext.setPersistenceCacheSizeBytes(100000000); // 100MB cache

      var KikobaId = DataStore.currentKikobaId;
      var userNumberx = DataStore.userNumber;
      var currentUserId = DataStore.currentUserId;

      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('files')
          .child('users')
          .child("$currentUserId.png");


      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No file was selected'),
        ));
        //return null;
      }
      final metadata = firebase_storage.SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'picked-file-path': _imageFile!.path});

      String imageUrl;




      if (kIsWeb) {
        showDialog(context: context,
            builder: (BuildContext context){
              return waitDialog(
                title: "Tafadhali Subiri",
                descriptions: "Picha ina uplodiwa...",
                text: "",
              );
            }
        );
        //print(ref.putData(await _imageFile!.readAsBytes(), metadata));
        UploadTask uploadTask = ref.putData(await _imageFile!.readAsBytes(), metadata);
        uploadTask.whenComplete(() async{

          try{
            imageUrl = await ref.getDownloadURL();

          print(imageUrl);





          try {

            HttpService.updateProfileImage(_imageFile!.path, imageUrl.toString()).then((String result){

              Navigator.of(context, rootNavigator: true).pop('dialog');

              goToMessages(result.toString());
            });
          } on Exception catch (ex) {
            print('Query error: $ex');
          }

          }catch(onError){
            print("Error");
          }


        });

      } else {
        //print(ref.putFile(io.File(_imageFile!.path), metadata));

        showDialog(context: context,
            builder: (BuildContext context){
              return waitDialog(
                title: "Tafadhali Subiri",
                descriptions: "Picha ina uplodiwa...",
                text: "",
              );
            }
        );


        UploadTask uploadTask = ref.putFile(io.File(_imageFile!.path), metadata);

        uploadTask.whenComplete(() async{

          try{
            imageUrl = await ref.getDownloadURL();



          try {

            HttpService.updateProfileImage(_imageFile!.path, imageUrl.toString()).then((String result){
              Navigator.of(context, rootNavigator: true).pop('dialog');

              goToMessages(result.toString());
            });
          } on Exception catch (ex) {
            print('Query error: $ex');
          }

          }catch(onError){
            print("Error");
          }



        });

      }


      //FocusScope.of(baraza.this).unfocus();
      //FocusScope.of(context).requestFocus(FocusNode());
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      numberController.clear();

      //printFirebase();



  }






  void goToMessages(String data){

    print("DATA SAVED");
    // Auth handled by TAJIRI bridge — pop back to main app
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    print('codeSent');

  }




}






extension ImagePickerExtension on ImagePicker {
  Future<XFile?> getVideo({
    required ImageSource source,
    required Duration maxDuration,
  }) {
    return pickVideo(
      source: source,
      maxDuration: maxDuration,
    );
  }

  Future<XFile?> getImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) {
    return pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  Future<LostDataResponse> getLostData() {
    return retrieveLostData();
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


class RoundedButton2 extends StatelessWidget {
  const RoundedButton2({super.key, 
    required this.buttonName,
  });

  final String buttonName;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      height: size.height * 0.08,
      width: size.width * 0.8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(0),
        color: Colors.redAccent,
      ),
      child:ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.redAccent[300],
          backgroundColor: Colors.white,
          shadowColor: Colors.redAccent[100],
          elevation: 3,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0)),
          minimumSize: Size(100, 40), //////// HERE
        ),
        onPressed: () {
          _MyHomePageState().addData();
        },
        child: Text(
          buttonName,
          style: TextStyle(fontSize: 18, color: Colors.white, height: 1.0).copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
