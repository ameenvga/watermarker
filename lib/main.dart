// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Watermark App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WatermarkHomePage(),
    );
  }
}

class WatermarkHomePage extends StatefulWidget {
  const WatermarkHomePage({super.key});

  @override
  State<WatermarkHomePage> createState() => _WatermarkHomePageState();
}

class _WatermarkHomePageState extends State<WatermarkHomePage> {
  File? _portraitWatermarkFile;
  File? _landscapeWatermarkFile;
  String? _imageFolderPath;
  String? _outputFolderPath;
  final bool _isProcessing = false;

  @override
  void initState() {
    requestPermission();
    super.initState();
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (!await Permission.storage.request().isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildGrid(),
                const SizedBox(height: 20),
                if (!_isProcessing)
                  ElevatedButton(
                    onPressed: _areInputsSet() ? _applyWatermarkToImages : null,
                    child: const Text('Apply Watermark'),
                  )
                else
                  const Center(child: Text('Processing...')),
                const SizedBox(
                  height: 200,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      // crossAxisCount: 2,
      // shrinkWrap: true,
      // crossAxisSpacing: 16,
      // mainAxisSpacing: 16,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropTarget(
          onDragDone: (data) {
            print(data);

            final file = data.files.first;
            _pickPortraitWatermarkFile(File(file.path));
          },
          child: _buildGridItem(
            icon: Icons.portrait,
            title: 'Portrait Watermark',
            file: _portraitWatermarkFile,
            onTap: () {},
          ),
        ),
        DropTarget(
          onDragDone: (data) {
            final file = data.files.first;
            _pickLandscapeWatermarkFile(File(file.path));
          },
          child: _buildGridItem(
            icon: Icons.landscape,
            title: 'Landscape Watermark',
            file: _landscapeWatermarkFile,
            onTap: () {},
          ),
        ),
        DropTarget(
          onDragDone: (detail) {
            _pickImageFolder(detail.files.first.path);
          },
          child: _buildGridItem(
            icon: Icons.folder,
            title: 'Image Folder',
            filePath: _imageFolderPath,
            onTap: () {},
          ),
        ),
        DropTarget(
          onDragDone: (details) {
            _pickOutputFolder(details.files.first.path);
          },
          child: _buildGridItem(
            icon: Icons.folder,
            title: 'Output Folder',
            filePath: _outputFolderPath,
            onTap: () {
              // _pickOutputFolder
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required String title,
    File? file,
    String? filePath,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(title),
          Container(
            width: 200,
            height: 200,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Stack(
              // mainAxisAlignment: MainAxisAlignment.center,
              alignment: Alignment.center,
              children: [
                Icon(
                  file != null || filePath != null ? Icons.check_circle : icon,
                  size: 50,
                  color: file != null || filePath != null ? Colors.green : Colors.grey,
                ),
                if (file != null)
                  Image.file(
                    file,
                    fit: BoxFit.contain,
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (filePath != null) SizedBox(width: 200, child: Text(filePath)),
          if (file != null) SizedBox(width: 200, child: Text(file.path)),
        ],
      ),
    );
  }

  Future<void> _pickPortraitWatermarkFile(File? result) async {
    // FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      print(result.path);
      setState(() {
        _portraitWatermarkFile = result;
        // _portraitWatermarkFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickLandscapeWatermarkFile(File? result) async {
    // FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _landscapeWatermarkFile = result;
      });
    }
  }

  Future<void> _pickImageFolder(String? folder) async {
    setState(() {
      _imageFolderPath = folder;
    });
    // String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // if (selectedDirectory != null) {
    //   setState(() {
    //     _imageFolderPath = selectedDirectory;
    //   });
    // }
  }

  Future<void> _pickOutputFolder(String folder) async {
    setState(() {
      _outputFolderPath = folder;
    });
    // String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    // if (selectedDirectory != null) {
    // setState(() {
    //   _outputFolderPath = selectedDirectory;
    // });
    // }
  }

  bool _areInputsSet() {
    return _portraitWatermarkFile != null && _landscapeWatermarkFile != null && _imageFolderPath != null && _outputFolderPath != null;
  }

  // Future<void> _pickPortraitWatermarkFile() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

  //   if (result != null && result.files.single.extension == 'png') {
  //     setState(() {
  //       _portraitWatermarkFile = File(result.files.single.path!);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //       content: Text('Portrait watermark image selected successfully!'),
  //     ));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //       content: Text('Please select a PNG file.'),
  //     ));
  //   }
  // }

  // Future<void> _pickLandscapeWatermarkFile() async {
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

  //   if (result != null && result.files.single.extension == 'png') {
  //     setState(() {
  //       _landscapeWatermarkFile = File(result.files.single.path!);
  //     });
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //       content: Text('Landscape watermark image selected successfully!'),
  //     ));
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //       content: Text('Please select a PNG file.'),
  //     ));
  //   }
  // }

  // Future<void> _pickImageFolder() async {
  //   String? folderPath = await FilePicker.platform.getDirectoryPath();

  //   setState(() {
  //     _imageFolderPath = folderPath;
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text('Image folder selected successfully!'),
  //   ));

  //   await setWatermarkPreview();
  // }

  // Future<void> _pickOutputFolder() async {
  //   String? folderPath = await FilePicker.platform.getDirectoryPath();

  //   setState(() {
  //     _outputFolderPath = folderPath;
  //   });
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text('Output folder selected successfully!'),
  //   ));
  // }

  // Future setWatermarkPreview() async {
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text('Processing a preview...'),
  //   ));

  //   List<FileSystemEntity> images = Directory(_imageFolderPath!).listSync(recursive: true, followLinks: false);
  //   List<String> validExtensions = ['jpg', 'jpeg', 'png'];

  //   for (var file in images) {
  //     String extension = p.extension(file.path).toLowerCase().replaceAll('.', '');

  //     if (validExtensions.contains(extension)) {
  //       try {
  //         setState(() {
  //           imageFile = File(file.path);
  //         });

  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text('Preview generated for the first valid image.'),
  //         ));

  //         break;
  //       } catch (e, s) {
  //         print("ERROR | $e");
  //         print("TRACE | $s");
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //           content: Text('Failed to generate preview.'),
  //         ));
  //       }
  //     }
  //   }
  // }

  Future<void> _applyWatermarkToImages() async {
    if (_portraitWatermarkFile == null || _landscapeWatermarkFile == null || _imageFolderPath == null || _outputFolderPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both watermarks, an image folder, and an output folder first.'),
      ));
      return;
    }

    img.Image portraitWatermark = img.decodeImage(_portraitWatermarkFile!.readAsBytesSync())!;
    img.Image landscapeWatermark = img.decodeImage(_landscapeWatermarkFile!.readAsBytesSync())!;

    List<FileSystemEntity> images = Directory(_imageFolderPath!).listSync(recursive: true, followLinks: false);
    int count = 1;

    for (var imageFile in images) {
      try {
        File correctedImageFile = await fixExifRotation(imageFile.path);
        img.Image image = img.decodeImage(correctedImageFile.readAsBytesSync())!;
        // img.Image image = img.decodeImage(File(imageFile.path).readAsBytesSync())!;
        img.Image watermark = _getWatermarkForImage(image, portraitWatermark, landscapeWatermark);

        await processAndSaveImage(imageFile.path, image, watermark);
        print("Processed $count images");
        count++;
      } catch (e) {
        print("ERROR | $e");
        print(imageFile.toString());
      }
    }

    print("Finished processing!");
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Watermark applied to all images!'),
    ));
  }

