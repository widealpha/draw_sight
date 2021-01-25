import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import 'draw_path.dart';

class PaintBoard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return PaintBoardState();
  }
}

class PaintBoardState extends State {
  File _image;
  double _mStrokeWidth;
  Color _mStrokeColor;
  Paint _paint;
  double _tmpStokeWidth;
  Color _tmpStokeColor;
  GlobalKey<SignatureState> key = GlobalKey<SignatureState>();

  @override
  void initState() {
    super.initState();
    _initPaint();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          title: Text("画图板"),
          centerTitle: false,
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.undo),
              tooltip: "撤销",
              onPressed: () {
                key.currentState.undo();
              },
            ),
            IconButton(
              icon: Icon(Icons.redo),
              tooltip: "反撤销",
              onPressed: () {
                key.currentState.redo();
              },
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              tooltip: "重新绘制",
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: Text("确定清除画板"),
                    actions: <Widget>[
                      MaterialButton(
                        child: Text(
                          "取消",
                          style: TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      MaterialButton(
                        child: Text(
                          "确定",
                          style: TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        onPressed: () {
                          _initPaint();
                          key.currentState.clear();
                          key.currentState.changePaint(_paint);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            PopupMenuButton(
              icon: Icon(Icons.expand_more),
              tooltip: "更多选项",
              onSelected: (value) {
                switch (value) {
                  case "画笔":
                    setState(() {
                      _paint.color = _mStrokeColor;
                      key.currentState.changePaint(_paint);
                      key.currentState.changePaint(_paint);
                    });
                    break;
                  case "橡皮擦":
                    setState(() {
                      _paint.color = Colors.white;
                      key.currentState.changePaint(_paint);
                      key.currentState.changePaint(_paint);
                    });
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                new PopupMenuItem(value: "画笔", child: new Text("画笔")),
                new PopupMenuItem(value: "橡皮擦", child: new Text("橡皮擦"))
              ],
            )
          ],
        ),
        body: Stack(
          overflow: Overflow.clip,
          fit: StackFit.loose,
          children: [
            Positioned(child: Center(
              child: Image.asset('images/apple.png'),
            )),
            Positioned(
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  color: Colors.white,
                  child: Signature(key, _paint),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: RaisedButton(
                onPressed: null,
                disabledColor: ThemeData.light().buttonColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.fromLTRB(0, 8, 0, 12),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: <Widget>[
                      //线条
                      Expanded(
                        child: Center(
                          child: RaisedButton(
                            textColor: Colors.white,
                            color: Colors.blue,
                            child: Text(
                              "线条",
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext buildContext) =>
                                    StatefulBuilder(
                                  builder: (context, mSetState) => AlertDialog(
                                    title: Text("设置线条宽度"),
                                    contentPadding: const EdgeInsets.fromLTRB(
                                        12, 24, 24, 12),
                                    content: SingleChildScrollView(
                                      child: Slider(
                                        min: 1,
                                        max: 50,
                                        value: _tmpStokeWidth,
                                        onChanged: (double width) {
                                          mSetState(() {
                                            _tmpStokeWidth =
                                                width.roundToDouble();
                                          });
                                        },
                                      ),
                                    ),
                                    actions: <Widget>[
                                      MaterialButton(
                                        child: Text(
                                          "取消",
                                          style: TextStyle(
                                              color: Colors.blue, fontSize: 16),
                                        ),
                                        onPressed: () {
                                          _tmpStokeWidth = _mStrokeWidth;
                                          Navigator.of(buildContext).pop();
                                        },
                                      ),
                                      MaterialButton(
                                        child: Text(
                                          "确定",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _mStrokeWidth = _tmpStokeWidth;
                                            _paint.strokeWidth = _mStrokeWidth;
                                            key.currentState
                                                .changePaint(_paint);
                                          });
                                          Navigator.of(buildContext).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      //保存
                      Expanded(
                        child: Center(
                          child: RaisedButton(
                            textColor: Colors.white,
                            color: Colors.blue,
                            child: Text(
                              "保存",
                            ),
                            onPressed: () {
                              key.currentState.save();
                            },
                          ),
                        ),
                      ),
                      //颜色
                      Expanded(
                        child: Center(
                          child: RaisedButton(
                            textColor: Colors.white,
                            color: Colors.blue,
                            child: Text(
                              "颜色",
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext buildContext) =>
                                    StatefulBuilder(
                                  builder: (context, mSetState) => AlertDialog(
                                    title: Text("设置线条颜色"),
                                    content: SingleChildScrollView(
                                      child: ColorPicker(
                                        pickerColor: _tmpStokeColor,
                                        onColorChanged: (Color color) {
                                          mSetState(() {
                                            _tmpStokeColor = color;
                                          });
                                        },
                                      ),
                                    ),
                                    actions: <Widget>[
                                      MaterialButton(
                                        child: Text(
                                          "取消",
                                          style: TextStyle(
                                              color: Colors.blue, fontSize: 16),
                                        ),
                                        onPressed: () {
                                          _tmpStokeColor = _mStrokeColor;
                                          Navigator.of(buildContext).pop();
                                        },
                                      ),
                                      MaterialButton(
                                        child: Text(
                                          "确定",
                                          style: TextStyle(
                                              color: Colors.red, fontSize: 16),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _mStrokeColor = _tmpStokeColor;
                                            _paint.color = _mStrokeColor;
                                            key.currentState
                                                .changePaint(_paint);
                                          },);
                                          Navigator.of(buildContext).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: () async {
                      try {
                        File pickedFile = await ImagePicker.pickImage(
                            source: ImageSource.camera);
                        pickedFile = await ImageCropper.cropImage(
                            sourcePath: pickedFile.path,
                            cropStyle: CropStyle.rectangle);
                        setState(() {
                          _image = pickedFile;
                        });
                        showDialog(
                            context: context,
                            builder: (buildContext) {
                              return Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            barrierDismissible: false);
                      } on Exception {}
                    },
                    tooltip: '拍照',
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                    ),
                  ),
                  Padding(padding: EdgeInsets.all(4)),
                  FloatingActionButton(
                    onPressed: () async {
                      try {} on Exception {}
                    },
                    tooltip: '风格化',
                    child: Icon(
                      Icons.style_outlined,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _initPaint() {
    _mStrokeColor = Colors.black;
    _tmpStokeColor = _mStrokeColor;
    _mStrokeWidth = 5.0;
    _tmpStokeWidth = _mStrokeWidth;
    _paint = Paint()
      ..strokeCap = StrokeCap.round
      ..color = _mStrokeColor
      ..strokeJoin = StrokeJoin.bevel
      ..filterQuality = FilterQuality.high
      ..strokeWidth = _mStrokeWidth;
  }
}
