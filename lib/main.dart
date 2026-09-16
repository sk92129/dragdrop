// Kang Engineering Systems LLC, 2026, Copyright protection
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera2image/services/bloc/hydrated_bootstrap.dart';
import 'package:camera2image/services/storage/secure_storage_service.dart';
import 'package:camera2image/modules/local_saved/bloc/local_bloc.dart';
import 'package:camera2image/services/connectivity/connectivity_cubit.dart';
import 'package:camera2image/services/connectivity/connectivity_service.dart';
import 'package:camera2image/services/routing/router.dart';
import 'package:camera2image/services/ui/snackbar_service.dart';
import 'package:camera2image/shared_widgets/offline_status_icon.dart';
import 'package:camera2image/shared_widgets/qa_semantics.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:video_player/video_player.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // initialize secure storage before hydrated bloc
  await SecureStorageService.instance.initialize();
  await ConnectivityService.instance.initialize();
  await initializeHydratedBloc();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
        BlocProvider<LocalBloc>(create: (_) => LocalBloc()),
      ],
      child: MaterialApp.router(
        key: myWidgetKey('app'),
        debugShowCheckedModeBanner: false,
        title: 'Receipt Capture',
        scaffoldMessengerKey: SnackbarService.messengerKey,
        routerConfig: appRouter,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<XFile>? _mediaFileList;
  bool _blackAndWhite = false;

  void _setImageFileListFromFile(XFile? value) {
    _mediaFileList = value == null ? null : <XFile>[value];
  }

  dynamic _pickImageError;
  bool isVideo = false;

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;
  String? _retrieveDataError;

  final ImagePicker _picker = ImagePicker();
  final TextEditingController maxWidthController = TextEditingController();
  final TextEditingController maxHeightController = TextEditingController();
  final TextEditingController qualityController = TextEditingController();
  final TextEditingController limitController = TextEditingController();

  Future<void> _playVideo(XFile? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      final VideoPlayerController controller;
      if (kIsWeb) {
        controller = VideoPlayerController.networkUrl(Uri.parse(file.path));
      } else {
        controller = VideoPlayerController.file(File(file.path));
      }
      _controller = controller;

      const volume = kIsWeb ? 0.0 : 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      setState(() {});
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

  XFile? _firstStillImageXFile() {
    if (isVideo || _mediaFileList == null) {
      return null;
    }
    for (final f in _mediaFileList!) {
      final String? m = f.mimeType ?? lookupMimeType(f.path);
      if (m == null || m.startsWith('image/')) {
        return f;
      }
    }
    return null;
  }

  void _openSaveScreen() {
    if (isVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Switch to image mode to save a still image.'),
        ),
      );
      return;
    }
    final XFile? xfile = _firstStillImageXFile();
    if (xfile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No image to save.')));
      return;
    }
    context.pushNamed(AppRoutes.save.name, extra: xfile.path);
  }

  Future<void> _openAutoCaptureCamera(BuildContext context) async {
    try {
      final XFile? captured = await Navigator.of(context).push<XFile>(
        MaterialPageRoute<XFile>(
          builder: (BuildContext context) =>
              AutoCaptureCameraPage(blackAndWhite: _blackAndWhite),
        ),
      );
      if (captured != null && mounted) {
        setState(() {
          isVideo = false;
          _setImageFileListFromFile(captured);
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Camera error: $e')));
    }
  }

  Widget _previewVideo() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_controller == null) {
      return myWidget(
        id: 'home.video_empty',
        child: const Text(
          'You have not yet picked a video',
          textAlign: TextAlign.center,
        ),
      );
    }
    return myWidget(
      id: 'home.video_preview',
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: AspectRatioVideo(_controller),
      ),
    );
  }

  Widget _previewImages() {
    final Text? retrieveError = _getRetrieveErrorWidget();
    if (retrieveError != null) {
      return retrieveError;
    }
    if (_mediaFileList != null) {
      return myWidget(
        id: 'home.picked_images',
        label: 'Picked images',
        child: ListView.builder(
          key: myWidgetKey('home.picked_images_list'),
          itemBuilder: (BuildContext context, int index) {
            final String? mime = lookupMimeType(_mediaFileList![index].path);
            return myWidget(
              id: 'home.picked_image.$index',
              image: true,
              label: 'Picked image $index',
              child: kIsWeb
                  ? Image.network(_mediaFileList![index].path)
                  : (mime == null || mime.startsWith('image/')
                        ? Image.file(
                            File(_mediaFileList![index].path),
                            errorBuilder:
                                (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return myWidget(
                                    id: 'home.picked_image.$index.unsupported',
                                    child: const Center(
                                      child: Text(
                                        'This image type is not supported',
                                      ),
                                    ),
                                  );
                                },
                          )
                        : _buildInlineVideoPlayer(index)),
            );
          },
          itemCount: _mediaFileList!.length,
        ),
      );
    } else if (_pickImageError != null) {
      return myWidget(
        id: 'home.pick_image_error',
        child: Text(
          'Pick image error: $_pickImageError',
          textAlign: TextAlign.center,
        ),
      );
    } else {
      return myWidget(
        id: 'home.no_image_picked',
        child: const Text(
          'You have not yet picked an image.',
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  Widget _buildInlineVideoPlayer(int index) {
    final controller = VideoPlayerController.file(
      File(_mediaFileList![index].path),
    );
    const volume = kIsWeb ? 0.0 : 1.0;
    controller.setVolume(volume);
    controller.initialize();
    controller.setLooping(true);
    controller.play();
    return myWidget(
      id: 'home.inline_video.$index',
      child: Center(child: AspectRatioVideo(controller)),
    );
  }

  Widget _handlePreview() {
    if (isVideo) {
      return _previewVideo();
    } else {
      return _previewImages();
    }
  }

  Widget _buildBlackAndWhiteToggle() {
    return myWidget(
      id: 'home.black_and_white_toggle',
      button: true,
      label: 'Black and White',
      child: CheckboxListTile(
        key: myWidgetKey('home.black_and_white_checkbox'),
        title: const Text('Black and White'),
        value: _blackAndWhite,
        onChanged: (bool? value) {
          setState(() {
            _blackAndWhite = value ?? false;
          });
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Future<void> retrieveLostData() async {
    final LostDataResponse response = await _picker.retrieveLostData();
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
          if (response.files == null) {
            _setImageFileListFromFile(response.file);
          } else {
            _mediaFileList = response.files;
          }
        });
      }
    } else {
      _retrieveDataError = response.exception!.code;
    }
  }

  @override
  Widget build(BuildContext context) {
    return myWidget(
      id: 'home.screen',
      child: Scaffold(
        appBar: AppBar(
          key: myWidgetKey('home.app_bar'),
          title: myWidget(
            id: 'home.app_bar_title',
            header: true,
            child: Text(widget.title!),
          ),
          actions: withOfflineStatusIcon(),
          leading: myWidget(
            id: 'home.menu_button',
            button: true,
            label: 'Menu',
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu),
              onSelected: (String value) {
                switch (value) {
                  case 'pending':
                    context.pushNamed(AppRoutes.pending.name);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  key: myWidgetKey('home.menu_item.pending'),
                  value: 'pending',
                  child: myWidget(
                    id: 'home.menu_item.pending.label',
                    child: const Text('Pending'),
                  ),
                ),
              ],
            ),
          ),
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child:
                    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                    ? FutureBuilder<void>(
                        future: retrieveLostData(),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<void> snapshot,
                            ) {
                              switch (snapshot.connectionState) {
                                case ConnectionState.none:
                                case ConnectionState.waiting:
                                  return myWidget(
                                    id: 'home.waiting_for_image',
                                    child: const Text(
                                      'You have not yet picked an image.',
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                case ConnectionState.done:
                                  return _handlePreview();
                                case ConnectionState.active:
                                  if (snapshot.hasError) {
                                    return myWidget(
                                      id: 'home.pick_error',
                                      child: Text(
                                        'Pick image/video error: ${snapshot.error}}',
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  } else {
                                    return myWidget(
                                      id: 'home.no_image_picked_active',
                                      child: const Text(
                                        'You have not yet picked an image.',
                                        textAlign: TextAlign.center,
                                      ),
                                    );
                                  }
                              }
                            },
                      )
                    : _handlePreview(),
              ),
            ),
            _buildBlackAndWhiteToggle(),
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            // add a file picker
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: myWidget(
                id: 'home.file_picker_button',
                button: true,
                label: 'Pick a file',
                child: FloatingActionButton(
                  onPressed: () async {
                    // go to file picker screen by route
                    context.pushNamed(AppRoutes.filePicker.name);
                  },
                  heroTag: 'filePicker',
                  tooltip: 'Pick a file',
                  child: const Icon(Icons.file_present),
                ),
              ),
            ),

            if (_picker.supportsImageSource(ImageSource.camera))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: myWidget(
                  id: 'home.capture_button',
                  button: true,
                  label: 'Take a photo',
                  child: FloatingActionButton(
                    key: myWidgetKey('home.capture_fab'),
                    onPressed: () async {
                      isVideo = false;
                      await _openAutoCaptureCamera(context);
                    },
                    heroTag: 'image2',
                    tooltip: 'Take a photo',
                    child: const Icon(Icons.camera_alt),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: myWidget(
                id: 'home.save_button',
                button: true,
                label: 'Save current image as PNG',
                child: FloatingActionButton(
                  key: myWidgetKey('home.save_fab'),
                  onPressed: _openSaveScreen,
                  heroTag: 'savePng',
                  tooltip: 'Save current image as PNG',
                  child: const Icon(Icons.save),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Text? _getRetrieveErrorWidget() {
    if (_retrieveDataError != null) {
      final result = Text(_retrieveDataError!);
      _retrieveDataError = null;
      return result;
    }
    return null;
  }
}

typedef OnPickImageCallback =
    void Function(
      double? maxWidth,
      double? maxHeight,
      int? quality,
      int? limit,
    );

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
      return myWidget(
        id: 'home.video_player',
        child: Center(
          child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: VideoPlayer(controller!),
          ),
        ),
      );
    } else {
      return myWidget(
        id: 'home.video_player_uninitialized',
        child: Container(),
      );
    }
  }
}

class AutoCaptureCameraPage extends StatefulWidget {
  const AutoCaptureCameraPage({super.key, required this.blackAndWhite});

  final bool blackAndWhite;

  @override
  State<AutoCaptureCameraPage> createState() => _AutoCaptureCameraPageState();
}

class _AutoCaptureCameraPageState extends State<AutoCaptureCameraPage> {
  static const int _requiredStableFrames = 8;
  static const double _minSharpness = 20.0;
  static const double _maxMotion = 8.0;

  CameraController? _controller;
  bool _initializing = true;
  bool _capturing = false;
  bool _streamRunning = false;
  String _status = 'Point camera and hold still...';
  int _stableFrames = 0;
  final DateTime _startedAt = DateTime.now();
  Uint8List? _previousLuma;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final List<CameraDescription> cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No camera available');
      }
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final CameraController controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);
      await controller.setExposureMode(ExposureMode.auto);
      await controller.startImageStream(_onFrame);
      _streamRunning = true;

      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _initializing = false;
        _status = 'Camera init failed: $e';
      });
    }
  }

  void _onFrame(CameraImage image) {
    if (!mounted || _capturing) {
      return;
    }
    if (DateTime.now().difference(_startedAt).inMilliseconds < 1200) {
      return;
    }
    if (image.planes.isEmpty) {
      return;
    }

    final Uint8List luma = image.planes.first.bytes;
    final int width = image.width;
    final int height = image.height;
    final int rowStride = image.planes.first.bytesPerRow;
    final double sharpness = _computeSharpness(luma, width, height, rowStride);
    final double motion = _computeMotion(
      _previousLuma,
      luma,
      width,
      height,
      rowStride,
    );
    _previousLuma = Uint8List.fromList(luma);

    final bool stableNow = sharpness >= _minSharpness && motion <= _maxMotion;
    final int nextStableFrames = stableNow ? _stableFrames + 1 : 0;
    if (_stableFrames != nextStableFrames || !_capturing) {
      setState(() {
        _stableFrames = nextStableFrames;
        _status = stableNow
            ? 'Stabilizing... $_stableFrames/$_requiredStableFrames'
            : 'Hold still for auto-capture...';
      });
    }

    if (nextStableFrames >= _requiredStableFrames) {
      unawaited(_captureNow());
    }
  }

  double _computeSharpness(
    Uint8List luma,
    int width,
    int height,
    int rowStride,
  ) {
    final int step = math.max(2, math.min(width, height) ~/ 64);
    double sum = 0;
    int count = 0;
    for (int y = step; y < height; y += step) {
      final int row = y * rowStride;
      final int prevRow = (y - step) * rowStride;
      for (int x = step; x < width; x += step) {
        final int idx = row + x;
        final int gx = (luma[idx] - luma[row + x - step]).abs();
        final int gy = (luma[idx] - luma[prevRow + x]).abs();
        sum += gx + gy;
        count++;
      }
    }
    if (count == 0) {
      return 0;
    }
    return sum / count;
  }

  double _computeMotion(
    Uint8List? previous,
    Uint8List current,
    int width,
    int height,
    int rowStride,
  ) {
    if (previous == null || previous.length != current.length) {
      return 999;
    }
    final int step = math.max(2, math.min(width, height) ~/ 64);
    double sum = 0;
    int count = 0;
    for (int y = 0; y < height; y += step) {
      final int row = y * rowStride;
      for (int x = 0; x < width; x += step) {
        final int idx = row + x;
        sum += (current[idx] - previous[idx]).abs();
        count++;
      }
    }
    if (count == 0) {
      return 999;
    }
    return sum / count;
  }

  Future<void> _captureNow() async {
    final CameraController? controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) {
      return;
    }
    setState(() {
      _capturing = true;
      _status = 'Capturing...';
    });
    try {
      if (_streamRunning) {
        await controller.stopImageStream();
        _streamRunning = false;
      }
      final XFile file = await controller.takePicture();
      final XFile output = await _applyBlackAndWhiteIfNeeded(file);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(output);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _capturing = false;
        _stableFrames = 0;
        _status = 'Capture failed. Hold still and try again.';
      });
      if (!_streamRunning) {
        await controller.startImageStream(_onFrame);
        _streamRunning = true;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  Future<XFile> _applyBlackAndWhiteIfNeeded(XFile file) async {
    if (!widget.blackAndWhite) {
      return file;
    }
    final Uint8List bytes = await file.readAsBytes();
    final img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return file;
    }
    final img.Image bw = img.grayscale(decoded);
    final Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(bw, quality: 95),
    );
    await File(file.path).writeAsBytes(encoded, flush: true);
    return XFile(file.path, mimeType: 'image/jpeg');
  }

  @override
  void dispose() {
    final CameraController? controller = _controller;
    _controller = null;
    if (controller != null) {
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = _controller;
    return myWidget(
      id: 'camera.screen',
      child: Scaffold(
        appBar: AppBar(
          key: myWidgetKey('camera.app_bar'),
          title: myWidget(
            id: 'camera.app_bar_title',
            header: true,
            child: const Text('Auto Capture'),
          ),
          actions: withOfflineStatusIcon(),
        ),
        body: _initializing
            ? myWidget(
                id: 'camera.loading',
                child: const Center(child: CircularProgressIndicator()),
              )
            : controller == null || !controller.value.isInitialized
            ? myWidget(
                id: 'camera.status',
                child: Center(
                  child: Text(_status, textAlign: TextAlign.center),
                ),
              )
            : myWidget(
                id: 'camera.preview',
                image: true,
                label: 'Camera preview',
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraPreview(controller),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 24,
                      child: myWidget(
                        id: 'camera.status_overlay',
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _status,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: controller == null
            ? null
            : myWidget(
                id: 'camera.capture_button',
                button: true,
                label: 'Capture now',
                child: FloatingActionButton(
                  key: myWidgetKey('camera.capture_fab'),
                  onPressed: _capturing ? null : _captureNow,
                  tooltip: 'Capture now',
                  child: const Icon(Icons.camera),
                ),
              ),
      ),
    );
  }
}