  img.Image _getWatermarkForImage(img.Image image, img.Image portraitWatermark, img.Image landscapeWatermark) {
    return image.width >= image.height ? landscapeWatermark : portraitWatermark;
  }

  img.Image _applyWatermark(img.Image image, img.Image watermark) {
    int watermarkWidth = watermark.width;
    int watermarkHeight = watermark.height;

    double aspectRatio = image.height / image.width;
    int resizedImageWidth = watermarkWidth;
    int resizedImageHeight = (resizedImageWidth * aspectRatio).round();

    img.Image resizedImage = img.copyResize(image, width: resizedImageWidth, height: resizedImageHeight);

    img.Image finalImage = img.Image(watermarkWidth, watermarkHeight);
    finalImage.fill(0xFFFFFFFF);

    finalImage = img.drawImage(finalImage, resizedImage, dstX: 0, dstY: 0);
    finalImage = img.drawImage(finalImage, watermark, dstX: 0, dstY: 0);

    return finalImage;
  }

  Future<Uint8List> _compressImageToTargetSize(img.Image image) async {
    try {
      // Convert the img.Image object to Uint8List (JPEG format)
      Uint8List imageBytes = img.encodeJpg(image, quality: 90) as Uint8List;

      // Optionally compress further with flutter_image_compress if needed
      var result = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 2300,
        minHeight: 1500,
        quality: 80,
      );
      return result;
    } catch (e) {
      print(e);
      throw Exception('Failed to compress image');
    }
  }

  // Future<Uint8List> _compressImageToTargetSize(img.Image image, int targetSizeInBytes) async {
  //   int minQuality = 10;
  //   int maxQuality = 100;
  //   late Uint8List result;
  //   int currentQuality = maxQuality;

  //   while (minQuality <= maxQuality) {
  //     result = Uint8List.fromList(img.encodeJpg(image, quality: currentQuality));
  //     int fileSize = result.lengthInBytes;

  //     if (fileSize <= targetSizeInBytes) {
  //       break;
  //     } else {
  //       maxQuality = currentQuality - 1;
  //       currentQuality = (minQuality + maxQuality) ~/ 2;
  //     }
  //   }

  //   return result;
  // }

  Future<void> saveCompressedImage(Uint8List imageBytes, String fileName) async {
    File outputFile = File(fileName);
    await outputFile.writeAsBytes(imageBytes);
  }

  Future<void> processAndSaveImage(String imagePath, img.Image image, img.Image watermark) async {
    // Apply the watermark to the image
    img.Image watermarkedImage = _applyWatermark(image, watermark);

    // Compress the image to a target size (e.g., 5MB)
    Uint8List compressedImageBytes = await _compressImageToTargetSize(watermarkedImage);

    // Save the processed image to the output folder with the same name as the original image
    String imageFileName = p.basename(imagePath);
    String outputFilePath = p.join(_outputFolderPath!, imageFileName);

    await saveCompressedImage(compressedImageBytes, outputFilePath);
  }

  Future<File> fixExifRotation(String imagePath) async {
    final originalFile = File(imagePath);
    List<int> imageBytes = await originalFile.readAsBytes();

    // Decode the image
    final originalImage = img.decodeImage(imageBytes);

    // Read EXIF data to check orientation
    final Map<String, IfdTag> exifData = await readExifFromBytes(imageBytes);

    // Default to no rotation needed
    img.Image fixedImage = originalImage!;

    // Check the orientation property in the EXIF data
    if (exifData.containsKey('Image Orientation')) {
      String orientation = exifData['Image Orientation']?.printable ?? '';

      if (orientation.contains('Rotated 90 CW')) {
        fixedImage = img.copyRotate(originalImage, 90);
      } else if (orientation.contains('Rotated 180')) {
        fixedImage = img.copyRotate(originalImage, 180);
      } else if (orientation.contains('Rotated 90 CCW')) {
        fixedImage = img.copyRotate(originalImage, -90);
      }
    }

    // Save the corrected image as a new file or overwrite the existing file
    final fixedFile = await originalFile.writeAsBytes(img.encodeJpg(fixedImage));

    return fixedFile;
  }
}
