// ignore_for_file: library_private_types_in_public_api, sized_box_for_whitespace, avoid_print, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_qr_reader/flutter_qr_reader.dart';
import 'package:image_picker/image_picker.dart';
import 'package:master_pay/page/qr_reader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:upi_india/upi_india.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showScanView = false;
  QrReaderViewController? _controller;

  String upiId = "";
  var amount = 0.0;

  TextEditingController upiController = TextEditingController();
  TextEditingController amtController = TextEditingController();

  Future<UpiResponse>? _transaction;
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? apps;

  TextStyle header = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  TextStyle value = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 14,
  );

  @override
  void initState() {
    _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      setState(() {
        apps = value;
      });
    }).catchError((e) {
      apps = [];
    });
    super.initState();
  }

  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    return _upiIndia.startTransaction(
      app: app,
      receiverUpiId: upiId,
      receiverName: upiId,
      transactionRefId: 'N/A',
      transactionNote: 'Paying with Master Pay',
      amount: amount,
    );
  }

  Widget displayUpiApps() {
    if (apps == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (apps!.isEmpty) {
      return Center(
        child: Text(
          "No apps found to handle transaction.",
          style: header,
        ),
      );
    } else {
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            children: apps!.map<Widget>((UpiApp app) {
              return GestureDetector(
                onTap: () {
                  if (upiId != "" && amount != 0.0) {
                    _transaction = initiateTransaction(app);
                    setState(() {});
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Enter UPI ID and Amount'),
                      duration: Duration(seconds: 1),
                    ));
                  }
                },
                child: Container(
                  height: 100,
                  width: 100,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.memory(
                        app.icon,
                        height: 60,
                        width: 60,
                      ),
                      Text(app.name),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
  }

  String _upiErrorHandler(error) {
    switch (error) {
      case UpiIndiaAppNotInstalledException:
        return 'Requested app not installed on device';
      case UpiIndiaUserCancelledException:
        return 'You cancelled the transaction';
      case UpiIndiaNullResponseException:
        return 'Requested app didn\'t return any response';
      case UpiIndiaInvalidParametersException:
        return 'Requested app cannot handle the transaction';
      default:
        return 'An Unknown error has occurred';
    }
  }

  void _checkTxnStatus(String status) {
    switch (status) {
      case UpiPaymentStatus.SUCCESS:
        print('Transaction Successful');
        break;
      case UpiPaymentStatus.SUBMITTED:
        print('Transaction Submitted');
        break;
      case UpiPaymentStatus.FAILURE:
        print('Transaction Failed');
        break;
      default:
        print('Received an Unknown transaction status');
    }
  }

  Widget displayTransactionData(title, body) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("$title: ", style: header),
          Flexible(
              child: Text(
            body,
            style: value,
          )),
        ],
      ),
    );
  }

  Future stopScan() async {
    assert(_controller != null);
    await _controller?.stopCamera();
    setState(() {
      _showScanView = false;
    });
  }

  Future flashlight() async {
    assert(_controller != null);
    final state = await _controller?.setFlashlight();
    setState(() {});
  }

  late Uri _url;
  Future imgScan() async {
    var image = await ImagePicker().getImage(source: ImageSource.gallery);
    if (image == null) return;
    final rest = await FlutterQrReader.imgScan(image.path);

    if (rest.contains('upi://')) {
      print("Found UPI in gallery");
      _url = Uri.parse(rest);
      if (!await launchUrl(_url)) {
        throw 'Could not launch $_url';
      }
    }
    setState(() {
      upiController.text = rest;
      upiId = rest;
    });
  }

  void openScanUI(BuildContext context) async {
    if (_showScanView) {
      await stopScan();
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return Scaffold(
        body: QrcodeReaderView(
          onScan: (result) async {
            if (result.contains("upi://")) {
              print("\n Result found ${result} ");
              _url = Uri.parse(result);
              if (!await launchUrl(_url)) {
                throw 'Could not launch $_url';
              }
            }
            Navigator.of(context).pop();
            setState(() {
              upiController.text = result;
              upiId = result;
            });
          },
          headerWidget: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0.0,
          ),
          boxLineColor: Colors.cyanAccent,
          helpWidget: Container(),
          scanBoxRatio: 0.85,
        ),
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UPI Master'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: upiController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                icon: Icon(Icons.payment),
                hintText: '124512483@gpay',
                labelText: 'UPI ID',
              ),
              onChanged: ((value) {
                setState(() {
                  upiId = value;
                });
              }),
            ),
            const SizedBox(
              height: 20,
            ),
            const Center(
              child: Text(
                "OR",
                style: TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () async {
                    // final photo = await ImagePicker()
                    //     .pickImage(source: ImageSource.camera);
                    await Permission.camera.request();
                    openScanUI(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(
                        33,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.camera_alt,
                          size: 25,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Scan",
                          style: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    imgScan();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(
                        33,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.image,
                          size: 25,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Text(
                          "Pick QR",
                          style: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: amtController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                icon: Icon(Icons.money),
                hintText: '100.00',
                labelText: 'Amount',
              ),
              onChanged: (value) {
                setState(() {
                  amount = double.parse(value);
                });
              },
            ),
            Expanded(
              child: displayUpiApps(),
            ),
            Expanded(
              child: FutureBuilder(
                future: _transaction,
                builder: (BuildContext context,
                    AsyncSnapshot<UpiResponse> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          _upiErrorHandler(snapshot.error.runtimeType),
                          style: header,
                        ), // Print's text message on screen
                      );
                    }

                    // If we have data then definitely we will have UpiResponse.
                    // It cannot be null
                    UpiResponse upiResponse = snapshot.data!;

                    // Data in UpiResponse can be null. Check before printing
                    String txnId = upiResponse.transactionId ?? 'N/A';
                    String resCode = upiResponse.responseCode ?? 'N/A';
                    String txnRef = upiResponse.transactionRefId ?? 'N/A';
                    String status = upiResponse.status ?? 'N/A';
                    String approvalRef = upiResponse.approvalRefNo ?? 'N/A';
                    _checkTxnStatus(status);

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          displayTransactionData('Transaction Id', txnId),
                          displayTransactionData('Response Code', resCode),
                          displayTransactionData('Reference Id', txnRef),
                          displayTransactionData(
                              'Status', status.toUpperCase()),
                          displayTransactionData('Approval No', approvalRef),
                        ],
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text(''),
                    );
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
