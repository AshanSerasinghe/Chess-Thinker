import 'dart:async';

// import 'dart:html';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  //import Firebaase
  Firebase.initializeApp();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.first;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    super.key,
    required this.camera,
  });

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium, //medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //https://stackoverflow.com/questions/56735552/how-to-set-flutter-camerapreview-size-fullscreen
    final mediaSize = MediaQuery.of(context).size;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('App Name'),
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 0, 0, 0),
          leading: Image.asset('images/AppLogo/icon1.png'),
        ),
        // You must wait until the controller is initialized before displaying the
        // camera preview. Use a FutureBuilder to display a loading spinner until the
        // controller has finished initializing.
        body: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              // If the Future is complete, display the preview.
              final scale =
                  1 / (_controller.value.aspectRatio * mediaSize.aspectRatio);
              return ClipRect(
                clipper: _MediaSizeClipper(mediaSize),
                child: Transform.scale(
                  scale: scale,
                  alignment: Alignment.topCenter,
                  child: CameraPreview(_controller),
                ),
              ); //CameraPreview(_controller);
            } else {
              // Otherwise, display a loading indicator.
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
        floatingActionButton: FloatingActionButton(
          // Provide an onPressed callback.
          onPressed: () async {
            // Take the Picture in a try / catch block. If anything goes wrong,
            // catch the error.
            try {
              // Ensure that the camera is initialized.
              await _initializeControllerFuture;

              // Attempt to take a picture and get the file `image`
              // where it was saved.
              final image = await _controller.takePicture();

              if (!mounted) return;

              // If the picture was taken, display it on a new screen.
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayPictureScreen(
                    // Pass the automatically generated path to
                    // the DisplayPictureScreen widget.
                    imagePath: image.path,
                  ),
                ),
              );
            } catch (e) {
              // If an error occurs, log the error to the console.
              //print(e);
            }
          },
          child: const Icon(Icons.camera_alt),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class _MediaSizeClipper extends CustomClipper<Rect> {
  final Size mediaSize;
  const _MediaSizeClipper(this.mediaSize);
  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, mediaSize.width, mediaSize.height);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) {
    return true;
  }
}

class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;
  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  State<DisplayPictureScreen> createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  final _firebaseStorage = FirebaseStorage.instance;
  DatabaseReference ref = FirebaseDatabase.instance.ref("users");
  Map blackMap = {};
  Map whiteMap = {};

  @override
  void initState() {
    super.initState();
    // ToDo:
    // FirebaseDatabase realTimeDatabase = FirebaseDatabase.instance;
  }

  @override
  Widget build(BuildContext context) {
    var file = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Display the Picture'),
        backgroundColor: Colors.black,
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
        height: double.infinity,
        width: double.infinity,
        alignment: Alignment.center,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _firebaseStorage.ref().child('images/BoardImg').putFile(file);

          DatabaseEvent event = await ref.once();
          Map dataFromFB = event.snapshot.value as Map;

          blackMap = dataFromFB['B'];
          whiteMap = dataFromFB['W'];

          // if (snapshot.exists) {
          // ignore: use_build_context_synchronously
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => board(
                whiteMap: whiteMap,
                blackMap: blackMap,
                fullMap: dataFromFB,
              ),
            ),
          );
        }
        // }
        ,
        child: const Icon(Icons.file_upload),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class board extends StatefulWidget {
  Map whiteMap = {};
  Map blackMap = {};
  Map fullMap = {};

  board(
      {super.key,
      required this.whiteMap,
      required this.blackMap,
      required this.fullMap});

  @override
  State<board> createState() => _boardState();
}

class _boardState extends State<board> {
  // late DatabaseReference dbRef;

  // @override
  // void initState() {
  //   super.initState();
  //   dbRef = FirebaseDatabase.instance.ref("users/123");
  // }

