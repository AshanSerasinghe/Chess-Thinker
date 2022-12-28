import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

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
      ResolutionPreset.medium,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
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
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Image.file(File(imagePath)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => board()),
          );
        },
        child: const Icon(Icons.navigation),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////

class board extends StatefulWidget {
  const board({super.key});

  @override
  State<board> createState() => _boardState();
}

class _boardState extends State<board> {
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

  @override
  Widget build(BuildContext context) {
    var blackDict = {'a8': 'N', 'b8': 'K'};
    var whiteDict = {'a1': 'N', 'b1': 'K'};

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Constructed board'),
      ),
      body: Center(
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 8,
          children: eachSqqare(blackDict: blackDict, whiteDict: whiteDict),
        ),
      ),
    );
  }
}
