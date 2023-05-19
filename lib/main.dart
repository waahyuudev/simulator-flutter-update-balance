import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:prepaid_lib_flutter/unik_lib_flutter.dart';
import 'package:intl/intl.dart';
import 'package:unik_lib_flutter_example/screen/TapCard.dart';
// import 'package:unique_identifier/unique_identifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: NfcScan()),
      ),
    );
  }
}

class NfcScan extends StatefulWidget {
  NfcScan({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<NfcScan> {
  String _balance = "0", _cardNumber = "000000000000000", _status = "Unknown";
  String _bgCard = "images/mandiri_bg.png";
  bool _isLoading = false;
  String paidAmount;
  String _identifier = 'Unknown';
  String _bankName;
  bool isSuccessInit;
  List<dynamic> listHistory;

  @override
  void initState() {
    super.initState();
    initLibrary();
  }

  void initLibrary() async {
    print("mid : 1bdaf34aef1656dcb2abe461255d8f57");
    isSuccessInit =
        await UnikLibFlutter.initUnikLib("1bdaf34aef1656dcb2abe461255d8f57", 1);
    print("isSuccessInit $isSuccessInit");
  }

  void getCardInfo() async {
    _setStateDefault();

    /// optional you can use List<String> varName = List<String>.filled(1, "");
    List<String> cardUid = [''];
    List<String> cardNumber = [''];
    List<String> balance = [''];
    List<String> bankName = [''];
    List<String> history = [''];

    bool isSuccess = await UnikLibFlutter.getCardInfo(
        cardUid, cardNumber, balance, bankName,
        startPooling: true,
        callbackTimeout: (bool isTimeout) {
          //Todo : Timeout pool supported
          print("timeout $isTimeout");
          return false;
        },
        errorNfc: (bool nfcIsNotDetected) {
          //Todo : Card not supported
          print("--> errorNfc $nfcIsNotDetected");
          return false;
        },
        callbackState: (String value) => print(value)).catchError((onError) {
      print("catcherror : $onError");
      return false;
    });
    /*print(
        "isSuccess $isSuccess, cardNumber ${cardNumber[0]}, balance ${balance[0]}, bankName ${bankName[0]}");*/

    // bool jsonHistory = await UnikLibFlutter.getHistory(history);
    // print("jsonHistory ${history[0]}");
    // this.setState(() {
    //   listHistory = jsonDecode(history[0]);
    // });
    if (isSuccess) {
      UnikLibFlutter.stopReader(messageSuccess: "Cek saldo berhasil");

      _setStateCard(true, cardNumber[0], balance[0], bankName[0]);
    } else {
      print("Terjadi kesalahan");
      _setStateDefault();
      if (Platform.isAndroid) Navigator.pop(context);
    }
    // bool historyStatus = await UnikLibFlutter.getHistory(history);
    //
    // print("History Transaction ${jsonEncode(historyStatus)}");
  }

  void updateBalance() async {
    _setStateDefault();
    List<String> status = [null];
    List<String> cardNumber = [null];
    List<String> balance = [null];
    List<String> bankName = [null];
    List<String> beforeBalance = [null];
    // if (isSuccessInit) {
    bool isSuccess = await UnikLibFlutter.updateBalance(status, cardNumber,
        balance, bankName, beforeBalance, "085735442829", "developer@mdd.co.id",
        callbackState: (String stateOperation) =>
            (stateOperation == UnikLibFlutter.WAITING_STATUS)
                ? UnikLibFlutter.setIosMessage(
                    "Mohon tunggu, jangan lepaskan kartu")
                : print("state operation DONE"),
        callbackTimeout: (bool isTimeout) => print("timeout $isTimeout"),
        errorNfc: (bool value) => print("error nfc $value"),
        reffNo: "23488");
    print("isSuccess $isSuccess");
    print("status update ${status[0]}");

    // print("cardNumber ${cardNumber[0]}");

    this.setState(() {
      _status = status[0];
    });

    if (isSuccess) {
      UnikLibFlutter.stopReader(messageSuccess: "Update balance berhasil");
      _setStateCard(true, cardNumber[0], balance[0], bankName[0]);
    } else {
      print("Terjadi kesalahan");
      UnikLibFlutter.stopReader(messageError: "Update balance gagal");
      _setStateCard(false, cardNumber[0], balance[0], bankName[0]);
      // Navigator.of(context).pop();
    }
    // }
  }

  void _setStateCard(
      bool isSuccess, String cardNumber, String balance, String bankName) {
    this.setState(() {
      _cardNumber = cardNumber ?? "0000000000000000";
      _balance = balance ?? "0";
      _bgCard =
          (bankName == "BNI") ? "images/bni_bg.png" : "images/mandiri_bg.png";
      _bankName = bankName;
    });
    if (Platform.isAndroid) Navigator.pop(context);
  }

  void _setStateDefault() {
    this.setState(() {
      _cardNumber = "0000000000000000";
      _balance = "0";
      _bgCard = "images/mandiri_bg.png";
      listHistory = null;
      _status = "Unknown";
    });

  }

  Widget listViewBuilder(List<dynamic> list) {
    return Container(
      height: 300,
      child: ListView.builder(
        itemBuilder: (context, index) {
          return Column(
            children: [
              Text("amount : ${list[index]["amount"]}"),
              Text("date : ${list[index]["date"]}"),
              Text("type : ${list[index]["type"]}"),
              SizedBox(
                height: 10,
              )
            ],
          );
        },
        itemCount: list.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void _showBottomSheet(dynamic screen, dynamic height) {
      showModalBottomSheet(
          isScrollControlled: true,
          shape: RoundedRectangleBorder(
            borderRadius: new BorderRadius.only(
              topLeft: const Radius.circular(25.0),
              topRight: const Radius.circular(25.0),
            ),
          ),
          context: context,
          builder: (builder) {
            return new Container(
              height: MediaQuery.of(context).size.height * height,
              color: Colors.transparent,
              //could change this to Color(0xFF737373),
              //so you don't have to change MaterialApp canvasColor
              child: new Container(
                  child: new Center(
                child: screen,
              )),
            );
          });
    }

    return Scaffold(
      body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: 200,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage('images/bg_home.png'),
                  )),
                  child: Align(
                    alignment: Alignment(0, 17),
                    child: Container(
                        padding: EdgeInsets.only(left: 20, right: 20),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              fit: BoxFit.fill, image: AssetImage(_bgCard)),
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 2,
                              offset:
                                  Offset(3, 3), // changes position of shadow
                            ),
                          ],
                        ),
                        width: 322,
                        height: 190,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 70,
                            ),
                            DefaultTextStyle(
                                style: TextStyle(color: Colors.black),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        _cardNumber.replaceAllMapped(
                                            RegExp(r".{4}"),
                                            (match) => "${match.group(0)} "),
                                        style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18) ??
                                            "0000000000000000"),
                                    SizedBox(
                                      height: 17,
                                    ),
                                    Text("Saldo",
                                        style: TextStyle(
                                            color: Colors.white38,
                                            fontSize: 15)),
                                    SizedBox(
                                      height: 3,
                                    ),
                                    Text(
                                        NumberFormat.simpleCurrency(
                                                locale: 'id_ID')
                                            .format(int.parse(_balance) ?? "0"),
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ))
                          ],
                        )),
                  ),
                ),
                SizedBox(
                  height: 100,
                ),
                Container(
                    width: 300,
                    child: ElevatedButton.icon(
                      label: Text('Update'),
                      icon: Icon(Icons.update_rounded),
                      onPressed: () {
                        updateBalance();
                        if (Platform.isAndroid)
                          _showBottomSheet(TapCard(), 0.50);
                      },
                    )),
                SizedBox(
                  height: 30,
                ),
                Align(
                  alignment: Alignment.center,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : Text(_status ?? "Unknown"),
                ),
                SizedBox(
                  height: 10,
                ),
                (listHistory != null)
                    ? listViewBuilder(listHistory)
                    : SizedBox(
                        width: 1,
                      )
              ],
            ),
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // if (isSuccessInit) {
          getCardInfo();
          if (Platform.isAndroid) _showBottomSheet(TapCard(), 0.50);
          // } else {
          //   print("Init Failed");
          // }
        },
        child: const Icon(Icons.cached),
        backgroundColor: Colors.blue,
      ),
    );
  }

// Future<void> initPlatformState() async {
//   String identifier;
//   try {
//     identifier = await UniqueIdentifier.serial;
//   } on PlatformException {
//     identifier = 'Failed to get Unique Identifier';
//   }
//
//   if (!mounted) return;
//
//   setState(() {
//     _identifier = identifier;
//   });
//
//   print("Unique $_identifier");
// }
}
