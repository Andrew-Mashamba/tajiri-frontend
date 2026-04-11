
import 'dart:async';
import 'dart:io';
import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'tabshome.dart';
import 'package:video_player/video_player.dart';

import 'DataStore.dart';


class imagePickerAvatar extends StatelessWidget {
  const imagePickerAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyHomePage(title: 'Chagua picha au video');
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

  final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.black87, backgroundColor: Colors.grey[300],
    minimumSize: Size(120, 50),
    padding: EdgeInsets.symmetric(horizontal: 16),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(2)),
    ),
  );










  static final List<FloatingActionButtonLocation> centerLocations =
  <FloatingActionButtonLocation>[
    FloatingActionButtonLocation.centerDocked,
    FloatingActionButtonLocation.centerFloat,
  ];



  final bool _showFab = true;
  final bool _showNotch = true;
  final FloatingActionButtonLocation _fabLocation =
      FloatingActionButtonLocation.endDocked;



  @override
  void initState() {
    super.initState();



  }




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
      final PickedFile? file = await _picker.getVideo(source: source, maxDuration: const Duration(seconds: 10));
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
          _imageFile = pickedFile;
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
        'You have not yet picked a video',
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
        'You have not yet picked an image.',
        textAlign: TextAlign.center,
      );
    }
  }

  Future<void> retrieveLostData() async {
    final LostData response = await _picker.getLostData();
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
        backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title!),
      ),


      floatingActionButton: _showFab
          ? FloatingActionButton(
        onPressed: () {
          addData;
        },
        tooltip: 'Create',
        child: const Icon(Icons.add),
      )
          : null,
      floatingActionButtonLocation: _fabLocation,

      bottomNavigationBar: botoomView(

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
                  'You have not yet picked an image.',
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
                    'You have not yet picked an image.',
                    textAlign: TextAlign.center,
                  );
                }
            }
          },
        )
            : (isVideo ? _previewVideo() : _previewImage()),
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





Widget botoomView(){

  final FloatingActionButtonLocation? fabLocation;
  final NotchedShape? shape;

  fabLocation = FloatingActionButtonLocation.endDocked;
  shape = const CircularNotchedRectangle();

  //fabLocation: _fabLocation,
  //shape: _showNotch ? const CircularNotchedRectangle() : null,

  return BottomAppBar(
    shape: _showNotch ? const CircularNotchedRectangle() : null,
    color: Colors.blue,
    child: IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
      child: Row(
        children: <Widget>[
          IconButton(
            tooltip: 'Open navigation menu',
            icon: const Icon(Icons.menu),
            onPressed: () {},
          ),
          if (centerLocations.contains(fabLocation)) const Spacer(),
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.photo_library),
            onPressed: () {
              isVideo = false;
              _onImageButtonPressed(ImageSource.gallery, context: context);
            },
          ),
          IconButton(
            tooltip: 'Favorite',
            icon: const Icon(Icons.camera_alt),
            onPressed: () {
              isVideo = false;
              _onImageButtonPressed(ImageSource.camera, context: context);
            },
          ),
        ],
      ),
    ),
  );
}






Future<void> addData() async {

    if(numberController.text.isNotEmpty){

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
      var currentKikobaNamex = DataStore.currentKikobaName;
      var currentUserId = DataStore.currentUserId;

      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('files')
          .child(KikobaId)
          .child('avatars')
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
        //print(ref.putData(await _imageFile!.readAsBytes(), metadata));
        UploadTask uploadTask = ref.putData(await _imageFile!.readAsBytes(), metadata);
        uploadTask.whenComplete(() async{

          try{
            imageUrl = await ref.getDownloadURL();


          print(imageUrl);


          DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
          String thedate = dateFormat.format(DateTime.now());

          CollectionReference users = FirebaseFirestore.instance.collection('${currentUserId}userData');


          // Call the user's CollectionReference to add a new user
          users.add({
            'Name': DataStore.currentUserName,
            'userId': DataStore.currentUserId ,
            'phoneNumber': userNumberx,
            'userPhotoLocal': _imageFile!.path,
            'userPhotoRemote': imageUrl.toString(),
            'status': "Mtu kwao",
            'localpostImage': _imageFile!.path,
            'remotepostImage': imageUrl.toString(),
            'userAccount': '012240006786',
            'pin': '3333',
            'cheo': 'Mjumbe',
            'totalAda': '1,150,000 /=',
            'monthlyAda': '150,000 /=',
            'ada': 'paid',
            'adaArreas': '50,000 /=',
            'hisa':'paid',
            'totalHisa': '500,000 /=',
            'minimumHisa': '1,000 /=',
            'hisaArreas': '50,000 /=',
            'currentLoan':'2,000,000 /=',
            'loanInterestType':'flat',
            'rejesho':'230,000 /=',
            'riba':'18',
            'loanArreas':'60,000 /=',
            'currentLoanPayment':'100,000 /=',
            'michangoUlioChangia':'3',
            'michangoUlioChangiaAmount':'300,000 /=',
            'michangoUliochangiwa':'3',
            'michangoUliochangiwaAmount':'350,000 /=',
            'fainiAmount':'80,000 /=',
            'registrationDate' : '',
            'lastUpdateDate' : thedate
          }).then((value) =>

          //print("User Added")
          goToMessages(value.toString())

          ).catchError((error) =>

              print("Failed to add user: $error"

              ));

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
          DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
          String thedate = dateFormat.format(DateTime.now());

          CollectionReference users = FirebaseFirestore.instance.collection('${KikobaId}barazaMessages');


          // Call the user's CollectionReference to add a new user
          users.add({
            'posterName': DataStore.currentUserName,
            'posterId': DataStore.currentUserId ,
            'posterNumber': userNumberx,
            'posterPhoto': "",
            'postComment': postComment,
            'localpostImage': _imageFile!.path,
            'remotepostImage': imageUrl.toString(),
            'postImage': '',
            'postType': 'textImage',
            'postId': postID,
            'postTime' : thedate,
            'kikobaId' : KikobaId
          }).then((value) =>

          //print("User Added")
          goToMessages(value.toString())

          ).catchError((error) =>

              print("Failed to add user: $error"

              ));


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

    }else{
      numberController.clear();
    }


  }






  void goToMessages(String data){

    print("DATA SAVED");

    print(data);

    Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext context) => tabshome()));
  }




}

extension on ImagePicker {
  getVideo({required ImageSource source, required Duration maxDuration}) {}

  getImage({required ImageSource source, required maxWidth, required maxHeight, required imageQuality}) {}

  getLostData() {}
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