// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:exif/exif.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  File? imageFile;

  @override
  void initState() {
    requestPermission();
    super.initState();
  }

  Future requestPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      if (await Permission.storage.request().isGranted) {
        // Continue if granted
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Storage permission denied.'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watermark App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickPortraitWatermarkFile,
              child: const Text('Upload Portrait Watermark Image (PNG)'),
            ),
            ElevatedButton(
              onPressed: _pickLandscapeWatermarkFile,
              child: const Text('Upload Landscape Watermark Image (PNG)'),
            ),
            ElevatedButton(
              onPressed: _pickImageFolder,
              child: const Text('Select Image Folder'),
            ),
            ElevatedButton(
              onPressed: _pickOutputFolder,
              child: const Text('Select Output Folder'),
            ),
            ElevatedButton(
              onPressed: _applyWatermarkToImages,
              child: const Text('Apply Watermark'),
            ),
            if (_portraitWatermarkFile != null || _landscapeWatermarkFile != null)
              // Preview logic remains the same...
              // Add any UI for previewing if needed
              Container(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPortraitWatermarkFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.extension == 'png') {
      setState(() {
        _portraitWatermarkFile = File(result.files.single.path!);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Portrait watermark image selected successfully!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a PNG file.'),
      ));
    }
  }

  Future<void> _pickLandscapeWatermarkFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.extension == 'png') {
      setState(() {
        _landscapeWatermarkFile = File(result.files.single.path!);
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Landscape watermark image selected successfully!'),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a PNG file.'),
      ));
    }
  }

  Future<void> _pickImageFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();

    setState(() {
      _imageFolderPath = folderPath;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Image folder selected successfully!'),
    ));

    await setWatermarkPreview();
  }

  Future<void> _pickOutputFolder() async {
    String? folderPath = await FilePicker.platform.getDirectoryPath();

    setState(() {
      _outputFolderPath = folderPath;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Output folder selected successfully!'),
    ));
  }

  Future setWatermarkPreview() async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Processing a preview...'),
    ));

    List<FileSystemEntity> images = Directory(_imageFolderPath!).listSync(recursive: true, followLinks: false);
    List<String> validExtensions = ['jpg', 'jpeg', 'png'];

    for (var file in images) {
      String extension = p.extension(file.path).toLowerCase().replaceAll('.', '');

      if (validExtensions.contains(extension)) {
        try {
          setState(() {
            imageFile = File(file.path);
          });

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Preview generated for the first valid image.'),
          ));

          break;
        } catch (e, s) {
          print("ERROR | $e");
          print("TRACE | $s");
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to generate preview.'),
          ));
        }
      }
    }
  }

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

  Future<Uint8List> _compressImageToTargetSize(img.Image image, int targetSizeInBytes) async {
    int minQuality = 10;
    int maxQuality = 100;
    late Uint8List result;
    int currentQuality = maxQuality;

    while (minQuality <= maxQuality) {
      result = Uint8List.fromList(img.encodeJpg(image, quality: currentQuality));
      int fileSize = result.lengthInBytes;

      if (fileSize <= targetSizeInBytes) {
        break;
      } else {
        maxQuality = currentQuality - 1;
        currentQuality = (minQuality + maxQuality) ~/ 2;
      }
    }

    return result;
  }

  Future<void> saveCompressedImage(Uint8List imageBytes, String fileName) async {
    File outputFile = File(fileName);
    await outputFile.writeAsBytes(imageBytes);
  }

  Future<void> processAndSaveImage(String imagePath, img.Image image, img.Image watermark) async {
    // Apply the watermark to the image
    img.Image watermarkedImage = _applyWatermark(image, watermark);

    // Compress the image to a target size (e.g., 5MB)
    Uint8List compressedImageBytes = await _compressImageToTargetSize(watermarkedImage, 5 * 1024 * 1024);

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
