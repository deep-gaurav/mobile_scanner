import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWithController extends StatefulWidget {
  const BarcodeScannerWithController({Key? key}) : super(key: key);

  @override
  _BarcodeScannerWithControllerState createState() =>
      _BarcodeScannerWithControllerState();
}

class _BarcodeScannerWithControllerState
    extends State<BarcodeScannerWithController>
    with SingleTickerProviderStateMixin {
  String? barcode;
  Barcode? barcodeVal;

  MobileScannerController controller = MobileScannerController(
    torchEnabled: true,
    // formats: [BarcodeFormat.qrCode]
    // facing: CameraFacing.front,
  );

  bool isStarted = true;

  ValueNotifier<bool> isZooming = ValueNotifier(false);
  double? startValue;
  ValueNotifier<double> zoomAmount = ValueNotifier(0);

  double? minZoomRatio, maxZoomRatio;

  bool get isZoomRatioAvailable => minZoomRatio != null;
  var zoomRatio = ValueNotifier(1.0);
  var startRatio = 1.0;

  @override
  void initState() {
    WidgetsBinding.instance?.addPostFrameCallback(
      (timeStamp) async {
        await Future.delayed(Duration(milliseconds: 1000));
        if (mounted) {
          minZoomRatio = await controller.getMinZoomRatio();
          maxZoomRatio = await controller.getMaxZoomRatio();
          setState(() {});
        }
      },
    );
    super.initState();
  }

  handleZoom() async {
    if (isZooming.value) {
      return;
    }
    isZooming.value = true;
    controller.setZoom(zoomAmount.value).ignore();
    await Future.delayed(const Duration(milliseconds: 50));
    isZooming.value = false;
  }

  handleZoomRatio() async {
    if (isZooming.value) {
      return;
    }
    isZooming.value = true;
    controller.setZoomRatio(zoomRatio.value).ignore();
    await Future.delayed(const Duration(milliseconds: 50));
    isZooming.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Stack(
            children: [
              Stack(
                fit: StackFit.passthrough,
                children: [
                  MobileScanner(
                    freeze: barcodeVal != null,
                    controller: controller,
                    fit: BoxFit.cover,
                    // allowDuplicates: true,
                    // controller: MobileScannerController(
                    //   torchEnabled: true,
                    //   facing: CameraFacing.front,
                    // ),
                    onDetect: (barcode, args) {
                      setState(() {
                        barcodeVal = barcode;
                        this.barcode = barcode.rawValue;
                      });
                    },
                  ),
                  if (barcodeVal != null)
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: UnconstrainedBox(
                          child: SizedBox(
                            width: barcodeVal!.width!.toDouble(),
                            height: barcodeVal!.height!.toDouble(),
                            child: CustomPaint(
                              painter: PointsPainter(barcodeVal!.corners!),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withOpacity(0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        color: Colors.white,
                        icon: ValueListenableBuilder(
                          valueListenable: controller.torchState,
                          builder: (context, state, child) {
                            if (state == null) {
                              return const Icon(
                                Icons.flash_off,
                                color: Colors.grey,
                              );
                            }
                            switch (state as TorchState) {
                              case TorchState.off:
                                return const Icon(
                                  Icons.flash_off,
                                  color: Colors.grey,
                                );
                              case TorchState.on:
                                return const Icon(
                                  Icons.flash_on,
                                  color: Colors.yellow,
                                );
                            }
                          },
                        ),
                        iconSize: 32.0,
                        onPressed: () => controller.toggleTorch(),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: isStarted
                            ? const Icon(Icons.stop)
                            : const Icon(Icons.play_arrow),
                        iconSize: 32.0,
                        onPressed: () => setState(() {
                          isStarted ? controller.stop() : controller.start();
                          isStarted = !isStarted;
                        }),
                      ),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 200,
                          height: 50,
                          child: FittedBox(
                            child: Text(
                              barcode ?? 'Scan something!',
                              overflow: TextOverflow.fade,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline4!
                                  .copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: ValueListenableBuilder(
                          valueListenable: controller.cameraFacingState,
                          builder: (context, state, child) {
                            if (state == null) {
                              return const Icon(Icons.camera_front);
                            }
                            switch (state as CameraFacing) {
                              case CameraFacing.front:
                                return const Icon(Icons.camera_front);
                              case CameraFacing.back:
                                return const Icon(Icons.camera_rear);
                            }
                          },
                        ),
                        iconSize: 32.0,
                        onPressed: () => controller.switchCamera(),
                      ),
                      IconButton(
                        color: Colors.white,
                        icon: const Icon(Icons.image),
                        iconSize: 32.0,
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          // Pick an image
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) {
                            var codes =
                                await controller.analyzeImage(image.path);
                            if (codes.isNotEmpty) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text(codes.map((e) => e.rawValue).join()),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No barcode found!'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: (details) {
                    setState(() {
                      startRatio = zoomRatio.value;
                    });
                  },
                  onScaleUpdate: (details) {
                    if (isZoomRatioAvailable == false) {
                      zoomAmount.value =
                          ((details.scale - 1) / 1).clamp(0.0, 1.0);
                      setState(() {
                        handleZoom();
                      });
                    } else {
                      zoomRatio.value = (details.scale * startRatio)
                          .clamp(minZoomRatio!, maxZoomRatio!);
                      setState(() {
                        handleZoomRatio();
                      });
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PointsPainter extends CustomPainter {
  List<Offset> corners;

  PointsPainter(this.corners);

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Colors.pink
      ..strokeWidth = 20;
    for (var point in corners) {
      canvas.drawCircle(point, 20, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