  List numToAxis({pos}) {
    int row = 0;
    int col = 0;
    List colLetter = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    String theColLetter = '';

    if (pos / 8 <= 1) {
      row = 8;
    } else if (pos / 8 <= 2) {
      row = 7;
    } else if (pos / 8 <= 3) {
      row = 6;
    } else if (pos / 8 <= 4) {
      row = 5;
    } else if (pos / 8 <= 5) {
      row = 4;
    } else if (pos / 8 <= 6) {
      row = 3;
    } else if (pos / 8 <= 7) {
      row = 2;
    } else {
      row = 1;
    }

    col = pos % 8;
    if (col == 0) {
      col = 8;
    }
    theColLetter = colLetter[(col.toInt() - 1)];

    return [row, theColLetter];
  }

  List<Widget> eachSqqare({blackDict, whiteDict}) {
    List<Widget> sqrList = [];

    int i = 1, row = 0, pieceFlag = 0;
    var w = const Color.fromARGB(255, 211, 159, 117);
    var b = const Color.fromARGB(255, 112, 57, 5);
    Color temp;
    List axis = [];
    String stdAxisNotation = '', file = '', col = '';
    var pieceB, pieceW;

    while (i <= 64) {
      // get the col row
      axis = numToAxis(pos: i);
      row = axis[0];
      col = axis[1];
      stdAxisNotation = col.toString() + row.toString();

      pieceB = blackDict[stdAxisNotation]; //stdAxisNotation
      pieceW = whiteDict[stdAxisNotation]; //stdAxisNotation

      if (pieceB != null) {
        file = 'images/B/$pieceB.png';
        pieceFlag = 1;
      } else if (pieceW != null) {
        file = 'images/W/$pieceW.png';
        pieceFlag = 1;
      } else {
        pieceFlag = 0;
      }

      if (i % 2 == 0) {
        sqrList.add(
          Container(
            color: b,
            child: pieceFlag == 1 ? Image.asset(file) : const Text(''),
          ),
        );
      } else {
        sqrList.add(
          Container(
            color: w,
            child: pieceFlag == 1 ? Image.asset(file) : const Text(''),
          ),
        );
      }

      if (i % 8 == 0) {
        temp = b;
        b = w;
        w = temp;
      }

      i++;
    }

    return sqrList;
  }

  double transformNumbers(input) {
    double result = 0;
    int upperBound = 1, lowerBound = 0;
    num originalUper = 10, originalLower = -10;

    result = (double.parse(input) - originalLower) *
            (upperBound - lowerBound) /
            (originalUper - originalLower) +
        lowerBound;

    return result;
  }

  @override
  Widget build(BuildContext context) {
    var blackDict = widget.blackMap; //{'a8': 'N', 'b8': 'K'};
    var whiteDict = widget.whiteMap; //{'a1': 'N', 'b1': 'K'};
    var fullMap = widget.fullMap;
    Map line1 = fullMap['Line_1'];
    Map line2 = fullMap['Line_2'];
    Map line3 = fullMap['Line_3'];

    var widthScreen = MediaQuery.of(context).size.width;
    double scoreB = transformNumbers(line1['eval_score']);
    String scoreBround = (double.parse(line1['eval_score'])).toStringAsFixed(3);
    // String scoreWround = (scoreW*100).toStringAsFixed(2);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Constructed board'),
      ),
      body: Column(
        children: [
          Text(scoreBround),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
            child: LinearProgressIndicator(
              backgroundColor: const Color.fromARGB(255, 211, 159, 117),
              valueColor:
                  const AlwaysStoppedAnimation(Color.fromARGB(255, 112, 57, 5)),
              minHeight: 10,
              value: scoreB,
            ),
          ),
          SizedBox(
            width: widthScreen,
            height: widthScreen,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 8,
              children: eachSqqare(blackDict: blackDict, whiteDict: whiteDict),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          ),
          Expanded(
              child: Table(
            columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(6)},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 101, 114, 113)
                        .withOpacity(0.3)),
                children: [
                  Text(line1['eval_score']),
                  Text(line1['Moves']),
                ],
              ),
              TableRow(
                children: [
                  Text(
                    line2['eval_score'],
                  ),
                  Text(line2['Moves']),
                ],
              ),
              TableRow(
                decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 101, 114, 113)
                        .withOpacity(0.3)),
                children: [
                  Text(line3['eval_score']),
                  Text(line3['Moves']),
                ],
              )
            ],
          ))
        ],
      ),
    );
  }
}
